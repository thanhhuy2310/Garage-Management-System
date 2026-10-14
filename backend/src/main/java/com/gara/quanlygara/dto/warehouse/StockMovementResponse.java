// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.time.LocalDateTime;

/** Đồng thời là đích của truy vấn JPQL constructor trong StockMovementRepository. */
public record StockMovementResponse(
        Long id,
        Integer partId,
        String partName,
        Integer receiptId,
        Integer issueId,
        LocalDateTime time,
        String type,
        Integer quantity,
        Integer quantityBefore,
        Integer quantityAfter,
        String note
) {
}
