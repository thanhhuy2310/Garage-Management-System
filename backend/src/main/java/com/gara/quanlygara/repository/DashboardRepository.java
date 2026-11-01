package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.RepairOrder;
import org.springframework.data.repository.Repository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.LocalDateTime;
import java.util.List;

public interface DashboardRepository extends Repository<RepairOrder, Integer> {
    @Query(value="SELECT COUNT_BIG(*) FROM PhieuTiepNhan WHERE NgayTiepNhan >= :start AND NgayTiepNhan < :end", nativeQuery=true)
    long countReceptions(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    @Query(value="""
        SELECT CAST(NgayThanhToan AS DATE), SUM(SoTien)
        FROM ThanhToan WHERE NgayThanhToan >= :start AND NgayThanhToan < :end
        GROUP BY CAST(NgayThanhToan AS DATE)
        ORDER BY CAST(NgayThanhToan AS DATE)
        """, nativeQuery=true)
    List<Object[]> paymentsByDay(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);

    @Query(value="""
        SELECT TOP 6 d.MaDichVu, d.TenDichVu, COUNT_BIG(*)
        FROM ChiTietDichVu c JOIN DichVu d ON d.MaDichVu=c.MaDichVu
        JOIN PhieuSuaChua p ON p.MaPhieuSuaChua=c.MaPhieuSuaChua
        WHERE p.TrangThai=N'HOAN_TAT' AND p.NgayHoanThanh >= :start AND p.NgayHoanThanh < :end
        GROUP BY d.MaDichVu, d.TenDichVu ORDER BY COUNT_BIG(*) DESC, d.MaDichVu
        """, nativeQuery=true)
    List<Object[]> popularServices(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);
}
