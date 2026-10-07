// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.StockIssueItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface StockIssueItemRepository extends JpaRepository<StockIssueItem, StockIssueItem.Key> {

    List<StockIssueItem> findByIssueId(Integer issueId);

    List<StockIssueItem> findByIssueIdIn(Collection<Integer> issueIds);

    // Chỉ ĐỌC các bảng của module khác (Huy: PhanCongKyThuatVien; Trung: BaoGia).
    @Query(value = "SELECT COUNT(1) FROM PhanCongKyThuatVien WHERE MaPhieuSuaChua = :orderId "
            + "AND MaKyThuatVien = :technicianId", nativeQuery = true)
    long countAssignment(@Param("orderId") Integer orderId, @Param("technicianId") Integer technicianId);

    @Query(value = "SELECT COUNT(1) FROM BaoGia WHERE MaPhieuSuaChua = :orderId AND TrangThai = N'DA_XAC_NHAN'",
            nativeQuery = true)
    long countConfirmedQuotation(@Param("orderId") Integer orderId);

    // Số lượng đã cấp phát nhưng chưa xác nhận thực dùng (chưa trừ tồn): dùng để tính tồn khả dụng.
    @Query(value = "SELECT COALESCE(SUM(SoLuong), 0) FROM ChiTietPhieuXuat WHERE MaPhuTung = :partId "
            + "AND DaXacNhanSuDung = 0", nativeQuery = true)
    long sumPendingAllocation(@Param("partId") Integer partId);

    // Tổng thực dùng đã xác nhận của một phụ tùng trong một phiếu sửa chữa (qua mọi phiếu xuất).
    @Query(value = "SELECT COALESCE(SUM(ct.SoLuongThucDung), 0) FROM ChiTietPhieuXuat ct "
            + "JOIN PhieuXuatKho px ON px.MaPhieuXuat = ct.MaPhieuXuat "
            + "WHERE px.MaPhieuSuaChua = :orderId AND ct.MaPhuTung = :partId AND ct.DaXacNhanSuDung = 1",
            nativeQuery = true)
    long sumConfirmedActual(@Param("orderId") Integer orderId, @Param("partId") Integer partId);
}
