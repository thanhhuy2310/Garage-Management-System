// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import com.gara.quanlygara.entity.SparePart;

import java.math.BigDecimal;

public record InventoryItemResponse(
        Integer id,
        Integer warehouseId,
        String name,
        String manufacturer,
        BigDecimal unitPrice,
        Integer stockQuantity,
        Integer minStockLevel,
        StockStatus stockStatus
) {
    public static InventoryItemResponse from(SparePart part) {
        int stock = part.getStockQuantity() == null ? 0 : part.getStockQuantity();
        return new InventoryItemResponse(
                part.getId(), part.getWarehouseId(), part.getName(), part.getManufacturer(),
                part.getUnitPrice(), stock, part.getMinStockLevel(),
                StockStatus.of(stock, part.getMinStockLevel()));
    }
}
