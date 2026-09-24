package com.gara.quanlygara.dto.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank(message = "Họ tên không được để trống.")
        @Size(max = 100, message = "Họ tên không được vượt quá 100 ký tự.") String fullName,
        @NotBlank(message = "Số điện thoại không được để trống.")
        @Pattern(regexp = "^\\+?[0-9]{9,15}$", message = "Số điện thoại không hợp lệ.") String phone,
        @Email(message = "Email không hợp lệ.")
        @Size(max = 150, message = "Email không được vượt quá 150 ký tự.") String email,
        @Size(max = 255, message = "Địa chỉ không được vượt quá 255 ký tự.") String address,
        @NotBlank(message = "Tên đăng nhập không được để trống.")
        @Size(min = 4, max = 100, message = "Tên đăng nhập phải có từ 4 đến 100 ký tự.") String username,
        @NotBlank(message = "Mật khẩu không được để trống.")
        @Size(min = 8, max = 72, message = "Mật khẩu phải có từ 8 đến 72 ký tự.") String password
) {
}
