// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.Valid;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

/** Tạo phiếu nhập kèm chi tiết trong một transaction. importDate bỏ trống = thời điểm hiện tại. */
public record ImportRequest(
        @NotBlank(message = "Nhà cung cấp không được để trống.")
        @Size(max = 200, message = "Nhà cung cấp không được vượt quá 200 ký tự.")
        String supplier,

        LocalDateTime importDate,

        @Size(max = 500, message = "Ghi chú không được vượt quá 500 ký tự.")
        String note,

        @NotEmpty(message = "Phiếu nhập phải có ít nhất một phụ tùng.")
        @Valid
        List<Item> items
) {
    public record Item(
            @NotNull(message = "Vui lòng chọn phụ tùng.")
            @Positive(message = "Mã phụ tùng không hợp lệ.")
            Integer partId,

            @NotNull(message = "Số lượng không được để trống.")
            @Min(value = 1, message = "Số lượng nhập phải lớn hơn 0.")
            Integer quantity,

            @NotNull(message = "Đơn giá nhập không được để trống.")
            @DecimalMin(value = "0", message = "Đơn giá nhập không được âm.")
            @Digits(integer = 16, fraction = 2, message = "Đơn giá tối đa 2 chữ số thập phân.")
            BigDecimal unitPrice
    ) {
    }
}
