// TV3-TUAN7
package com.gara.quanlygara.dto.repairdetail;

import java.math.BigDecimal;
import java.util.List;

public record RepairDetailsResponse(
        Integer repairOrderId,
        String repairOrderStatus,
        boolean editable,
        List<RepairDetailResponse> items,
        BigDecimal serviceTotal,
        BigDecimal partsTotal,
        BigDecimal totalAmount
) {
}
