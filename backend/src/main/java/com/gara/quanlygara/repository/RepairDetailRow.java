// TV3-TUAN7
package com.gara.quanlygara.repository;

import java.math.BigDecimal;

/** Một dòng chi tiết (kèm tên dịch vụ/phụ tùng) đọc bằng truy vấn JOIN. */
public interface RepairDetailRow {
    Integer getItemId();

    String getItemName();

    Integer getQuantity();

    BigDecimal getUnitPrice();

    String getItemStatus();
}
