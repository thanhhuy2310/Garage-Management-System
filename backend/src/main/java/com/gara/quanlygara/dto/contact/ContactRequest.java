package com.gara.quanlygara.dto.contact;

import jakarta.validation.constraints.*;
import java.util.UUID;

public record ContactRequest(@NotNull UUID requestId,
                             @NotBlank @Size(max=100) String fullName,
                             @NotBlank @Size(max=20) @Pattern(regexp="[+0-9][0-9 .-]{7,19}") String phone,
                             @Size(max=20) String plate,
                             @NotBlank @Size(max=2000) String message) {
    public ContactRequest {
        fullName=fullName==null?null:fullName.strip();
        phone=phone==null?null:phone.strip();
        plate=plate==null||plate.isBlank()?null:plate.strip();
        message=message==null?null:message.strip();
    }
}
