package com.gara.quanlygara.dto.insurance;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record InsuranceCompanyRequest(
        @NotBlank @Size(max = 30) String code,
        @NotBlank @Size(max = 200) String name,
        @Size(max = 30) String phone,
        @Email @Size(max = 150) String email,
        @Size(max = 255) String address,
        @Size(max = 150) String assessorName,
        @Size(max = 150) String assessorContact,
        @NotNull Boolean active
) {}
