// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import java.util.List;

/** lowStockCount = số phụ tùng SAP_HET hoặc HET_HANG trên toàn danh mục (không phụ thuộc bộ lọc). */
public record InventoryPageResponse(
        List<InventoryItemResponse> items,
        int page,
        int size,
        long totalElements,
        int totalPages,
        long lowStockCount
) {
}
