// TV3-TUAN7
package com.gara.quanlygara.dto.repairdetail;

import java.math.BigDecimal;

public record RepairDetailResponse(
        RepairDetailType type,
        Integer itemId,
        String itemName,
        Integer quantity,
        BigDecimal unitPrice,
        BigDecimal lineTotal,
        String status
) {
}
