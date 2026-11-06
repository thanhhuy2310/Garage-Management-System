// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.time.LocalDateTime;
import java.util.List;

public record IssueResponse(
        Integer id,
        Integer repairOrderId,
        Integer warehouseStaffId,
        Integer requestedTechnicianId,
        LocalDateTime issueDate,
        String reason,
        List<Item> items
) {
    /**
     * state là trạng thái thực dùng. issued cho biết kho đã xuất và trừ tồn;
     * returnConfirmed cho biết kho đã nhận phần dư. stockAfter lấy từ biến động xuất.
     */
    public record Item(
            Integer partId,
            String partName,
            Integer issuedQuantity,
            java.math.BigDecimal unitPrice,
            String state,
            LocalDateTime confirmedAt,
            Integer confirmedTechnicianId,
            Integer actualUsedQuantity,
            Integer returnedQuantity,
            Integer stockAfter,
            boolean issued,
            boolean returnConfirmed
    ) {
    }
}
