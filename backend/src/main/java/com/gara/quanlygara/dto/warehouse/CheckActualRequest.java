// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record CheckActualRequest(
        @NotNull(message = "Số lượng thực tế không được để trống.")
        @Min(value = 0, message = "Số lượng thực tế không được âm.")
        Integer actualQuantity,

        @Size(max = 500, message = "Nguyên nhân không được vượt quá 500 ký tự.")
        String reason
) {
}
