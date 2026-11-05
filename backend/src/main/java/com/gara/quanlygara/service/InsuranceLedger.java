package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.billing.BillingRequests.RecordPayment;
import com.gara.quanlygara.exception.*;
import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.*;

@Service
@Transactional(readOnly=true)
public class InsuranceLedger {
    public record Amount(@Positive int lineId,@NotNull @DecimalMin("0") @Digits(integer=16,fraction=2) BigDecimal amount) {}
    public record Allocation(@NotNull @Min(0) Integer version,@Positive int quoteId,@Min(1) int revision,
                             @NotNull Boolean direct,@NotEmpty @Size(max=100) List<@NotNull @Valid Amount> lines) {}
    public record Decision(@NotNull @Min(0) Integer version,@Positive int proposalId,@Positive int documentId,
                           @NotBlank @Size(max=100) String reference,@NotBlank @Size(max=500) String reason,
                           @NotEmpty @Size(max=100) List<@NotNull @Valid Amount> lines) {}
    public record ManualDecision(@Valid @NotNull Allocation allocation,@Positive int documentId,
                                 @NotBlank @Size(max=100) String reference,@NotBlank @Size(max=500) String reason) {}
    public record Settlement(@NotNull @Min(0) Integer version,@Positive int proposalId,@Positive int invoiceId,
                             @NotEmpty @Size(max=100) List<@NotNull @Valid Amount> lines) {}
    private final JdbcTemplate db;
    private final ClaimCaseworkService cases;
    public InsuranceLedger(JdbcTemplate db,ClaimCaseworkService cases) {this.db=db;this.cases=cases;}

    private int number(Map<String,Object> row,String key) {return ((Number)row.get(key)).intValue();}
    private BigDecimal money(Map<String,Object> row,String key) {return (BigDecimal)row.get(key);}
    private Map<String,Object> currentQuote(int claim) {
        var rows=db.queryForList("""
            SELECT b.MaBaoGia AS id,b.LanDieuChinh AS revision,b.TrangThai AS status
            FROM HoSoBaoHiem h JOIN PhieuSuaChua r ON r.MaTiepNhan=h.MaTiepNhan
            JOIN BaoGia b ON b.MaPhieuSuaChua=r.MaPhieuSuaChua WHERE h.MaHoSoBaoHiem=?
            """,claim);
        if(rows.isEmpty()) throw new ConflictException("Hồ sơ chưa có báo giá sửa chữa.");
        return rows.getFirst();
    }
    private Map<Integer,BigDecimal> amounts(List<Amount> lines,int expected) {
        var values=new HashMap<Integer,BigDecimal>();
        for(var line:lines) if(values.put(line.lineId(),line.amount())!=null) throw new BadRequestException("Trùng dòng báo giá.");
        if(values.size()!=expected) throw new BadRequestException("Cần phân bổ từng dòng, kể cả dòng có giá trị bằng 0.");
        return values;
    }
    private BigDecimal bounded(Map<Integer,BigDecimal> values,int key,BigDecimal max) {
        var value=values.get(key);
        if(value==null || value.compareTo(max)>0) throw new BadRequestException("Phân bổ sai dòng hoặc vượt hạn mức của dòng.");
        return value;
    }

    // A repair can exist before its claim. Non-insured orders do not need any insurance decision.
    Integer claimForOrder(int order) {
        return db.query("""
            SELECT h.MaHoSoBaoHiem FROM HoSoBaoHiem h JOIN PhieuSuaChua r ON r.MaTiepNhan=h.MaTiepNhan
            WHERE r.MaPhieuSuaChua=?
            """,(r,n)->r.getInt(1),order).stream().findFirst().orElse(null);
    }
    public void requireDecision(int order) {
        Integer claim=claimForOrder(order);
        if(claim!=null && db.queryForObject("""
            SELECT COUNT(*) FROM DeNghiBoiThuong d JOIN BaoGia b ON b.MaBaoGia=d.MaBaoGia AND b.LanDieuChinh=d.LanDieuChinh
            WHERE d.MaHoSoBaoHiem=? AND b.MaPhieuSuaChua=? AND d.MaChungTu IS NOT NULL
            """,Integer.class,claim,order)==0) throw new ConflictException("Thiếu quyết định bảo hiểm cho phiên bản báo giá hiện tại.");
    }

