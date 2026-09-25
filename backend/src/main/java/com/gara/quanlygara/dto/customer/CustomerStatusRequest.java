package com.gara.quanlygara.dto.customer;

import jakarta.validation.constraints.NotNull;

public record CustomerStatusRequest(
        @NotNull(message = "Trạng thái không được để trống.") Boolean active
) {
}
