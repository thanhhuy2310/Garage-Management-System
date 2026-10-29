package com.gara.quanlygara.dto.insurance;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

public record InsuranceClaimRequest(
        @NotNull @Positive Integer policyId,
        @NotNull @Positive Integer receptionId,
        @Size(max = 100) String insurerClaimNumber,
        @NotNull LocalDateTime incidentAt,
        @NotBlank @Size(max = 255) String incidentLocation,
        @NotBlank @Size(max = 1000) String causeDescription,
        @NotBlank @Size(max = 2000) String damageDescription,
        LocalDateTime notifiedAt,
        @Size(max = 150) String assessorName,
        @Size(max = 150) String assessorContact
) {}
