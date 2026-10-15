// TV3-TUAN9
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Vehicle;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.Repository;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

/**
 * Truy vấn CHỈ ĐỌC để tổng hợp lịch sử sửa chữa của khách hàng từ dữ liệu nghiệp vụ gốc.
 * Gắn với entity Vehicle có sẵn (không tạo entity/bảng mới cho PhieuSuaChua, PhieuTiepNhan của module khác);
 * kết quả là Object[] và được chuyển kiểu tường minh trong RepairHistoryService.
 */
public interface RepairHistoryRepository extends Repository<Vehicle, Integer> {

    /**
     * Cột: 0 MaPhieuSuaChua, 1 MaXe, 2 BienSo, 3 HangXe, 4 DongXe, 5 NgayLap, 6 NgayBatDau, 7 NgayHoanThanh,
     * 8 KetQua, 9 tổng chi phí (dbo.fn_TinhTongChiPhiSuaChua). Mới nhất trước, tối đa 200 lượt.
     * vehicleId = 0 và repairOrderId = 0 nghĩa là không lọc. Chỉ lấy xe của đúng khách hàng và phiếu HOAN_TAT.
     */
    @Query(value = """
            SELECT TOP (200)
                   ps.MaPhieuSuaChua, xe.MaXe, xe.BienSo, xe.HangXe, xe.DongXe,
                   ps.NgayLap, ps.NgayBatDau, ps.NgayHoanThanh, ps.KetQua,
                   dbo.fn_TinhTongChiPhiSuaChua(ps.MaPhieuSuaChua)
            FROM PhieuSuaChua ps
            JOIN PhieuTiepNhan tn ON tn.MaTiepNhan = ps.MaTiepNhan
            JOIN Xe xe ON xe.MaXe = tn.MaXe
            WHERE xe.MaKhachHang = :customerId
              AND ps.TrangThai = N'HOAN_TAT'
              AND (:vehicleId = 0 OR xe.MaXe = :vehicleId)
              AND (:repairOrderId = 0 OR ps.MaPhieuSuaChua = :repairOrderId)
            ORDER BY COALESCE(ps.NgayHoanThanh, ps.NgayBatDau, ps.NgayLap) DESC, ps.MaPhieuSuaChua DESC
            """, nativeQuery = true)
    List<Object[]> findHistoryRows(
            @Param("customerId") Integer customerId,
            @Param("vehicleId") Integer vehicleId,
            @Param("repairOrderId") Integer repairOrderId);

    /** Cột: 0 MaPhieuSuaChua, 1 MaDichVu, 2 TenDichVu, 3 LoaiDichVu, 4 SoLuong, 5 DonGia. */
    @Query(value = """
            SELECT cd.MaPhieuSuaChua, cd.MaDichVu, dv.TenDichVu, dv.LoaiDichVu, cd.SoLuong, cd.DonGia
            FROM ChiTietDichVu cd
            JOIN DichVu dv ON dv.MaDichVu = cd.MaDichVu
            WHERE cd.MaPhieuSuaChua IN (:orderIds)
            ORDER BY cd.MaPhieuSuaChua, cd.MaDichVu
            """, nativeQuery = true)
    List<Object[]> findServiceLines(@Param("orderIds") Collection<Integer> orderIds);

    /** Cột: 0 MaPhieuSuaChua, 1 MaPhuTung, 2 TenPhuTung, 3 SoLuong, 4 DonGia. */
    @Query(value = """
            SELECT cp.MaPhieuSuaChua, cp.MaPhuTung, pt.TenPhuTung, cp.SoLuong, cp.DonGia
            FROM ChiTietPhuTung cp
            JOIN PhuTung pt ON pt.MaPhuTung = cp.MaPhuTung
            WHERE cp.MaPhieuSuaChua IN (:orderIds)
            ORDER BY cp.MaPhieuSuaChua, cp.MaPhuTung
            """, nativeQuery = true)
    List<Object[]> findPartLines(@Param("orderIds") Collection<Integer> orderIds);

    @Query(value = "SELECT COUNT(1) FROM Xe WHERE MaXe = :vehicleId AND MaKhachHang = :customerId", nativeQuery = true)
    long countOwnedVehicle(@Param("vehicleId") Integer vehicleId, @Param("customerId") Integer customerId);
}
