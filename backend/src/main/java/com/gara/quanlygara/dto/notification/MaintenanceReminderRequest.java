// TV3-TUAN10
package com.gara.quanlygara.dto.notification;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

import java.time.LocalDate;

/** Phải có dueDate hoặc dueKm (hoặc cả hai); không có chu kỳ mặc định nào được tự suy ra. */
public record MaintenanceReminderRequest(
        @NotNull(message = "Vui lòng chọn xe.")
        @Positive(message = "Mã xe không hợp lệ.")
        Integer vehicleId,

        @Positive(message = "Mã dịch vụ không hợp lệ.")
        Integer serviceId,

        LocalDate dueDate,

        @Min(value = 0, message = "Số km đến hạn không được âm.")
        Integer dueKm,

        @Size(max = 500, message = "Ghi chú không được vượt quá 500 ký tự.")
        String note
) {
}
