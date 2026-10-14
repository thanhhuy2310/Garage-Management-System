package com.gara.quanlygara.dto.billing;

import jakarta.validation.constraints.*;
import java.math.BigDecimal;

public final class BillingRequests {
    private BillingRequests() { }
    public record CreateInvoice(@NotNull @Positive Integer repairOrderId) { }
    public record RecordPayment(
            @NotNull @DecimalMin(value = "0", inclusive = false) @Digits(integer = 16, fraction = 2) BigDecimal amount,
            @NotNull @Pattern(regexp = "TIEN_MAT|CHUYEN_KHOAN") String method,
            @NotNull @Pattern(regexp = "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}") String requestId,
            @Positive Integer bankAccountId
    ) { }
}
