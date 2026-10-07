// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

/**
 * KTV xác nhận số lượng phụ tùng thực dùng (0 <= actualUsed <= số cấp phát).
 * technicianId: bắt buộc khi người gọi là ADMIN/MANAGER; tài khoản TECHNICIAN luôn là chính họ.
 */
public record ConfirmUsageRequest(
        @NotNull(message = "Số lượng thực dùng không được để trống.")
        @Min(value = 0, message = "Số lượng thực dùng không được âm.")
        Integer actualUsed,

        @Positive(message = "Mã kỹ thuật viên không hợp lệ.")
        Integer technicianId
) {
}
