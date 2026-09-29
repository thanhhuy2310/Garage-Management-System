package com.gara.quanlygara.dto.technician;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record TechnicianAssignmentRequest(
        @NotNull(message = "Vui lòng chọn kỹ thuật viên.")
        @Positive(message = "Mã kỹ thuật viên phải lớn hơn 0.")
        Integer technicianId,

        @Size(max = 500, message = "Ghi chú không được vượt quá 500 ký tự.")
        String notes
) {
    public TechnicianAssignmentRequest {
        notes = notes == null || notes.isBlank() ? null : notes.strip();
    }
}
