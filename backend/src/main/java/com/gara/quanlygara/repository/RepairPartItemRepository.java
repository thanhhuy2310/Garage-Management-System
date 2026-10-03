// TV3-TUAN7
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.RepairPartItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface RepairPartItemRepository extends JpaRepository<RepairPartItem, RepairPartItem.Key> {

    @Query(value = """
            SELECT ct.MaPhuTung AS itemId, pt.TenPhuTung AS itemName, ct.SoLuong AS quantity,
                   ct.DonGia AS unitPrice, CAST(NULL AS NVARCHAR(50)) AS itemStatus
            FROM ChiTietPhuTung ct
            JOIN PhuTung pt ON pt.MaPhuTung = ct.MaPhuTung
            WHERE ct.MaPhieuSuaChua = :repairOrderId
            ORDER BY ct.MaPhuTung
            """, nativeQuery = true)
    List<RepairDetailRow> findDetailRows(@Param("repairOrderId") Integer repairOrderId);
}
