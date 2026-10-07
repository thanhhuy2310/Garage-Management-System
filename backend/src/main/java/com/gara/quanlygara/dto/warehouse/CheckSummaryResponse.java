// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.time.LocalDateTime;

public record CheckSummaryResponse(
        Integer id,
        LocalDateTime checkDate,
        Integer createdBy,
        Integer approvedBy,
        String status,
        String note,
        int itemCount,
        int differenceCount
) {
}
