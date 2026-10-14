// TV3-TUAN9
package com.gara.quanlygara.dto.history;

/** Xe của khách hàng có ít nhất một lượt sửa chữa/bảo dưỡng đã hoàn tất (dùng làm bộ lọc ở mobile). */
public record HistoryVehicleResponse(
        Integer vehicleId,
        String licensePlate,
        String brand,
        String model,
        int completedCount
) {
}
