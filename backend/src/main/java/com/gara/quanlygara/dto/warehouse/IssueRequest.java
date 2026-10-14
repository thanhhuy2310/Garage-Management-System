// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.Valid;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.util.List;

/** Cấp phát phụ tùng cho một phiếu sửa chữa. Tạo phiếu xuất KHÔNG giảm tồn. */
public record IssueRequest(
        @NotNull(message = "Vui lòng chọn phiếu sửa chữa.")
        @Positive(message = "Mã phiếu sửa chữa không hợp lệ.")
        Integer repairOrderId,

        @Positive(message = "Mã kỹ thuật viên không hợp lệ.")
        Integer requestedTechnicianId,

        @NotBlank(message = "Lý do không được để trống.")
        @Size(max = 500, message = "Lý do không được vượt quá 500 ký tự.")
        String reason,

        @NotEmpty(message = "Phiếu xuất phải có ít nhất một phụ tùng.")
        @Valid
        List<Item> items
) {
    public record Item(
            @NotNull(message = "Vui lòng chọn phụ tùng.")
            @Positive(message = "Mã phụ tùng không hợp lệ.")
            Integer partId,

            @NotNull(message = "Số lượng cấp phát không được để trống.")
            @Min(value = 1, message = "Số lượng cấp phát phải lớn hơn 0.")
            Integer quantity
    ) {
    }
}
