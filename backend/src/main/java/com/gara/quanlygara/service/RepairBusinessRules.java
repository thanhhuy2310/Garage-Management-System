package com.gara.quanlygara.service;

import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairOrderRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

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
