package com.gara.quanlygara.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.util.List;

@Service
public class ApprovedRepairPartsService {
    private final JdbcTemplate db;
    private final RepairOrderQueryService orders;
    public ApprovedRepairPartsService(JdbcTemplate db,RepairOrderQueryService orders) {this.db=db;this.orders=orders;}
    public record Part(int id,String name,int approvedQuantity,BigDecimal unitPrice,int issuedQuantity,
                       int returnedQuantity,int actualUsedQuantity,String status) {}
    @Transactional(readOnly=true)
    public List<Part> get(int order,Authentication auth) {
        orders.getById(order,auth); // Apply the same technician ownership and missing-order rules.
        return db.query("""
            SELECT q.MaPhuTung,q.NoiDung,q.SoLuong,q.DonGia,
                   COALESCE(s.Issued,0),COALESCE(s.Returned,0),COALESCE(s.Used,0)
            FROM BaoGia b JOIN ChiTietBaoGia q ON q.MaBaoGia=b.MaBaoGia
            LEFT JOIN (
                SELECT x.MaPhieuSuaChua,d.MaPhuTung,SUM(CASE WHEN d.DaXuatKho=1 THEN d.SoLuong ELSE 0 END) AS Issued,
                       SUM(CASE WHEN d.DaNhapTra=1 THEN COALESCE(d.SoLuongHoanTra,0) ELSE 0 END) AS Returned,
                       SUM(COALESCE(d.SoLuongThucDung,0)) AS Used
                FROM PhieuXuatKho x JOIN ChiTietPhieuXuat d ON d.MaPhieuXuat=x.MaPhieuXuat
                GROUP BY x.MaPhieuSuaChua,d.MaPhuTung
            ) s ON s.MaPhieuSuaChua=b.MaPhieuSuaChua AND s.MaPhuTung=q.MaPhuTung
            WHERE b.MaPhieuSuaChua=? AND b.TrangThai=N'DA_XAC_NHAN' AND q.MaPhuTung IS NOT NULL
            ORDER BY q.MaChiTietBaoGia
            """,(r,n)->new Part(r.getInt(1),r.getString(2),r.getInt(3),r.getBigDecimal(4),r.getInt(5),r.getInt(6),r.getInt(7),
                r.getInt(5)==0?"Chưa cấp phát":r.getInt(5)-r.getInt(6)<r.getInt(3)?"Cấp phát một phần":"Đã cấp phát"),order);
    }
}
