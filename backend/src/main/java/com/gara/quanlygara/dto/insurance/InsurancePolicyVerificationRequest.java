package com.gara.quanlygara.dto.insurance;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record InsurancePolicyVerificationRequest(
        @NotBlank @Pattern(regexp = "DA_XAC_MINH|KHONG_HOP_LE") String status,
        @NotBlank @Size(max = 1000) String note,
        @Size(max=200) String registeredOwnerName,
        @Size(max=200) String certificateOwnerName
) {
    public InsurancePolicyVerificationRequest(String status,String note) { this(status,note,null,null); }
}
