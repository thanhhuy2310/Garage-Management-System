package com.gara.quanlygara.dto.reception;
import java.time.LocalDateTime;
public record ReceptionResponse(int id, int vehicleId, int customerId, String customerName,
    String licensePlate, Integer appointmentId, Integer mileage, String initialCondition,
    String customerRequest, String notes, LocalDateTime receivedAt, LocalDateTime updatedAt,
    Integer receivedBy, int version, Integer repairOrderId, String repairStatus) {}
