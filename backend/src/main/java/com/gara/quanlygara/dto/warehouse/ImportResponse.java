// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record ImportResponse(
        Integer id,
        LocalDateTime importDate,
        String supplier,
        Integer warehouseStaffId,
        String note,
        List<Item> items,
        BigDecimal totalAmount
) {
    public record Item(Integer partId, String partName, Integer quantity, BigDecimal unitPrice, BigDecimal lineTotal) {
    }
}
