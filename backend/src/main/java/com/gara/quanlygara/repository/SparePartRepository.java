// TV3-TUAN7
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.SparePart;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface SparePartRepository extends JpaRepository<SparePart, Integer> {

    Page<SparePart> findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
            String name, String manufacturer, Pageable pageable);

    // Từ khóa là số: khớp mã phụ tùng (MaPhuTung) HOẶC tên/hãng chứa chuỗi số đó.
    Page<SparePart> findByIdOrNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
            Integer id, String name, String manufacturer, Pageable pageable);

    // Bảng Kho thuộc nghiệp vụ kho (Tuần 8): ở đây chỉ đọc để kiểm tra khóa ngoại và đổ danh sách chọn.
    @Query(value = "SELECT COUNT(1) FROM Kho WHERE MaKho = :id", nativeQuery = true)
    long countWarehouse(@Param("id") Integer id);

    @Query(value = "SELECT MaKho AS id, TenKho AS name FROM Kho ORDER BY MaKho", nativeQuery = true)
    List<WarehouseView> findWarehouses();

    // ---- Tuần 8: kho. Chỉ StockLedger được dùng lockStockQuantity/updateStockQuantity để ghi tồn. ----

    // Khóa dòng phụ tùng (UPDLOCK) tới hết transaction rồi đọc tồn hiện tại (bỏ qua cache của JPA).
    @Query(value = "SELECT SoLuongTon FROM PhuTung WITH (UPDLOCK, HOLDLOCK) WHERE MaPhuTung = :id", nativeQuery = true)
    Optional<Integer> lockStockQuantity(@Param("id") Integer id);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = "UPDATE PhuTung SET SoLuongTon = :quantity WHERE MaPhuTung = :id", nativeQuery = true)
    int updateStockQuantity(@Param("id") Integer id, @Param("quantity") Integer quantity);

    // keyword = '' và status = 'ALL' nghĩa là không lọc (tránh tham số null trong JPQL).
    @Query("SELECT p FROM SparePart p WHERE "
            + "(:keyword = '' OR CAST(p.id AS string) = :keyword "
            + "OR LOWER(p.name) LIKE LOWER(CONCAT('%', :keyword, '%')) "
            + "OR LOWER(p.manufacturer) LIKE LOWER(CONCAT('%', :keyword, '%'))) "
            + "AND (:status = 'ALL' "
            + "OR (:status = 'HET_HANG' AND p.stockQuantity = 0) "
            + "OR (:status = 'SAP_HET' AND p.stockQuantity > 0 AND p.stockQuantity <= p.minStockLevel) "
            + "OR (:status = 'CON_HANG' AND p.stockQuantity > p.minStockLevel))")
    Page<SparePart> searchInventory(@Param("keyword") String keyword, @Param("status") String status, Pageable pageable);

    @Query("SELECT COUNT(p) FROM SparePart p WHERE p.stockQuantity <= p.minStockLevel")
    long countAtOrBelowMinimum();

    interface WarehouseView {
        Integer getId();

        String getName();
    }
}