    private List<Map<String,Object>> rows(int proposal) {
        return db.queryForList("""
            SELECT DongBaoGia AS lineId,Loai AS kind,MaHang AS itemId,Ten AS name,ThanhTien AS total,
                   DeNghi AS requested,ChapThuan AS approved,PhaiThu AS payable
            FROM PhanBoDongBaoHiem WHERE DeNghiId=? ORDER BY DongBaoGia
            """,proposal);
    }
    public Map<String,Object> details(int claim) {
        var casesView=cases.overview(claim);
        var proposals=db.queryForList("""
            SELECT Id AS id,MaBaoGia AS quoteId,LanDieuChinh AS revision,NhanTienTaiGara AS direct,
                   MaChungTu AS documentId,SoQuyetDinh AS reference FROM DeNghiBoiThuong
            WHERE MaHoSoBaoHiem=? ORDER BY Id DESC
            """,claim);
        for(var proposal:proposals) proposal.put("lines",rows(number(proposal,"id")));
        casesView.put("proposals",proposals);
        var invoice=(Integer)casesView.get("invoiceId");
        casesView.put("balance",invoice==null?null:balance(invoice));
        casesView.put("receipts",db.queryForList("""
            SELECT t.MaThanhToan AS id,t.SoTien AS amount,t.NgayThanhToan AS receivedAt,
                   b.MaChungTu AS documentId,b.ThamChieu AS reference FROM ThuBaoHiem b
            JOIN ThanhToan t ON t.MaThanhToan=b.MaThanhToan WHERE b.MaHoSoBaoHiem=? ORDER BY t.MaThanhToan
            """,claim));
        return casesView;
    }

    private void lockOrder(int claim) {
        if(db.queryForList("""
            SELECT r.MaPhieuSuaChua FROM PhieuSuaChua r WITH (UPDLOCK,HOLDLOCK)
            JOIN HoSoBaoHiem h ON h.MaTiepNhan=r.MaTiepNhan WHERE h.MaHoSoBaoHiem=?
            """,claim).isEmpty()) throw new ConflictException("Chưa có phiếu sửa chữa.");
    }

    @Transactional
    public void propose(int claim,Allocation input,int staff) {
        lockOrder(claim);
        String status=cases.lock(claim,input.version());
        if(!"DANG_XU_LY".equals(status) || db.queryForObject("SELECT COUNT(*) FROM KetQuaGiamDinh WHERE MaHoSoBaoHiem=?",Integer.class,claim)==0)
            throw new ConflictException("Cần kết quả giám định trước khi đề nghị chi trả.");
        snapshot(claim,input);
        cases.event(claim,staff,"DE_NGHI_CHI_TRA",status,status,"Báo giá #"+input.quoteId()+", lần "+input.revision());
    }

    @Transactional
    public void manualDecision(int claim,ManualDecision decision,int staff) {
        var input=decision.allocation();
        lockOrder(claim);
        String status=cases.lock(claim,input.version());
        if(!Set.of("MOI_TAO","DA_THONG_BAO","CHO_GIAM_DINH","DANG_XU_LY").contains(status))
            throw new ConflictException("Hồ sơ không còn mở để ghi nhận quyết định.");
        cases.requireDocument(claim,decision.documentId(),"QUYET_DINH");
        validatePolicyTotal(claim,input.lines().stream().map(Amount::amount).reduce(BigDecimal.ZERO,BigDecimal::add));
        int proposal=snapshot(claim,input);
        cases.event(claim,staff,"DOI_CHIEU_QUYET_DINH",status,"DANG_XU_LY","Nhân viên đối chiếu văn bản "+decision.reference());
        decide(claim,new Decision(input.version()+1,proposal,decision.documentId(),decision.reference(),decision.reason(),input.lines()),staff);
    }

    private int snapshot(int claim,Allocation input) {
        var quote=currentQuote(claim);
        if(number(quote,"id")!=input.quoteId() || number(quote,"revision")!=input.revision() ||
            !Set.of("CHO_XAC_NHAN","DA_XAC_NHAN").contains(quote.get("status")))
            throw new ConflictException("Báo giá chưa gửi hoặc đã thay đổi.");
        var items=db.queryForList("""
            SELECT MaChiTietBaoGia AS id,MaDichVu AS serviceId,MaPhuTung AS partId,NoiDung AS name,
                   CAST(SoLuong*DonGia AS DECIMAL(18,2)) AS total FROM ChiTietBaoGia WHERE MaBaoGia=?
            """,input.quoteId());
        var requested=amounts(input.lines(),items.size());
        int proposal=db.queryForObject("""
            INSERT INTO DeNghiBoiThuong(MaHoSoBaoHiem,MaBaoGia,LanDieuChinh,NhanTienTaiGara)
            OUTPUT INSERTED.Id VALUES(?,?,?,?)
            """,Integer.class,claim,input.quoteId(),input.revision(),input.direct());
        for(var row:items) {
            int line=number(row,"id");
            boolean service=row.get("serviceId")!=null;
            var total=money(row,"total");
            db.update("INSERT INTO PhanBoDongBaoHiem(DeNghiId,DongBaoGia,Loai,MaHang,Ten,ThanhTien,DeNghi) VALUES(?,?,?,?,?,?,?)",
                    proposal,line,service?"SERVICE":"PART",row.get(service?"serviceId":"partId"),row.get("name"),total,bounded(requested,line,total));
        }
        return proposal;
    }

