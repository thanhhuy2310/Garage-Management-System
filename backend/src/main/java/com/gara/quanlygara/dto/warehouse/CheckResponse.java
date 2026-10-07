// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.time.LocalDateTime;
import java.util.List;

public record CheckResponse(
        Integer id,
        LocalDateTime checkDate,
        Integer createdBy,
        Integer approvedBy,
        LocalDateTime approvedAt,
        String status,
        String note,
        String decisionReason,
        List<Item> items
) {
    public record Item(
            Integer partId,
            String partName,
            Integer systemQuantity,
            Integer actualQuantity,
            Integer difference,
            String reason,
            boolean adjustmentApproved
    ) {
    }
}
