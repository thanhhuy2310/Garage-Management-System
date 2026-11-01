package com.gara.quanlygara.dto.employee;

public record EmployeeResponse(Integer id, String fullName, String phone, String email,
                               String position, boolean technician, String username,
                               String accountRole, Boolean accountActive) {
}
