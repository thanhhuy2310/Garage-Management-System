// TV3-TUAN7
package com.gara.quanlygara.dto.repairdetail;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

import java.math.BigDecimal;

/** unitPrice bỏ trống = lấy đơn giá hiện tại của danh mục (DichVu/PhuTung). */
public record RepairDetailCreateRequest(
        @NotNull(message = "Vui lòng chọn loại hạng mục.")
        RepairDetailType type,

        @NotNull(message = "Vui lòng chọn dịch vụ hoặc phụ tùng.")
        @Positive(message = "Mã dịch vụ/phụ tùng không hợp lệ.")
        Integer itemId,

        @NotNull(message = "Số lượng không được để trống.")
        @Min(value = 1, message = "Số lượng phải lớn hơn 0.")
        Integer quantity,

        @DecimalMin(value = "0", message = "Đơn giá không được âm.")
        @Digits(integer = 16, fraction = 2, message = "Đơn giá tối đa 2 chữ số thập phân.")
        BigDecimal unitPrice
) {
}
