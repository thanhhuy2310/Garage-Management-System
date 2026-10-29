package com.gara.quanlygara.dto.appointment;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public final class AppointmentDtos {
    private AppointmentDtos() {}
    public record Create(@NotNull @Positive Integer vehicleId, @Positive Integer serviceId,
                         @NotNull LocalDate date, @NotNull LocalTime time, @Size(max=500) String note) {}
    public record Move(@NotNull LocalDate date, @NotNull LocalTime time,
                       @NotNull @PositiveOrZero Integer version, @Size(max=500) String reason) {}
    public record Change(@NotNull @PositiveOrZero Integer version, @Size(max=500) String reason) {}
    public record Schedule(@Min(1) @Max(7) int dayOfWeek, @NotNull LocalTime time,
                           @PositiveOrZero int capacity) {}
    public record Slot(LocalTime time, int capacity, int remaining) {}
    public record Availability(LocalDate date, boolean configured, List<Slot> slots) {}
    public record View(int id, int customerId, String customerName, int vehicleId, String plate,
                       String brand, String model, Integer year, Integer mileage, Integer serviceId,
                       String serviceName, String serviceType, BigDecimal unitPrice,
                       LocalDate date, LocalTime time, String note, String status, int version) {}
    public record Audit(long id, int accountId, String action, LocalDate date, LocalTime time,
                        String status, int version, String reason, java.time.LocalDateTime occurredAt) {}
}
