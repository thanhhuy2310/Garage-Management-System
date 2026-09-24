package com.gara.quanlygara.dto.customer;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record CustomerRequest(
        @NotBlank(message = "Họ tên không được để trống.")
        @Size(max = 100, message = "Họ tên không được vượt quá 100 ký tự.")
        String fullName,

        @NotBlank(message = "Số điện thoại không được để trống.")
        @Pattern(regexp = "^[0-9+ .()\\-]{8,20}$", message = "Số điện thoại không đúng định dạng.")
        String phone,

        @Email(message = "Email không đúng định dạng.")
        @Size(max = 150, message = "Email không được vượt quá 150 ký tự.")
        String email,

        @Size(max = 255, message = "Địa chỉ không được vượt quá 255 ký tự.")
        String address
) {
}
