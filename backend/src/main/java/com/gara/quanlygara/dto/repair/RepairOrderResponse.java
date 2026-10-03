package com.gara.quanlygara.dto.repair;

import java.time.LocalDateTime;

public record RepairOrderResponse(
        Integer id,
        Integer receptionId,
        LocalDateTime createdAt,
        LocalDateTime startedAt,
        LocalDateTime completedAt,
        String status,
        String result,
        String licensePlate,
        String brand,
        String model,
        String customerName,
        String customerRequest,
        String initialCondition
) {
}
