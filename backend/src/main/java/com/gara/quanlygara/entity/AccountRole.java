package com.gara.quanlygara.entity;

import com.gara.quanlygara.exception.BadRequestException;

import java.util.Locale;

public enum AccountRole {
    CUSTOMER,
    RECEPTIONIST,
    TECHNICIAN,
    WAREHOUSE,
    MANAGER,
    ADMIN;

    public static AccountRole from(String value) {
        if (value == null || value.isBlank()) {
            throw new BadRequestException("Vai trò không được để trống.");
        }

        try {
            return AccountRole.valueOf(value.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException exception) {
            throw new BadRequestException("Vai trò không hợp lệ.");
        }
    }
}
