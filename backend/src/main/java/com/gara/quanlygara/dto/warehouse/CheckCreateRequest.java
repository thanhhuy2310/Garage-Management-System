// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.util.List;

/** Tạo phiên kiểm kê cho các phụ tùng được chọn; hệ thống chụp (snapshot) tồn hiện tại. */
public record CheckCreateRequest(
        @Size(max = 500, message = "Ghi chú không được vượt quá 500 ký tự.")
        String note,

        @NotEmpty(message = "Vui lòng chọn ít nhất một phụ tùng để kiểm kê.")
        @Size(max = 200, message = "Một phiên kiểm kê tối đa 200 phụ tùng.")
        List<@NotNull(message = "Mã phụ tùng không hợp lệ.") @Positive(message = "Mã phụ tùng không hợp lệ.") Integer> partIds
) {
}
