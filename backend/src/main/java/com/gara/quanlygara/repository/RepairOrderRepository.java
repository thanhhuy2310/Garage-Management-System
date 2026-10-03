package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.RepairOrder;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public interface RepairOrderRepository extends JpaRepository<RepairOrder, Integer> {

    @Query(value = """
            SELECT p.MaPhieuSuaChua AS id, p.MaTiepNhan AS receptionId,
                   p.NgayLap AS createdAt, p.NgayBatDau AS startedAt,
                   p.NgayHoanThanh AS completedAt, p.TrangThai AS status, p.KetQua AS result,
                   x.BienSo AS licensePlate, x.HangXe AS brand, x.DongXe AS model,
                   k.HoTen AS customerName, t.YeuCauKhachHang AS customerRequest,
                   t.TinhTrangBanDau AS initialCondition
            FROM PhieuSuaChua p
            JOIN PhieuTiepNhan t ON t.MaTiepNhan = p.MaTiepNhan
            JOIN Xe x ON x.MaXe = t.MaXe
            JOIN KhachHang k ON k.MaKhachHang = x.MaKhachHang
            WHERE (:orderId = 0 OR p.MaPhieuSuaChua = :orderId)
              AND (:technicianId = 0 OR EXISTS (
                  SELECT 1 FROM PhanCongKyThuatVien a
                  WHERE a.MaPhieuSuaChua = p.MaPhieuSuaChua AND a.MaKyThuatVien = :technicianId))
            ORDER BY p.NgayLap DESC, p.MaPhieuSuaChua DESC
            """, nativeQuery = true)
    List<Overview> findOverviews(@Param("orderId") int orderId, @Param("technicianId") int technicianId);

    @Query(value = """
            SELECT d.MaDichVu AS id, d.TenDichVu AS name, c.SoLuong AS quantity,
                   c.DonGia AS unitPrice, c.TrangThai AS status
            FROM ChiTietDichVu c JOIN DichVu d ON d.MaDichVu = c.MaDichVu
            WHERE c.MaPhieuSuaChua = :orderId ORDER BY d.MaDichVu
            """, nativeQuery = true)
    List<ServiceLine> findServiceLines(@Param("orderId") int orderId);

    interface Overview {
        Integer getId();
        Integer getReceptionId();
        LocalDateTime getCreatedAt();
        LocalDateTime getStartedAt();
        LocalDateTime getCompletedAt();
        String getStatus();
        String getResult();
        String getLicensePlate();
        String getBrand();
        String getModel();
        String getCustomerName();
        String getCustomerRequest();
        String getInitialCondition();
    }

    interface ServiceLine {
        Integer getId();
        String getName();
        Integer getQuantity();
        BigDecimal getUnitPrice();
        String getStatus();
    }
}
