package com.gara.quanlygara.repository;

import com.gara.quanlygara.validation.PriceRules;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gara.quanlygara.dto.quotation.QuotationDtos.*;
import com.gara.quanlygara.exception.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;
import org.springframework.stereotype.Repository;
import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.*;

@Repository
public class QuotationRepository {
    private final JdbcTemplate jdbc;
    private final ObjectMapper json;
    public QuotationRepository(JdbcTemplate jdbc, ObjectMapper json) { this.jdbc=jdbc; this.json=json; }
    private static final String SELECT = """
        SELECT b.*,x.MaXe,x.BienSo,x.HangXe,x.DongXe,x.NamSanXuat,x.SoKm,k.MaKhachHang,k.HoTen
        FROM BaoGia b JOIN PhieuSuaChua p ON p.MaPhieuSuaChua=b.MaPhieuSuaChua
        JOIN PhieuTiepNhan t ON t.MaTiepNhan=p.MaTiepNhan JOIN Xe x ON x.MaXe=t.MaXe
        JOIN KhachHang k ON k.MaKhachHang=x.MaKhachHang
        """;
    private LocalDateTime time(ResultSet r,String column) throws SQLException {
        var value=r.getTimestamp(column); return value==null?null:value.toLocalDateTime();
    }
    private View map(ResultSet r,int ignored) throws SQLException {
        int id=r.getInt("MaBaoGia");
        return new View(id,r.getInt("MaPhieuSuaChua"),r.getInt("MaKhachHang"),r.getString("HoTen"),
            r.getInt("MaXe"),r.getString("BienSo"),r.getString("HangXe"),r.getString("DongXe"),
            r.getObject("NamSanXuat",Integer.class),r.getObject("SoKm",Integer.class),
            r.getInt("PhienBan"),r.getInt("LanDieuChinh"),r.getString("TrangThai"),time(r,"NgayLap"),
            time(r,"NgayGui"),time(r,"NgayXacNhan"),r.getObject("MaNguoiLap",Integer.class),
            r.getObject("MaNguoiDuyet",Integer.class),r.getString("LyDoTuChoi"),r.getBigDecimal("TongTien"),lines(id));
    }
    public List<View> list(Integer owner) {
        return owner==null?jdbc.query(SELECT+" ORDER BY b.MaBaoGia DESC",this::map):
            jdbc.query(SELECT+" WHERE k.MaKhachHang=? AND b.TrangThai<>N'NHAP' ORDER BY b.MaBaoGia DESC",this::map,owner);
    }
    public View get(int id) {
        return jdbc.query(SELECT+" WHERE b.MaBaoGia=?",this::map,id).stream().findFirst()
            .orElseThrow(()->new ResourceNotFoundException("Không tìm thấy báo giá."));
    }
    public List<Line> lines(int id) {
        return jdbc.query("SELECT * FROM ChiTietBaoGia WHERE MaBaoGia=? ORDER BY MaChiTietBaoGia",(r,n)->
            new Line(r.getInt("MaChiTietBaoGia"),r.getObject("MaDichVu")==null?Kind.PART:Kind.SERVICE,
                r.getObject("MaDichVu")==null?r.getInt("MaPhuTung"):r.getInt("MaDichVu"),r.getString("NoiDung"),
                r.getInt("SoLuong"),r.getBigDecimal("DonGia"),r.getBigDecimal("ThanhTien")),id);
    }
    public boolean existsForOrder(int orderId) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM BaoGia WHERE MaPhieuSuaChua=?",Integer.class,orderId)>0;
    }
    public void requireOpenOrder(int orderId) {
        String status=jdbc.queryForObject("SELECT TrangThai FROM PhieuSuaChua WHERE MaPhieuSuaChua=?",String.class,orderId);
        if (Set.of("HOAN_TAT","HUY","DA_HUY").contains(status) ||
            jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaPhieuSuaChua=?",Integer.class,orderId)>0)
            throw new ConflictException("Phiếu đã kết thúc hoặc có hóa đơn, không thể thay đổi báo giá.");
    }
    public Line priced(LineInput input) {
        String query=input.kind()==Kind.SERVICE?
            "SELECT TenDichVu AS Ten,DonGia FROM DichVu WHERE MaDichVu=? AND TrangThai=1":
            "SELECT TenPhuTung AS Ten,DonGia FROM PhuTung WHERE MaPhuTung=?";
        return jdbc.query(query,(r,n)->{
            BigDecimal price=PriceRules.requireWholeThousand(input.unitPrice()==null?r.getBigDecimal("DonGia"):input.unitPrice());
            return new Line(0,input.kind(),input.itemId(),r.getString("Ten"),input.quantity(),price,
                price.multiply(BigDecimal.valueOf(input.quantity())).setScale(2));
        },input.itemId()).stream().findFirst().orElseThrow(()->new BadRequestException("Hạng mục không tồn tại hoặc đã ngừng cung cấp."));
    }
    public int create(int orderId,int actorId,LocalDateTime at) {
        return new SimpleJdbcInsert(jdbc).withTableName("BaoGia").usingGeneratedKeyColumns("MaBaoGia")
            .usingColumns("MaPhieuSuaChua","NgayLap","TongTien","TrangThai","MaNguoiLap")
            .executeAndReturnKey(Map.of("MaPhieuSuaChua",orderId,"NgayLap",Timestamp.valueOf(at),
                "TongTien",BigDecimal.ZERO,"TrangThai","NHAP","MaNguoiLap",actorId)).intValue();
    }
    public void replaceLines(int id,List<Line> lines) {
        jdbc.update("DELETE FROM ChiTietBaoGia WHERE MaBaoGia=?",id);
        for (Line line:lines) jdbc.update("""
            INSERT INTO ChiTietBaoGia(MaBaoGia,MaDichVu,MaPhuTung,NoiDung,SoLuong,DonGia) VALUES(?,?,?,?,?,?)
            """,id,line.kind()==Kind.SERVICE?line.itemId():null,line.kind()==Kind.PART?line.itemId():null,
            line.name(),line.quantity(),line.unitPrice());
        // Total is always recomputed by SQL's existing detail trigger, never accepted from the client.
    }
    public void advance(View item,String status,boolean revision,Integer decidedBy,String reason,LocalDateTime at) {
        int changed=jdbc.update("""
            UPDATE BaoGia SET PhienBan=PhienBan+1,LanDieuChinh=LanDieuChinh+?,TrangThai=?,
                NgayGui=?,NgayXacNhan=?,MaNguoiDuyet=?,LyDoTuChoi=? WHERE MaBaoGia=? AND PhienBan=?
            """,revision?1:0,status,"CHO_XAC_NHAN".equals(status)?Timestamp.valueOf(at):
                (revision?null:item.sentAt()==null?null:Timestamp.valueOf(item.sentAt())),
            decidedBy==null?null:Timestamp.valueOf(at),decidedBy,reason,item.id(),item.version());
        if(changed!=1) throw new ConflictException("Báo giá vừa thay đổi. Vui lòng tải lại.");
    }
    public void audit(View item,Integer actor,String action,String reason) {
        try {
            jdbc.update("INSERT INTO LichSuBaoGia(MaBaoGia,PhienBan,LanDieuChinh,MaTaiKhoan,HanhDong,LyDo,NoiDung) VALUES(?,?,?,?,?,?,?)",
                item.id(),item.version(),item.revision(),actor,action,reason,json.writeValueAsString(item));
        } catch(JsonProcessingException ex) { throw new IllegalStateException("Không lưu được lịch sử báo giá.",ex); }
    }
    public void preserveLegacy(View item) {
        if(jdbc.queryForObject("SELECT COUNT(*) FROM LichSuBaoGia WHERE MaBaoGia=? AND PhienBan=?",Integer.class,item.id(),item.version())==0)
            audit(item,null,"DU_LIEU_TRUOC_TICH_HOP",null);
    }
    public List<Audit> history(int id) {
        return jdbc.query("SELECT * FROM LichSuBaoGia WHERE MaBaoGia=? ORDER BY Id DESC",(r,n)->{
            try { return new Audit(r.getLong("Id"),r.getString("HanhDong"),r.getObject("MaTaiKhoan",Integer.class),
                time(r,"ThoiGian"),r.getString("LyDo"),json.readValue(r.getString("NoiDung"),View.class));
            } catch(JsonProcessingException ex) { throw new IllegalStateException("Không đọc được lịch sử báo giá.",ex); }
        },id);
    }
    public void notifyCustomer(View quote) {
        jdbc.update("""
            INSERT INTO ThongBao(MaKhachHang,MaPhieuSuaChua,LoaiThongBao,TieuDe,NoiDung,ThoiGian,DaDoc)
            VALUES(?,?,N'BAO_GIA',N'Báo giá cần xác nhận',?,SYSDATETIME(),0)
            """,quote.customerId(),quote.repairOrderId(),"Báo giá #"+quote.id()+", lần "+quote.revision()+" cho xe "+quote.plate()+" đang chờ bạn xem và xác nhận.");
    }
    public void requirePerformedLinesUnchanged(int orderId,List<Line> lines) {
        var started=jdbc.query("SELECT MaDichVu,SoLuong,DonGia FROM ChiTietDichVu WHERE MaPhieuSuaChua=? AND TrangThai IN (N'DANG_SUA',N'HOAN_TAT')",
            (r,n)->new Line(0,Kind.SERVICE,r.getInt(1),"",r.getInt(2),r.getBigDecimal(3),BigDecimal.ZERO),orderId);
        var used=jdbc.query("""
            SELECT ct.MaPhuTung,SUM(CASE WHEN ct.DaXacNhanSuDung=1 THEN ct.SoLuongThucDung ELSE ct.SoLuong END),MIN(ct.DonGia)
            FROM ChiTietPhieuXuat ct JOIN PhieuXuatKho px ON px.MaPhieuXuat=ct.MaPhieuXuat
            WHERE px.MaPhieuSuaChua=? AND (ct.DaXacNhanSuDung=0 OR ct.SoLuongThucDung>0) GROUP BY ct.MaPhuTung
            """,(r,n)->new Line(0,Kind.PART,r.getInt(1),"",r.getInt(2),r.getBigDecimal(3),BigDecimal.ZERO),orderId);
        for(Line actual:started) {
            if(lines.stream().noneMatch(l->l.kind()==Kind.SERVICE && l.itemId()==actual.itemId() &&
                l.quantity()==actual.quantity() && l.unitPrice().compareTo(actual.unitPrice())==0))
                throw new ConflictException("Không thể bỏ hoặc đổi giá/số lượng dịch vụ đã bắt đầu thực hiện.");
        }
        for(Line actual:used) {
            if(lines.stream().noneMatch(l->l.kind()==Kind.PART && l.itemId()==actual.itemId() && l.quantity()>=actual.quantity() &&
                actual.unitPrice()!=null && l.unitPrice().compareTo(actual.unitPrice())==0))
                throw new ConflictException("Báo giá phải giữ số lượng và đơn giá phụ tùng đã thực dùng hoặc đang cấp phát. Hãy hoàn trả phần chưa dùng trước khi giảm số lượng.");
        }
    }
    public void syncApprovedServices(View quote) {
        Set<Integer> ids=new HashSet<>();
        for(Line line:quote.lines()) if(line.kind()==Kind.SERVICE) {
            ids.add(line.itemId());
            int count=jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu WHERE MaPhieuSuaChua=? AND MaDichVu=?",Integer.class,quote.repairOrderId(),line.itemId());
            if(count==0) jdbc.update("INSERT INTO ChiTietDichVu(MaPhieuSuaChua,MaDichVu,SoLuong,DonGia,TrangThai) VALUES(?,?,?,?,N'CHO_SUA')",
                quote.repairOrderId(),line.itemId(),line.quantity(),line.unitPrice());
            else jdbc.update("UPDATE ChiTietDichVu SET SoLuong=?,DonGia=? WHERE MaPhieuSuaChua=? AND MaDichVu=? AND COALESCE(TrangThai,N'CHO_SUA') NOT IN (N'DANG_SUA',N'HOAN_TAT')",
                line.quantity(),line.unitPrice(),quote.repairOrderId(),line.itemId());
        }
        for(Integer id:jdbc.queryForList("SELECT MaDichVu FROM ChiTietDichVu WHERE MaPhieuSuaChua=? AND COALESCE(TrangThai,N'CHO_SUA') NOT IN (N'DANG_SUA',N'HOAN_TAT')",Integer.class,quote.repairOrderId()))
            if(!ids.contains(id)) jdbc.update("DELETE FROM ChiTietDichVu WHERE MaPhieuSuaChua=? AND MaDichVu=?",quote.repairOrderId(),id);
        // Expected parts remain in ChiTietBaoGia. Actual use is recorded only by warehouse confirmation.
    }
}
