// TV3-TUAN7
package com.gara.quanlygara.dto.sparepart;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

/** Không có số lượng tồn: tồn kho chỉ thay đổi bằng nghiệp vụ nhập/xuất kho (Tuần 8). */
public record SparePartRequest(
        @NotNull(message = "Vui lòng chọn kho.")
        @Positive(message = "Mã kho không hợp lệ.")
        Integer warehouseId,

        @NotBlank(message = "Tên phụ tùng không được để trống.")
        @Size(max = 150, message = "Tên phụ tùng không được vượt quá 150 ký tự.")
        String name,

        @Size(max = 150, message = "Hãng sản xuất không được vượt quá 150 ký tự.")
        String manufacturer,

        @NotNull(message = "Đơn giá không được để trống.")
        @DecimalMin(value = "0", message = "Đơn giá không được âm.")
        @Digits(integer = 16, fraction = 2, message = "Đơn giá tối đa 2 chữ số thập phân.")
        BigDecimal unitPrice,

        @Min(value = 0, message = "Mức tồn tối thiểu không được âm.")
        Integer minStockLevel
) {
}
