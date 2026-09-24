package com.gara.quanlygara.dto.account;

import com.gara.quanlygara.entity.Employee;

public record EmployeeOptionResponse(
        Integer id,
        String fullName,
        String position,
        boolean technician,
        boolean hasAccount
) {
    public static EmployeeOptionResponse from(Employee employee, boolean technician, boolean hasAccount) {
        return new EmployeeOptionResponse(
                employee.getId(),
                employee.getFullName(),
                employee.getPosition(),
                technician,
                hasAccount
        );
    }
}
