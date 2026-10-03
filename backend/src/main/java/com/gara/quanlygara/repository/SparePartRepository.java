// TV3-TUAN7
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.SparePart;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface SparePartRepository extends JpaRepository<SparePart, Integer> {

    Page<SparePart> findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
            String name, String manufacturer, Pageable pageable);

    // Bảng Kho thuộc nghiệp vụ kho (Tuần 8): ở đây chỉ đọc để kiểm tra khóa ngoại và đổ danh sách chọn.
    @Query(value = "SELECT COUNT(1) FROM Kho WHERE MaKho = :id", nativeQuery = true)
    long countWarehouse(@Param("id") Integer id);

    @Query(value = "SELECT MaKho AS id, TenKho AS name FROM Kho ORDER BY MaKho", nativeQuery = true)
    List<WarehouseView> findWarehouses();

    interface WarehouseView {
        Integer getId();

        String getName();
    }
}
