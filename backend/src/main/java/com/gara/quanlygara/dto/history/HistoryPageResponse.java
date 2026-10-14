// TV3-TUAN9
package com.gara.quanlygara.dto.history;

import java.util.List;

/** Một trang lịch sử; page bắt đầu từ 0 (giống Vehicle/SparePart). totalElements là tổng số lượt, không bị cắt. */
public record HistoryPageResponse(
        List<HistoryItemResponse> items,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
}
