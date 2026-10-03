// TV3-TUAN7
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.RepairServiceItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

public interface RepairServiceItemRepository extends JpaRepository<RepairServiceItem, RepairServiceItem.Key> {

    @Query(value = """
            SELECT ct.MaDichVu AS itemId, dv.TenDichVu AS itemName, ct.SoLuong AS quantity,
                   ct.DonGia AS unitPrice, ct.TrangThai AS itemStatus
            FROM ChiTietDichVu ct
            JOIN DichVu dv ON dv.MaDichVu = ct.MaDichVu
            WHERE ct.MaPhieuSuaChua = :repairOrderId
            ORDER BY ct.MaDichVu
            """, nativeQuery = true)
    List<RepairDetailRow> findDetailRows(@Param("repairOrderId") Integer repairOrderId);

    // Chỉ ĐỌC bảng của module khác (Trung: PhieuSuaChua, Huy: DichVu); không tạo entity/module thứ hai cho chúng.
    @Query(value = "SELECT TrangThai FROM PhieuSuaChua WHERE MaPhieuSuaChua = :repairOrderId", nativeQuery = true)
    Optional<String> findRepairOrderStatus(@Param("repairOrderId") Integer repairOrderId);

    @Query(value = "SELECT DonGia FROM DichVu WHERE MaDichVu = :serviceId", nativeQuery = true)
    Optional<BigDecimal> findServiceCatalogPrice(@Param("serviceId") Integer serviceId);
}
