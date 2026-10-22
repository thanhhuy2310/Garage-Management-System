// TV3-TUAN10
package com.gara.quanlygara.dto.notification;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.gara.quanlygara.entity.CustomerNotification;

import java.time.LocalDateTime;

public record NotificationResponse(
        Long id,
        String title,
        String message,
        LocalDateTime createdAt,
        String type,
        @JsonProperty("isRead") boolean read,
        Integer appointmentId,
        Integer repairOrderId,
        Integer maintenanceScheduleId
) {
    public static NotificationResponse from(CustomerNotification notification) {
        return new NotificationResponse(
                notification.getId(),
                notification.getTitle(),
                notification.getMessage(),
                notification.getCreatedAt(),
                NotificationType.fromCode(notification.getTypeCode()).apiValue(),
                notification.isRead(),
                notification.getAppointmentId(),
                notification.getRepairOrderId(),
                notification.getMaintenanceReminderId());
    }
}
