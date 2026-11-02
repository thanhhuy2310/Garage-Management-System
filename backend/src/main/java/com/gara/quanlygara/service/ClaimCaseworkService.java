package com.gara.quanlygara.service;

import com.gara.quanlygara.exception.*;
import jakarta.validation.constraints.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.util.*;

@Service
@Transactional(readOnly=true)
public class ClaimCaseworkService {
    public record FollowUp(@NotNull @PositiveOrZero Integer version,
                           @NotBlank String status, @NotBlank @Size(max=150) String assessor,
                           @Size(max=150) String contact, @NotBlank @Size(max=500) String note) {}
    public record Assessment(@NotNull @PositiveOrZero Integer version, UUID item,
                             @Positive int documentId, @NotBlank @Size(max=500) String damage,
                             @NotBlank @Size(max=1000) String finding) {}
    public record Document(String filename,String type,byte[] bytes) {}
    private final JdbcTemplate db;
    public ClaimCaseworkService(JdbcTemplate db) { this.db=db; }

    private static final Map<String,String> NEXT=Map.of("MOI_TAO","DA_THONG_BAO",
            "DA_THONG_BAO","CHO_GIAM_DINH","CHO_GIAM_DINH","DANG_XU_LY");
    public Map<String,Object> overview(int id) {
        var claims=db.queryForList("""
            SELECT h.PhienBanHoSo AS version,h.TrangThai AS status,p.MaPhieuSuaChua AS orderId,
                   hd.MaHoaDon AS invoiceId FROM HoSoBaoHiem h
            LEFT JOIN PhieuSuaChua p ON p.MaTiepNhan=h.MaTiepNhan
            LEFT JOIN HoaDon hd ON hd.MaPhieuSuaChua=p.MaPhieuSuaChua WHERE h.MaHoSoBaoHiem=?
            """,id);
        if(claims.isEmpty()) throw new ResourceNotFoundException("Không tìm thấy hồ sơ.");
        var result=new LinkedHashMap<>(claims.getFirst());
        result.put("documents",db.queryForList("""
            SELECT MaChungTu AS id,Loai AS category,TenTep AS filename,NgayTai AS createdAt,
                   MaNhanVien AS employeeId FROM ChungTuBaoHiem WHERE MaHoSoBaoHiem=? ORDER BY MaChungTu DESC
            """,id));
        result.put("assessments",db.queryForList("""
            SELECT Id AS id,CONVERT(varchar(36),HangMuc) AS item,Lan AS revision,MoTa AS damage,
                   KetQua AS finding,MaChungTu AS documentId,NgayGhi AS createdAt
            FROM KetQuaGiamDinh WHERE MaHoSoBaoHiem=? ORDER BY Id DESC
            """,id));
        return result;
    }

    String lock(int id,int version) {
        var rows=db.queryForList("SELECT PhienBanHoSo,TrangThai FROM HoSoBaoHiem WITH (UPDLOCK,HOLDLOCK) WHERE MaHoSoBaoHiem=?",id);
        if(rows.isEmpty()) throw new ResourceNotFoundException("Không tìm thấy hồ sơ.");
        var row=rows.getFirst();
        if(((Number)row.get("PhienBanHoSo")).intValue()!=version) throw new ConflictException("Hồ sơ đã thay đổi. Vui lòng tải lại.");
        String status=(String) row.get("TrangThai");
        if("DA_DONG".equals(status)) throw new ConflictException("Hồ sơ đã đóng.");
        return status;
    }

    void event(int id,int staff,String action,String before,String after,String note) {
        db.update("UPDATE HoSoBaoHiem SET PhienBanHoSo=PhienBanHoSo+1,TrangThai=? WHERE MaHoSoBaoHiem=?",after,id);
        db.update("""
            INSERT INTO NhatKyHoSoBaoHiem(MaHoSoBaoHiem,MaNhanVien,HanhDong,TrangThaiTruoc,TrangThaiSau,GhiChu)
            VALUES(?,?,?,?,?,?)
            """,id,staff,action,before,after,note);
    }

