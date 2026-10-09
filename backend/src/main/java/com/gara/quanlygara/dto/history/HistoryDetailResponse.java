// TV3-TUAN9
package com.gara.quanlygara.dto.history;

import java.math.BigDecimal;
import java.util.List;

public record HistoryDetailResponse(
        HistoryItemResponse item,
        List<ServiceLine> services,
        List<PartLine> parts,
        BigDecimal serviceTotal,
        BigDecimal partsTotal
) {
    public record ServiceLine(
            Integer serviceId, String name, String type, Integer quantity, BigDecimal unitPrice, BigDecimal lineTotal) {
    }

    public record PartLine(
            Integer partId, String name, Integer quantity, BigDecimal unitPrice, BigDecimal lineTotal) {
    }
}
