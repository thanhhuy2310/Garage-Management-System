package com.gara.quanlygara.repository;
import com.gara.quanlygara.entity.InsuranceReception;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import jakarta.persistence.LockModeType;
import java.time.LocalDateTime;
import java.util.*;

public interface ReceptionRepository extends JpaRepository<InsuranceReception,Integer> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select r from InsuranceReception r where r.id=:id")
    Optional<InsuranceReception> findForUpdate(@Param("id") int id);
    boolean existsByAppointmentId(Integer appointmentId);
    @Query(value="""
        SELECT COUNT(*) FROM PhieuTiepNhan t
        LEFT JOIN PhieuSuaChua p ON p.MaTiepNhan=t.MaTiepNhan
        WHERE t.MaXe=:vehicleId AND (p.MaPhieuSuaChua IS NULL OR p.TrangThai NOT IN (N'HOAN_TAT',N'HUY',N'DA_HUY'))
        """,nativeQuery=true)
    int countOpenForVehicle(@Param("vehicleId") int vehicleId);
    @Query(value="""
        SELECT t.MaTiepNhan id,t.MaXe vehicleId,x.MaKhachHang customerId,k.HoTen customerName,
            x.BienSo licensePlate,t.MaLichHen appointmentId,t.SoKmTiepNhan mileage,
            t.TinhTrangBanDau initialCondition,t.YeuCauKhachHang customerRequest,t.GhiChu notes,
            t.NgayTiepNhan receivedAt,t.NgayCapNhat updatedAt,t.MaNhanVienTiepNhan receivedBy,
            t.PhienBan version,p.MaPhieuSuaChua repairOrderId,p.TrangThai repairStatus
        FROM PhieuTiepNhan t JOIN Xe x ON x.MaXe=t.MaXe JOIN KhachHang k ON k.MaKhachHang=x.MaKhachHang
        LEFT JOIN PhieuSuaChua p ON p.MaTiepNhan=t.MaTiepNhan
        WHERE (:id=0 OR t.MaTiepNhan=:id) ORDER BY t.MaTiepNhan DESC
        """,nativeQuery=true)
    List<Overview> overview(@Param("id") int id);
    interface Overview {
        int getId(); int getVehicleId(); int getCustomerId(); String getCustomerName(); String getLicensePlate();
        Integer getAppointmentId(); Integer getMileage(); String getInitialCondition(); String getCustomerRequest();
        String getNotes(); LocalDateTime getReceivedAt(); LocalDateTime getUpdatedAt(); Integer getReceivedBy();
        int getVersion(); Integer getRepairOrderId(); String getRepairStatus();
    }
}
