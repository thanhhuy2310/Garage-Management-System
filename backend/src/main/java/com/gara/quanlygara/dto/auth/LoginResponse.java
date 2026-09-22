package com.gara.quanlygara.dto.auth;

import com.gara.quanlygara.dto.account.AccountResponse;

public record LoginResponse(
        String accessToken,
        String tokenType,
        long expiresIn,
        AccountResponse account
) {
}
