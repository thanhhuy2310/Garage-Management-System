package com.gara.quanlygara.dto.account;

import jakarta.validation.constraints.NotNull;

public record AccountStatusRequest(
        @NotNull(message = "Trạng thái không được để trống.") Boolean active
) {
}
