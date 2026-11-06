package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.billing.InvoiceResponse;
import com.gara.quanlygara.exception.*;
import com.gara.quanlygara.validation.ServiceTypes;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;

@Service
@Transactional(readOnly=true)
public class CustomerFinanceService {
    private final JdbcTemplate db;
    private final BillingService billing;
    public CustomerFinanceService(JdbcTemplate db,BillingService billing){this.db=db;this.billing=billing;}
    public record Receipt(LocalDateTime paidAt,BigDecimal amount,String method,String payer) {}
    public record CustomerInvoice(int id,int repairOrderId,int vehicleId,String licensePlate,LocalDateTime createdAt,
            BigDecimal total,BigDecimal insuranceSupport,BigDecimal customerDue,BigDecimal customerPaid,
            BigDecimal remaining,String status,boolean awaitingInsurance,List<InvoiceResponse.Line> lines,List<Receipt> payments) {}
    private void vehicle(int customer,Integer vehicle) {
        if(vehicle!=null && db.queryForObject("SELECT COUNT(*) FROM Xe WHERE MaXe=? AND MaKhachHang=?",Integer.class,vehicle,customer)==0)
            throw new ResourceNotFoundException("Không tìm thấy xe.");
    }
    public List<CustomerInvoice> invoices(int customer,Integer vehicle) {
        vehicle(customer,vehicle);
        var ids=db.queryForList("""
            SELECT h.MaHoaDon FROM HoaDon h JOIN PhieuSuaChua r ON r.MaPhieuSuaChua=h.MaPhieuSuaChua
            JOIN PhieuTiepNhan t ON t.MaTiepNhan=r.MaTiepNhan JOIN Xe x ON x.MaXe=t.MaXe
            WHERE x.MaKhachHang=? AND (?=0 OR x.MaXe=?) AND r.TrangThai NOT IN ('HUY','DA_HUY')
            ORDER BY h.NgayLap DESC,h.MaHoaDon DESC
            """,Integer.class,customer,vehicle==null?0:vehicle,vehicle==null?0:vehicle);
        return ids.stream().map(id->invoice(customer,id)).toList();
    }
    public CustomerInvoice invoice(int customer,int id) {
        var vehicles=db.queryForList("""
            SELECT x.MaXe FROM HoaDon h JOIN PhieuSuaChua r ON r.MaPhieuSuaChua=h.MaPhieuSuaChua
            JOIN PhieuTiepNhan t ON t.MaTiepNhan=r.MaTiepNhan JOIN Xe x ON x.MaXe=t.MaXe
            WHERE h.MaHoaDon=? AND x.MaKhachHang=? AND r.TrangThai NOT IN ('HUY','DA_HUY')
            """,Integer.class,id,customer);
        if(vehicles.isEmpty())throw new ResourceNotFoundException("Không tìm thấy hóa đơn.");
        var detail=billing.getById(id);var h=detail.invoice();var b=detail.insuranceBalance();
        boolean pending=detail.insuranceClaimId()!=null&&b==null;
        BigDecimal due=pending?null:b==null?h.total():b.customerDue();
        BigDecimal paid=b==null?h.paid():b.customerPaid();
        BigDecimal support=b==null?BigDecimal.ZERO:b.insurerDue();
        if(b!=null) {
            var refunds=db.queryForList("""
                SELECT p.ChapThuan,COALESCE(CASE WHEN p.Loai='SERVICE' THEN
                    (SELECT SUM(v.SoLuong*v.DonGia) FROM ChiTietDichVu v WHERE v.MaPhieuSuaChua=? AND v.MaDichVu=p.MaHang)
                    ELSE (SELECT SUM(v.SoLuong*v.DonGia) FROM ChiTietPhuTung v WHERE v.MaPhieuSuaChua=? AND v.MaPhuTung=p.MaHang) END,0) AS actual
                FROM CongNoBaoHiem c JOIN DeNghiBoiThuong d ON d.Id=c.DeNghiId JOIN PhanBoDongBaoHiem p ON p.DeNghiId=d.Id
                WHERE c.MaHoaDon=? AND d.NhanTienTaiGara=0 AND d.MaChungTu IS NOT NULL
                """,h.repairOrderId(),h.repairOrderId(),id);
            for(var refund:refunds) support=support.add(((BigDecimal)refund.get("ChapThuan")).min((BigDecimal)refund.get("actual")));
        }
        var payments=db.query("""
            SELECT t.NgayThanhToan,t.SoTien,t.PhuongThuc,CASE WHEN b.MaThanhToan IS NULL THEN 'CUSTOMER' ELSE 'INSURER' END
            FROM ThanhToan t LEFT JOIN ThuBaoHiem b ON b.MaThanhToan=t.MaThanhToan WHERE t.MaHoaDon=? ORDER BY t.NgayThanhToan DESC
            """,(r,n)->new Receipt(r.getTimestamp(1).toLocalDateTime(),r.getBigDecimal(2),r.getString(3),r.getString(4)),id);
        return new CustomerInvoice(id,h.repairOrderId(),vehicles.getFirst(),h.licensePlate(),h.createdAt(),h.total(),
                support,due,paid,due==null?null:due.subtract(paid),
                pending?"CHO_DOI_CHIEU":due.compareTo(paid)<=0?"DA_THANH_TOAN":paid.signum()>0?"THANH_TOAN_MOT_PHAN":"CHUA_THANH_TOAN",
                pending,detail.lines(),payments);
    }
    public record Vehicle(int id,String licensePlate,String brand,String model) {}
    public record VehicleStats(Vehicle vehicle,int completedVisits,int repairVisits,int maintenanceVisits,
            BigDecimal totalCost,BigDecimal customerCost,int awaitingInvoicesOrInsurance,LocalDateTime lastRepair) {}
    public record Month(int year,int month,int completedVisits,BigDecimal totalCost,BigDecimal customerCost) {}
    public record Statistics(int vehicleCount,int completedVisits,int repairVisits,int maintenanceVisits,
            BigDecimal totalCost,BigDecimal customerCost,int awaitingInvoicesOrInsurance,List<VehicleStats> vehicles,List<Month> months) {}
    private static class Totals {
        int visits,repairs,maintenance,pending; BigDecimal total=BigDecimal.ZERO,customer=BigDecimal.ZERO; LocalDateTime last;
        void add(boolean repair,boolean maintenance,BigDecimal total,BigDecimal customer,LocalDateTime date) {
            visits++;if(repair)repairs++;if(maintenance)this.maintenance++;
            this.total=this.total.add(total);if(customer==null)pending++;else this.customer=this.customer.add(customer);
            if(last==null||date.isAfter(last))last=date;
        }
    }
    public Statistics statistics(int customer,Integer selected,Integer year) {
        vehicle(customer,selected);
        if(year!=null&&(year<1900||year>9999))throw new BadRequestException("Năm không hợp lệ.");
        var vehicles=db.query("SELECT MaXe,BienSo,HangXe,DongXe FROM Xe WHERE MaKhachHang=? ORDER BY MaXe",
                (r,n)->new Vehicle(r.getInt(1),r.getString(2),r.getString(3),r.getString(4)),customer);
        var totals=new HashMap<Integer,Totals>();var monthly=new TreeMap<YearMonth,Totals>();var all=new Totals();
        vehicles.forEach(v->totals.put(v.id(),new Totals()));
        var invoices=new HashMap<Integer,CustomerInvoice>();invoices(customer,selected).forEach(i->invoices.put(i.repairOrderId(),i));
        var orders=db.queryForList("""
            SELECT r.MaPhieuSuaChua AS id,x.MaXe AS vehicle,COALESCE(r.NgayHoanThanh,r.NgayLap) AS completed,
                COALESCE((SELECT SUM(d.SoLuong*d.DonGia) FROM ChiTietDichVu d WHERE d.MaPhieuSuaChua=r.MaPhieuSuaChua),0)
                +COALESCE((SELECT SUM(d.SoLuong*d.DonGia) FROM ChiTietPhuTung d WHERE d.MaPhieuSuaChua=r.MaPhieuSuaChua),0) AS cost
            FROM PhieuSuaChua r JOIN PhieuTiepNhan t ON t.MaTiepNhan=r.MaTiepNhan JOIN Xe x ON x.MaXe=t.MaXe
            WHERE x.MaKhachHang=? AND r.TrangThai='HOAN_TAT' AND (?=0 OR x.MaXe=?)
            """,customer,selected==null?0:selected,selected==null?0:selected);
        for(var row:orders) {
            int id=((Number)row.get("id")).intValue(),car=((Number)row.get("vehicle")).intValue();
            var date=((java.sql.Timestamp)row.get("completed")).toLocalDateTime();
            if(year!=null&&date.getYear()!=year)continue;
            var types=db.queryForList("SELECT v.LoaiDichVu FROM ChiTietDichVu d JOIN DichVu v ON v.MaDichVu=d.MaDichVu WHERE d.MaPhieuSuaChua=?",String.class,id);
            boolean maintenance=types.stream().anyMatch(ServiceTypes::isMaintenance);
            boolean repair=types.stream().anyMatch(t->!ServiceTypes.isMaintenance(t))||types.isEmpty();
            var invoice=invoices.get(id);
            BigDecimal cost=invoice==null?(BigDecimal)row.get("cost"):invoice.total();
            BigDecimal due=invoice==null||invoice.awaitingInsurance()?null:invoice.total().subtract(invoice.insuranceSupport());
            all.add(repair,maintenance,cost,due,date);totals.get(car).add(repair,maintenance,cost,due,date);
            monthly.computeIfAbsent(YearMonth.from(date),ignored->new Totals()).add(repair,maintenance,cost,due,date);
        }
        var rows=vehicles.stream().filter(v->selected==null||v.id()==selected).map(v->{var t=totals.get(v.id());return new VehicleStats(v,t.visits,t.repairs,t.maintenance,t.total,t.customer,t.pending,t.last);}).toList();
        var months=monthly.entrySet().stream().map(e->new Month(e.getKey().getYear(),e.getKey().getMonthValue(),e.getValue().visits,e.getValue().total,e.getValue().customer)).toList();
        return new Statistics(vehicles.size(),all.visits,all.repairs,all.maintenance,all.total,all.customer,all.pending,rows,months);
    }
}
