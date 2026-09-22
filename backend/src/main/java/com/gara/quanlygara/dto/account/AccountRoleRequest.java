package com.gara.quanlygara.dto.account;

import jakarta.validation.constraints.NotBlank;

public record AccountRoleRequest(
        @NotBlank(message = "Vai trò không được để trống.") String role
) {
}
