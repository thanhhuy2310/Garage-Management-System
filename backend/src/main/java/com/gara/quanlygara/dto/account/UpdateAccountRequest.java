package com.gara.quanlygara.dto.account;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record UpdateAccountRequest(
        @NotBlank(message = "Tên đăng nhập không được để trống.")
        @Size(max = 100, message = "Tên đăng nhập không được vượt quá 100 ký tự.") String username,
        @Size(min = 8, max = 72, message = "Mật khẩu phải có từ 8 đến 72 ký tự.") String password,
        @NotBlank(message = "Vai trò không được để trống.") String role,
        Boolean active,
        Integer customerId,
        Integer employeeId
) {
}
