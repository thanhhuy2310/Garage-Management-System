// TV3-TUAN7
package com.gara.quanlygara.dto.sparepart;

import com.gara.quanlygara.entity.SparePart;

import java.math.BigDecimal;

public record SparePartResponse(
        Integer id,
        Integer warehouseId,
        String name,
        String manufacturer,
        BigDecimal unitPrice,
        Integer stockQuantity,
        Integer minStockLevel
) {
    public static SparePartResponse from(SparePart part) {
        return new SparePartResponse(
                part.getId(),
                part.getWarehouseId(),
                part.getName(),
                part.getManufacturer(),
                part.getUnitPrice(),
                // Phụ tùng vừa tạo chưa được nạp lại từ CSDL: tồn mặc định của bảng là 0.
                part.getStockQuantity() == null ? 0 : part.getStockQuantity(),
                part.getMinStockLevel()
        );
    }
}