    private void validatePolicyTotal(int claim,BigDecimal totalApproved) {
        if(totalApproved.signum()>0) {
            var policies=db.queryForList("""
                SELECT k.HoTen,p.TenChuXeTrenDangKy,p.TenChuXeTrenChungNhan,p.SoTienBaoHiem
                FROM HoSoBaoHiem h JOIN HopDongBaoHiem p ON h.MaHopDongBaoHiem=p.MaHopDongBaoHiem
                JOIN Xe x ON x.MaXe=p.MaXe JOIN KhachHang k ON k.MaKhachHang=x.MaKhachHang
                WHERE h.MaHoSoBaoHiem=? AND p.TrangThaiXacMinh=N'DA_XAC_MINH'
                  AND p.MaKhachHang=x.MaKhachHang AND CAST(h.ThoiDiemSuCo AS DATE) BETWEEN p.NgayBatDau AND p.NgayKetThuc
                """,claim);
            if(policies.isEmpty()) throw new ConflictException("Chưa xác minh hợp đồng, sai chủ xe hoặc ngoài thời hạn tại ngày xảy ra sự cố.");
            var policy=policies.getFirst();
            InsuranceCatalogService.validateOwnerNames((String)policy.get("TenChuXeTrenDangKy"),(String)policy.get("TenChuXeTrenChungNhan"),(String)policy.get("HoTen"));
            var limit=(BigDecimal)policy.get("SoTienBaoHiem");
            if(limit!=null && totalApproved.compareTo(limit)>0) throw new ConflictException("Số tiền chấp thuận vượt số tiền bảo hiểm ghi trên hợp đồng.");
        }
    }

    private Map<String,Object> currentProposal(int claim,int proposal) {
        var quote=currentQuote(claim);
        var list=db.queryForList("SELECT Id,NhanTienTaiGara,MaChungTu FROM DeNghiBoiThuong WHERE Id=? AND MaHoSoBaoHiem=? AND MaBaoGia=? AND LanDieuChinh=?",
                proposal,claim,quote.get("id"),quote.get("revision"));
        if(list.isEmpty()) throw new ConflictException("Đề nghị không thuộc phiên bản báo giá hiện tại.");
        return list.getFirst();
    }
    @Transactional
    public void decide(int claim,Decision input,int staff) {
        lockOrder(claim);
        String status=cases.lock(claim,input.version());
        var proposal=currentProposal(claim,input.proposalId());
        if(proposal.get("MaChungTu")!=null) throw new ConflictException("Đề nghị đã có quyết định. Cần lập phiên bản báo giá mới nếu điều chỉnh.");
        cases.requireDocument(claim,input.documentId(),"QUYET_DINH");
        var items=rows(input.proposalId());
        var values=amounts(input.lines(),items.size());
        BigDecimal totalApproved=values.values().stream().reduce(BigDecimal.ZERO,BigDecimal::add);
        validatePolicyTotal(claim,totalApproved);
        for(var row:items) {
            int line=number(row,"lineId");
            db.update("UPDATE PhanBoDongBaoHiem SET ChapThuan=? WHERE DeNghiId=? AND DongBaoGia=?",
                    bounded(values,line,money(row,"requested")),input.proposalId(),line);
        }
        db.update("UPDATE DeNghiBoiThuong SET MaChungTu=?,SoQuyetDinh=? WHERE Id=?",input.documentId(),input.reference().strip(),input.proposalId());
        cases.event(claim,staff,"QUYET_DINH_CHI_TRA",status,status,input.reference().strip()+" · "+input.reason().strip());
    }

