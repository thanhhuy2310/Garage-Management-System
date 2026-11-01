package com.gara.quanlygara.dto.employee;

import jakarta.validation.constraints.*;

public record EmployeeRequest(
        @NotBlank @Size(max = 100) String fullName,
        @Size(max = 20) String phone,
        @Email @Size(max = 150) String email,
        @NotBlank @Size(max = 100) String position,
        @NotNull Boolean technician) {
}
