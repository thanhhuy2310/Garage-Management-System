package com.gara.quanlygara.dto.reception;
import jakarta.validation.constraints.*;
public record ReceptionRequest(
    @Positive int customerId, @Positive int vehicleId, @Positive Integer appointmentId,
    @Min(0) Integer mileage, @NotBlank @Size(max=1000) String initialCondition,
    @NotBlank @Size(max=1000) String customerRequest, @Size(max=1000) String notes) {}
