package com.gara.quanlygara.dto.catalog;

import com.gara.quanlygara.dto.sparepart.SparePartResponse;
import java.math.BigDecimal;

public record PublicPartResponse(Integer id, String name, String manufacturer, BigDecimal unitPrice,
                                 int stockQuantity, int minStockLevel) {
    public static PublicPartResponse from(SparePartResponse part) {
        return new PublicPartResponse(part.id(),part.name(),part.manufacturer(),part.unitPrice(),
                part.stockQuantity(),part.minStockLevel());
    }
}
