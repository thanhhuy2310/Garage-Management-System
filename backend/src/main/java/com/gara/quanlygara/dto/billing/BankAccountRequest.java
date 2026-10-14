package com.gara.quanlygara.dto.billing;
import jakarta.validation.constraints.*;

public record BankAccountRequest(@NotBlank @Size(max = 100) String name,
        @NotNull @Pattern(regexp = "[0-9]{6}") String bin,
        @NotNull @Pattern(regexp = "[0-9]{6,25}") String account,
        @NotBlank @Size(max = 100) String accountName,
        boolean active) {
    public BankAccountRequest {
        name = name == null ? null : name.trim();
        accountName = accountName == null ? null : accountName.trim();
    }
}
