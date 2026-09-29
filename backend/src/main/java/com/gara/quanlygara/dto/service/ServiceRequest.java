package com.gara.quanlygara.dto.service;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

import java.math.BigDecimal;

public record ServiceRequest(
        @NotBlank(message = "Tên dịch vụ không được để trống.")
        @Size(max = 150, message = "Tên dịch vụ không được vượt quá 150 ký tự.")
        String name,

        @Size(max = 100, message = "Loại dịch vụ không được vượt quá 100 ký tự.")
        String type,

        @NotNull(message = "Đơn giá không được để trống.")
        @DecimalMin(value = "0", message = "Đơn giá không được âm.")
        @Digits(integer = 16, fraction = 2, message = "Đơn giá chỉ được có tối đa 16 chữ số nguyên và 2 chữ số thập phân.")
        BigDecimal unitPrice,

        @Size(max = 500, message = "Mô tả không được vượt quá 500 ký tự.")
        String description
) {
    public ServiceRequest {
        name = name == null ? null : name.strip();
        type = normalizeOptional(type);
        description = normalizeOptional(description);
    }

    private static String normalizeOptional(String value) {
        return value == null || value.isBlank() ? null : value.strip();
    }
}
