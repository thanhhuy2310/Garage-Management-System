// TV3-TUAN8
package com.gara.quanlygara.dto.warehouse;

import jakarta.validation.constraints.Size;

/** Lý do duyệt/từ chối. Từ chối bắt buộc có lý do (kiểm tra ở service). */
public record CheckDecisionRequest(
        @Size(max = 500, message = "Lý do không được vượt quá 500 ký tự.")
        String reason
) {
}
