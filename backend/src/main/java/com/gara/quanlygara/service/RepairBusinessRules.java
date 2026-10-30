package com.gara.quanlygara.service;

import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairOrderRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;
import java.math.BigDecimal;

/** Shared guards. Call under the caller's transaction; lock order before stock/detail rows. */
@Component
public class RepairBusinessRules {
    private final RepairOrderRepository orders;
    private final JdbcTemplate jdbc;

    public RepairBusinessRules(RepairOrderRepository orders, JdbcTemplate jdbc) {
        this.orders = orders;
        this.jdbc = jdbc;
    }

    public void lock(Integer id) {
        orders.findForUpdate(id).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
    }

    public boolean hasAcceptedQuote(Integer id) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM BaoGia WHERE MaPhieuSuaChua = ? AND TrangThai = N'DA_XAC_NHAN'",
                Integer.class, id) > 0;
    }

    public void requireAcceptedQuote(Integer id) {
        if (!hasAcceptedQuote(id)) throw new ConflictException("Khách hàng chưa xác nhận báo giá của phiếu sửa chữa.");
    }

    public void requireApprovedService(Integer orderId,Integer serviceId) {
        if(jdbc.queryForObject("""
            SELECT COUNT(*) FROM BaoGia b JOIN ChiTietBaoGia q ON q.MaBaoGia=b.MaBaoGia
            JOIN ChiTietDichVu d ON d.MaPhieuSuaChua=b.MaPhieuSuaChua AND d.MaDichVu=q.MaDichVu
            WHERE b.MaPhieuSuaChua=? AND b.TrangThai=N'DA_XAC_NHAN' AND q.MaDichVu=?
              AND q.SoLuong=d.SoLuong AND q.DonGia=d.DonGia
            """,Integer.class,orderId,serviceId)==0)
            throw new ConflictException("Hạng mục hoặc đơn giá/số lượng chưa được khách xác nhận trong báo giá hiện hành.");
    }

    /** Called while holding the repair-order lock, before locking stock rows. */
    public BigDecimal approvedPartPrice(Integer orderId,Integer partId,int quantity,boolean allocation) {
        var quotes=jdbc.query("""
            SELECT SUM(CONVERT(BIGINT,q.SoLuong)),MIN(q.DonGia),MAX(q.DonGia)
            FROM BaoGia b JOIN ChiTietBaoGia q ON q.MaBaoGia=b.MaBaoGia
            WHERE b.MaPhieuSuaChua=? AND b.TrangThai=N'DA_XAC_NHAN' AND q.MaPhuTung=?
            HAVING COUNT(*)>0
            """,(r,n)->new Object[]{r.getLong(1),r.getBigDecimal(2),r.getBigDecimal(3)},orderId,partId);
        if(quotes.isEmpty()) throw new ConflictException("Phụ tùng chưa được khách xác nhận trong báo giá hiện hành.");
        Object[] approved=quotes.getFirst();BigDecimal price=(BigDecimal)approved[1];
        if(price.compareTo((BigDecimal)approved[2])!=0) throw new ConflictException("Báo giá có đơn giá phụ tùng không thống nhất.");
        long committed=jdbc.queryForObject("""
            SELECT COALESCE(SUM(CONVERT(BIGINT,CASE WHEN ct.DaXacNhanSuDung=1 THEN ct.SoLuongThucDung
                WHEN ?=1 THEN ct.SoLuong ELSE 0 END)),0)
            FROM ChiTietPhieuXuat ct JOIN PhieuXuatKho px ON px.MaPhieuXuat=ct.MaPhieuXuat
            WHERE px.MaPhieuSuaChua=? AND ct.MaPhuTung=?
            """,Long.class,allocation?1:0,orderId,partId);
        if(committed+quantity>(Long)approved[0]) throw new ConflictException("Số lượng phụ tùng vượt báo giá đã duyệt. Cần điều chỉnh và được khách xác nhận trước.");
        return price;
    }

    public void requireEditableDetails(Integer id) {
        lock(id);
        String status = jdbc.queryForObject("SELECT TrangThai FROM PhieuSuaChua WHERE MaPhieuSuaChua = ?", String.class, id);
        if (!java.util.Set.of("MOI_TAO", "DANG_KIEM_TRA", "CHO_SUA").contains(status)
                || hasAcceptedQuote(id)
                || jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaPhieuSuaChua = ?", Integer.class, id) > 0) {
            throw new ConflictException("Chỉ sửa hạng mục dự kiến trước khi khách xác nhận báo giá và trước khi bắt đầu sửa chữa.");
        }
    }

    public void requireSettledParts(Integer id) {
        if (jdbc.queryForObject("""
                SELECT COUNT(*) FROM ChiTietPhieuXuat ct JOIN PhieuXuatKho px ON px.MaPhieuXuat = ct.MaPhieuXuat
                WHERE px.MaPhieuSuaChua = ? AND ct.DaXacNhanSuDung = 0
                """, Integer.class, id) > 0) {
            throw new ConflictException("Cần xác nhận thực dùng/hoàn trả toàn bộ phụ tùng đã cấp phát trước khi hoàn tất.");
        }
        if (jdbc.queryForObject("""
                SELECT COUNT(*) FROM ChiTietPhuTung p WHERE p.MaPhieuSuaChua = ? AND p.SoLuong <>
                (SELECT COALESCE(SUM(ct.SoLuongThucDung), 0) FROM ChiTietPhieuXuat ct
                 JOIN PhieuXuatKho px ON px.MaPhieuXuat = ct.MaPhieuXuat
                 WHERE px.MaPhieuSuaChua = p.MaPhieuSuaChua AND ct.MaPhuTung = p.MaPhuTung AND ct.DaXacNhanSuDung = 1)
                """, Integer.class, id) > 0) {
            throw new ConflictException("Chi tiết phụ tùng chưa khớp số lượng thực dùng đã xác nhận.");
        }
    }
}
