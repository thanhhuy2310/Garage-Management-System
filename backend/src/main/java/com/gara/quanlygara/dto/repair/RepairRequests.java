package com.gara.quanlygara.dto.repair;

import jakarta.validation.Valid;
import jakarta.validation.constraints.*;
import java.util.List;

public final class RepairRequests {
    private RepairRequests() { }

    public record ServiceLine(@NotNull @Positive Integer serviceId,
                              @NotNull @Min(1) @Max(1000) Integer quantity) { }

    public record Create(@NotNull @Positive Integer receptionId,
                         @NotEmpty @Size(max = 100) List<@Valid ServiceLine> services) { }

    public record Progress(@NotBlank @Size(max = 50) String status,
                           @NotBlank @Size(max = 50) String expectedStatus,
                           @NotBlank @Size(max = 1000) String notes) {
        public Progress {
            status = status == null ? null : status.trim();
            expectedStatus = expectedStatus == null ? null : expectedStatus.trim();
            notes = notes == null ? null : notes.trim();
        }
    }
}
