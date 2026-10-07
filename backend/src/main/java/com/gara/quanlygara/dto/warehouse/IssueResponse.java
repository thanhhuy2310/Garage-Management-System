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
     * state: CHO_XAC_NHAN (đã cấp phát, chờ KTV xác nhận thực dùng, CHƯA trừ tồn) hoặc DA_XAC_NHAN.
     * stockAfter chỉ có khi đã xác nhận thực dùng > 0 (lấy từ biến động kho XUAT).
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
            Integer stockAfter
    ) {
    }
}
