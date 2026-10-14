// TV3-TUAN8
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.StockIssue;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface StockIssueRepository extends JpaRepository<StockIssue, Integer> {

    Page<StockIssue> findAllByOrderByIdDesc(Pageable pageable);

    Page<StockIssue> findByIdInOrderByIdDesc(Collection<Integer> ids, Pageable pageable);

    // Phiếu xuất liên quan tới KTV: do họ yêu cầu hoặc họ được phân công cho phiếu sửa chữa (đọc bảng của Huy).
    @Query(value = "SELECT px.MaPhieuXuat FROM PhieuXuatKho px WHERE px.MaKyThuatVienYeuCau = :technicianId "
            + "OR EXISTS (SELECT 1 FROM PhanCongKyThuatVien pc WHERE pc.MaPhieuSuaChua = px.MaPhieuSuaChua "
            + "AND pc.MaKyThuatVien = :technicianId)", nativeQuery = true)
    List<Integer> findIdsRelatedToTechnician(@Param("technicianId") Integer technicianId);

    // Một phiếu xuất có liên quan tới KTV không (cùng điều kiện với findIdsRelatedToTechnician).
    @Query(value = "SELECT COUNT(1) FROM PhieuXuatKho px WHERE px.MaPhieuXuat = :issueId "
            + "AND (px.MaKyThuatVienYeuCau = :technicianId "
            + "OR EXISTS (SELECT 1 FROM PhanCongKyThuatVien pc WHERE pc.MaPhieuSuaChua = px.MaPhieuSuaChua "
            + "AND pc.MaKyThuatVien = :technicianId))", nativeQuery = true)
    long countRelatedToTechnician(@Param("issueId") Integer issueId, @Param("technicianId") Integer technicianId);
}
