package com.gara.quanlygara.dto.quotation;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public final class QuotationDtos {
    private QuotationDtos() {}
    public enum Kind { SERVICE, PART }
    public record LineInput(@NotNull Kind kind, @Positive int itemId,
        @Min(1) @Max(100000) int quantity,
        @DecimalMin("0.00") @Digits(integer=12,fraction=2) BigDecimal unitPrice) {}
    public record Create(@Positive int repairOrderId, @NotEmpty @Size(max=100) List<@Valid LineInput> lines) {}
    public record Edit(@Min(0) int version, @NotEmpty @Size(max=100) List<@Valid LineInput> lines) {}
    public record Change(@Min(0) int version, @Size(max=500) String reason) {}
    public record Decision(@Min(0) int version, @NotNull Boolean accepted, @Size(max=500) String reason) {}
    public record Line(int id, Kind kind, int itemId, String name, int quantity,
        BigDecimal unitPrice, BigDecimal amount) {}
    public record View(int id, int repairOrderId, int customerId, String customerName,
        int vehicleId, String plate, String brand, String model, Integer year, Integer mileage,
        int version, int revision, String status, LocalDateTime createdAt,
        LocalDateTime sentAt, LocalDateTime decidedAt, Integer createdBy, Integer decidedBy,
        String rejectionReason, BigDecimal total, List<Line> lines) {}
    public record Audit(long id, String action, Integer accountId, LocalDateTime at, String reason, View snapshot) {}
}
