// TV3-TUAN9
package com.gara.quanlygara.dto.history;

import java.math.BigDecimal;
import java.time.LocalDateTime;

/**
 * Một lượt sửa chữa/bảo dưỡng đã hoàn tất của khách hàng, tổng hợp từ PhieuSuaChua + PhieuTiepNhan + Xe
 * + ChiTietDichVu + ChiTietPhuTung (không có bảng lịch sử riêng).
 * category: BAO_DUONG | SUA_CHUA | BAO_DUONG_SUA_CHUA (suy ra từ DichVu.LoaiDichVu).
 */
public record HistoryItemResponse(
        Integer repairOrderId,
        Integer vehicleId,
        String licensePlate,
        String brand,
        String model,
        LocalDateTime createdAt,
        LocalDateTime startedAt,
        LocalDateTime completedAt,
        String category,
        String summary,
        int serviceCount,
        int partCount,
        BigDecimal totalCost,
        String result
) {
}
