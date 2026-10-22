// TV3-TUAN10
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.MaintenanceReminder;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

public interface MaintenanceReminderRepository extends JpaRepository<MaintenanceReminder, Integer> {

    // vehicleId = 0 và status = 'ALL' nghĩa là không lọc (tránh tham số null trong JPQL).
    @Query(value = "SELECT r FROM MaintenanceReminder r WHERE (:vehicleId = 0 OR r.vehicleId = :vehicleId) "
            + "AND (:status = 'ALL' OR r.status = :status) ORDER BY r.id DESC",
            countQuery = "SELECT COUNT(r) FROM MaintenanceReminder r WHERE (:vehicleId = 0 OR r.vehicleId = :vehicleId) "
                    + "AND (:status = 'ALL' OR r.status = :status)")
    Page<MaintenanceReminder> search(@Param("vehicleId") int vehicleId, @Param("status") String status, Pageable pageable);

    /**
     * Lịch CHO_NHAC đã đến hạn: ngày đến hạn <= :today, hoặc Xe.SoKm đã đạt/vượt mốc SoKmDenHan.
     * Lịch thiếu dữ liệu (NULL) không bao giờ được suy đoán là đến hạn; lịch đã nhắc/đã hủy không được chọn.
     * Cột: 0 MaLichNhac, 1 MaXe, 2 MaKhachHang, 3 BienSo, 4 NgayDenHan, 5 SoKmDenHan, 6 SoKm, 7 GhiChu, 8 TenDichVu.
     */
    @Query(value = """
            SELECT ln.MaLichNhac, ln.MaXe, xe.MaKhachHang, xe.BienSo, ln.NgayDenHan, ln.SoKmDenHan, xe.SoKm,
                   ln.GhiChu, dv.TenDichVu
            FROM LichNhacBaoDuong ln
            JOIN Xe xe ON xe.MaXe = ln.MaXe
            LEFT JOIN DichVu dv ON dv.MaDichVu = ln.MaDichVu
            WHERE ln.TrangThai = N'CHO_NHAC'
              AND ((ln.NgayDenHan IS NOT NULL AND ln.NgayDenHan <= :today)
                   OR (ln.SoKmDenHan IS NOT NULL AND xe.SoKm IS NOT NULL AND xe.SoKm >= ln.SoKmDenHan))
            ORDER BY ln.MaLichNhac
            """, nativeQuery = true)
    List<Object[]> findDue(@Param("today") LocalDate today);

    // "Giành quyền" xử lý nguyên tử: chỉ một lượt xử lý đổi được CHO_NHAC -> DA_NHAC; lượt đến sau nhận 0 dòng.
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = "UPDATE LichNhacBaoDuong SET TrangThai = N'DA_NHAC', NgayNhac = SYSDATETIME() "
            + "WHERE MaLichNhac = :id AND TrangThai = N'CHO_NHAC'", nativeQuery = true)
    int claim(@Param("id") Integer id);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = "UPDATE LichNhacBaoDuong SET TrangThai = N'DA_HUY' "
            + "WHERE MaLichNhac = :id AND TrangThai = N'CHO_NHAC'", nativeQuery = true)
    int cancelPending(@Param("id") Integer id);

    // Chỉ ĐỌC bảng của module khác (Xe, DichVu); không tạo entity thứ hai cho chúng.
    @Query(value = "SELECT COUNT(1) FROM Xe WHERE MaXe = :vehicleId", nativeQuery = true)
    long countVehicle(@Param("vehicleId") Integer vehicleId);

    @Query(value = "SELECT LoaiDichVu FROM DichVu WHERE MaDichVu = :serviceId", nativeQuery = true)
    Optional<String> findServiceType(@Param("serviceId") Integer serviceId);
}
