package com.gara.quanlygara.dto.technician;

import java.time.LocalDateTime;

public record TechnicianRepairOrderResponse(
        Integer repairOrderId,
        Integer receptionId,
        LocalDateTime createdAt,
        LocalDateTime startedAt,
        LocalDateTime completedAt,
        String status,
        String result,
        LocalDateTime assignedAt,
        String notes
) {
}
