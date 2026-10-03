// TV3-TUAN7
package com.gara.quanlygara.dto.repairdetail;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

import java.math.BigDecimal;

/** unitPrice bỏ trống = giữ nguyên đơn giá đang lưu trên dòng. */
public record RepairDetailUpdateRequest(
        @NotNull(message = "Số lượng không được để trống.")
        @Min(value = 1, message = "Số lượng phải lớn hơn 0.")
        Integer quantity,

        @DecimalMin(value = "0", message = "Đơn giá không được âm.")
        @Digits(integer = 16, fraction = 2, message = "Đơn giá tối đa 2 chữ số thập phân.")
        BigDecimal unitPrice
) {
}
