package com.gara.quanlygara.dto.vehicle;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record VehicleRequest(
        @NotNull(message = "Vui lòng chọn chủ xe.")
        @Positive(message = "Mã khách hàng không hợp lệ.")
        Integer customerId,

        @NotBlank(message = "Biển số không được để trống.")
        @Size(max = 20, message = "Biển số không được vượt quá 20 ký tự.")
        String licensePlate,

        @Size(max = 100, message = "Hãng xe không được vượt quá 100 ký tự.")
        String brand,

        @Size(max = 100, message = "Dòng xe không được vượt quá 100 ký tự.")
        String model,

        @Min(value = 1886, message = "Năm sản xuất không hợp lệ.")
        @Max(value = 2100, message = "Năm sản xuất không hợp lệ.")
        Short year,

        @Min(value = 0, message = "Số km không được âm.")
        Integer mileage
) {
}