    public record CustomerShare(BigDecimal approved, boolean direct, BigDecimal customerAmount, boolean settled, BigDecimal remaining,BigDecimal total,BigDecimal garageAmount) {}
    public CustomerShare customerShare(com.gara.quanlygara.dto.quotation.QuotationDtos.View quote) {
        Integer claim=claimForOrder(quote.repairOrderId());
        if(claim==null) return null;
        var rows=db.queryForList("""
            SELECT d.Id,d.NhanTienTaiGara,d.MaChungTu,c.MaHoaDon,
                   (SELECT SUM(p.ChapThuan) FROM PhanBoDongBaoHiem p WHERE p.DeNghiId=d.Id) AS approved
            FROM DeNghiBoiThuong d LEFT JOIN CongNoBaoHiem c ON c.DeNghiId=d.Id
            WHERE d.MaHoSoBaoHiem=? AND d.MaBaoGia=? AND d.LanDieuChinh=?
            """,claim,quote.id(),quote.revision());
        if(rows.isEmpty() || rows.getFirst().get("MaChungTu")==null) return new CustomerShare(null,false,null,false,null,quote.total(),null);
        var row=rows.getFirst();
        boolean direct=Boolean.TRUE.equals(row.get("NhanTienTaiGara"));
        BigDecimal approved=money(row,"approved");
        if(row.get("MaHoaDon")!=null) {
            var b=balance(number(row,"MaHoaDon"));
            return new CustomerShare(approved,direct,b.customerDue(),true,b.customerDue().subtract(b.customerPaid()),b.customerDue().add(b.insurerDue()),b.insurerDue());
        }
        return new CustomerShare(approved,direct,direct?quote.total().subtract(approved):quote.total(),false,null,quote.total(),direct?approved:BigDecimal.ZERO);
    }

