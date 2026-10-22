// TV3-TUAN10
package com.gara.quanlygara.dto.notification;

import com.gara.quanlygara.entity.MaintenanceReminder;

import java.time.LocalDate;
import java.time.LocalDateTime;

public record MaintenanceReminderResponse(
        Integer id,
        Integer vehicleId,
        Integer serviceId,
        LocalDate dueDate,
        Integer dueKm,
        String note,
        String status,
        LocalDateTime createdAt,
        LocalDateTime remindedAt
) {
    public static MaintenanceReminderResponse from(MaintenanceReminder reminder) {
        return new MaintenanceReminderResponse(
                reminder.getId(), reminder.getVehicleId(), reminder.getServiceId(), reminder.getDueDate(),
                reminder.getDueKm(), reminder.getNote(), reminder.getStatus(), reminder.getCreatedAt(),
                reminder.getRemindedAt());
    }
}
