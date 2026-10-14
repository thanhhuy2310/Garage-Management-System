// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

/** Suy ra từ tồn và mức tối thiểu (cùng quy tắc dbo.fn_TrangThaiTonKho), không lưu trong CSDL. */
public enum StockStatus {
    CON_HANG,
    SAP_HET,
    HET_HANG;

    public static StockStatus of(int stockQuantity, int minStockLevel) {
        if (stockQuantity == 0) return HET_HANG;
        if (stockQuantity <= minStockLevel) return SAP_HET;
        return CON_HANG;
    }
}