    public record Balance(BigDecimal insurerDue,BigDecimal customerDue,BigDecimal insurerPaid,BigDecimal customerPaid) {}
    public Balance balance(int invoice) {
        return db.query("""
            SELECT c.BaoHiem,c.KhachHang,
                COALESCE((SELECT SUM(t.SoTien) FROM ThanhToan t JOIN ThuBaoHiem b ON b.MaThanhToan=t.MaThanhToan WHERE t.MaHoaDon=c.MaHoaDon),0),
                COALESCE((SELECT SUM(t.SoTien) FROM ThanhToan t WHERE t.MaHoaDon=c.MaHoaDon AND NOT EXISTS(SELECT 1 FROM ThuBaoHiem b WHERE b.MaThanhToan=t.MaThanhToan)),0)
            FROM CongNoBaoHiem c WHERE c.MaHoaDon=?
            """,(r,n)->new Balance(r.getBigDecimal(1),r.getBigDecimal(2),r.getBigDecimal(3),r.getBigDecimal(4)),invoice).stream().findFirst().orElse(null);
    }
    @Transactional
    public void settle(int claim,Settlement input,int staff) {
        var invoices=db.queryForList("""
            SELECT i.TongTien FROM HoaDon i WITH (UPDLOCK,HOLDLOCK) JOIN PhieuSuaChua r ON i.MaPhieuSuaChua=r.MaPhieuSuaChua
            JOIN HoSoBaoHiem h ON h.MaTiepNhan=r.MaTiepNhan WHERE i.MaHoaDon=? AND h.MaHoSoBaoHiem=?
            """,input.invoiceId(),claim);
        if(invoices.isEmpty()) throw new ConflictException("Hóa đơn không thuộc hồ sơ.");
        String status=cases.lock(claim,input.version());
        var proposal=currentProposal(claim,input.proposalId());
        if(proposal.get("MaChungTu")==null || balance(input.invoiceId())!=null) throw new ConflictException("Chưa có quyết định hoặc hóa đơn đã phân bổ.");
        var items=rows(input.proposalId());
        var values=amounts(input.lines(),items.size());
        BigDecimal insurer=BigDecimal.ZERO;
        for(var row:items) {
            boolean service="SERVICE".equals(row.get("kind"));
            String actual=service?"ChiTietDichVu":"ChiTietPhuTung";
            String key=service?"MaDichVu":"MaPhuTung";
            var cost=db.queryForObject("SELECT COALESCE(SUM(d.SoLuong*d.DonGia),0) FROM "+actual+" d JOIN HoaDon i ON i.MaPhieuSuaChua=d.MaPhieuSuaChua WHERE i.MaHoaDon=? AND d."+key+"=?",
                    BigDecimal.class,input.invoiceId(),row.get("itemId"));
            int line=number(row,"lineId");
            var cap=Boolean.TRUE.equals(proposal.get("NhanTienTaiGara"))?cost.min(money(row,"approved")):BigDecimal.ZERO;
            var payable=bounded(values,line,cap);
            insurer=insurer.add(payable);
            db.update("UPDATE PhanBoDongBaoHiem SET PhaiThu=? WHERE DeNghiId=? AND DongBaoGia=?",payable,input.proposalId(),line);
        }
        BigDecimal customer=money(invoices.getFirst(),"TongTien").subtract(insurer);
        if(customer.signum()<0 || db.queryForObject("SELECT COALESCE(SUM(SoTien),0) FROM ThanhToan WHERE MaHoaDon=?",BigDecimal.class,input.invoiceId()).compareTo(customer)>0)
            throw new ConflictException("Phân bổ không khớp số tiền hóa đơn hoặc số tiền khách đã trả.");
        db.update("INSERT INTO CongNoBaoHiem(MaHoaDon,DeNghiId,BaoHiem,KhachHang) VALUES(?,?,?,?)",input.invoiceId(),input.proposalId(),insurer,customer);
        cases.event(claim,staff,"PHAN_BO_HOA_DON",status,status,"Bảo hiểm: "+insurer+", khách: "+customer);
    }
    void validateReceipt(int invoice,Integer claim,RecordPayment input) {
        boolean insurer="INSURER".equals(input.payer());
        if(!insurer && (input.documentId()!=null || input.reference()!=null)) throw new BadRequestException("Chỉ khoản thu bảo hiểm mới sử dụng chứng từ đối soát.");
        if(claim==null) {
            if(insurer) throw new BadRequestException("Hóa đơn không có hồ sơ bảo hiểm.");
            return;
        }
        var balance=balance(invoice);
        if(balance==null) throw new ConflictException("Cần phân bổ hóa đơn trước khi thu tiền.");
        if(insurer) {
            if(!"CHUYEN_KHOAN".equals(input.method()) || input.documentId()==null || input.reference()==null || input.reference().isBlank())
                throw new BadRequestException("Khoản bảo hiểm cần chứng từ và mã giao dịch chuyển khoản.");
            cases.requireDocument(claim,input.documentId(),"CHUYEN_TIEN");
        }
        BigDecimal left=insurer?balance.insurerDue.subtract(balance.insurerPaid):balance.customerDue.subtract(balance.customerPaid);
        if(input.amount().compareTo(left)>0) throw new ConflictException("Số tiền vượt công nợ của bên trả tiền.");
    }
    boolean matchesReceipt(int payment,RecordPayment input) {
        var rows=db.queryForList("SELECT MaChungTu,ThamChieu FROM ThuBaoHiem WHERE MaThanhToan=?",payment);
        if(!"INSURER".equals(input.payer())) return rows.isEmpty();
        return !rows.isEmpty() && Objects.equals(input.documentId(),rows.getFirst().get("MaChungTu")) && Objects.equals(input.reference(),rows.getFirst().get("ThamChieu"));
    }
    void saveReceipt(int payment,int invoice,int claim,RecordPayment input,int staff) {
        db.update("INSERT INTO ThuBaoHiem(MaThanhToan,MaHoaDon,MaHoSoBaoHiem,MaChungTu,ThamChieu) VALUES(?,?,?,?,?)",
            payment,invoice,claim,input.documentId(),input.reference());
        var row=db.queryForMap("SELECT PhienBanHoSo,TrangThai FROM HoSoBaoHiem WITH (UPDLOCK,HOLDLOCK) WHERE MaHoSoBaoHiem=?",claim);
        String status=(String)row.get("TrangThai");
        cases.event(claim,staff,"THU_BAO_HIEM",status,status,input.reference()+" · "+input.amount());
    }
    @Transactional
    public void close(int claim,int version,int staff) {
        var invoice=(Integer)cases.overview(claim).get("invoiceId");
        if(invoice!=null) db.queryForObject("SELECT MaHoaDon FROM HoaDon WITH (UPDLOCK,HOLDLOCK) WHERE MaHoaDon=?",Integer.class,invoice);
        String status=cases.lock(claim,version);
        var b=invoice==null?null:balance(invoice);
        if(b==null || b.insurerPaid.compareTo(b.insurerDue)!=0 || b.customerPaid.compareTo(b.customerDue)!=0)
            throw new ConflictException("Chỉ đóng hồ sơ sau khi đã đối soát đủ hai khoản phải thu.");
        cases.event(claim,staff,"DONG_HO_SO",status,"DA_DONG","Đã đối soát hóa đơn #"+invoice);
    }
}
