package com.gara.quanlygara.dto.insurance;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;
import java.math.BigDecimal;
import java.time.LocalDate;

public record InsurancePolicyRequest(
        @NotNull @Positive Integer companyId,
        @NotNull @Positive Integer vehicleId,
        @NotBlank @Size(max = 100) String policyNumber,
        @NotBlank @Pattern(regexp = "VAT_CHAT_XE|TNDS|KHAC") String insuranceType,
        @NotNull LocalDate startDate,
        @NotNull LocalDate endDate,
        @DecimalMin("0.00") @Digits(integer = 16, fraction = 2) BigDecimal insuredAmount,
        @DecimalMin("0.00") @Digits(integer = 16, fraction = 2) BigDecimal deductible,
        @Size(max = 500) String repairShopTerms,
        @Size(max = 1000) String partsTerms,
        @Size(max = 500) String certificateReference
) {}