    @Transactional
    public void followUp(int id,FollowUp input,int staff) {
        String before=lock(id,input.version());
        if(!before.equals(input.status()) && !input.status().equals(NEXT.get(before)))
            throw new ConflictException("Bước xử lý hồ sơ không hợp lệ.");
        db.update("""
            UPDATE HoSoBaoHiem SET GiamDinhVien=?,LienHeGiamDinh=?,
                NgayThongBao=CASE WHEN ?='DA_THONG_BAO' AND NgayThongBao IS NULL THEN SYSDATETIME() ELSE NgayThongBao END
            WHERE MaHoSoBaoHiem=?
            """,input.assessor().strip(),input.contact(),input.status(),id);
        event(id,staff,"CAP_NHAT",before,input.status(),input.assessor().strip()+" · "+input.note().strip());
    }

    @Transactional
    public void assess(int id,Assessment input,int staff) {
        String status=lock(id,input.version());
        if(!Set.of("CHO_GIAM_DINH","DANG_XU_LY").contains(status)) throw new ConflictException("Hồ sơ chưa ở bước giám định.");
        requireDocument(id,input.documentId(),"GIAM_DINH");
        UUID item=input.item()==null?UUID.randomUUID():input.item();
        int latest=db.queryForObject("SELECT COALESCE(MAX(Lan),0) FROM KetQuaGiamDinh WHERE MaHoSoBaoHiem=? AND HangMuc=?",Integer.class,id,item.toString());
        if(input.item()!=null && latest==0) throw new ResourceNotFoundException("Hạng mục không thuộc hồ sơ.");
        db.update("INSERT INTO KetQuaGiamDinh(MaHoSoBaoHiem,HangMuc,Lan,MoTa,KetQua,MaChungTu,MaNhanVien) VALUES(?,?,?,?,?,?,?)",
                id,item.toString(),latest+1,input.damage().strip(),input.finding().strip(),input.documentId(),staff);
        event(id,staff,"GIAM_DINH",status,"DANG_XU_LY",input.damage().strip());
    }

    void requireDocument(int id,int doc,String category) {
        if(db.queryForObject("SELECT COUNT(*) FROM ChungTuBaoHiem WHERE MaHoSoBaoHiem=? AND MaChungTu=? AND Loai=?",Integer.class,id,doc,category)==0)
            throw new BadRequestException("Chứng từ không đúng loại hoặc không thuộc hồ sơ này.");
    }

    @Transactional
    public void upload(int id,int version,String category,MultipartFile file,int staff) throws IOException {
        if(!Set.of("GIAM_DINH","QUYET_DINH","CHUYEN_TIEN","KHAC").contains(category))
            throw new BadRequestException("Loại chứng từ không hợp lệ.");
        if(file.isEmpty() || file.getSize()>2097152) throw new BadRequestException("Chứng từ phải từ 1 byte đến 2 MB.");
        byte[] bytes=file.getBytes();
        String type;
        if(starts(bytes,0x25,0x50,0x44,0x46,0x2d)) type="application/pdf";
        else if(starts(bytes,0xff,0xd8,0xff)) type="image/jpeg";
        else if(starts(bytes,137,80,78,71,13,10,26,10)) type="image/png";
        else throw new BadRequestException("Chỉ nhận chứng từ PDF, JPEG hoặc PNG.");
        String name=Objects.toString(file.getOriginalFilename(),"").strip();
        if(name.isEmpty() || name.length()>180 || name.chars().anyMatch(c->c<32 || c==127 || c==47 || c==92))
            throw new BadRequestException("Tên tệp không hợp lệ.");
        String status=lock(id,version);
        db.update("INSERT INTO ChungTuBaoHiem(MaHoSoBaoHiem,Loai,TenTep,Kieu,NoiDung,MaNhanVien) VALUES(?,?,?,?,?,?)",id,category,name,type,bytes,staff);
        event(id,staff,"LUU_CHUNG_TU",status,status,name);
    }

    private boolean starts(byte[] bytes,int... signature) {
        if(bytes.length<signature.length) return false;
        for(int i=0;i<signature.length;i++) if((bytes[i]&255)!=signature[i]) return false;
        return true;
    }

    public Document download(int id,int doc) {
        return db.query("SELECT TenTep,Kieu,NoiDung FROM ChungTuBaoHiem WHERE MaHoSoBaoHiem=? AND MaChungTu=?",
                (r,n)->new Document(r.getString(1),r.getString(2),r.getBytes(3)),id,doc)
                .stream().findFirst().orElseThrow(()->new ResourceNotFoundException("Không tìm thấy chứng từ."));
    }
}
