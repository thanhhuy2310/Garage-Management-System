package com.gara.quanlygara.security;

import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

class JwtServiceTest {

    @Test
    void generatedTokenContainsUsernameAndCanBeValidated() {
        JwtService jwtService = new JwtService("a-test-secret-that-is-at-least-32-characters", 60_000);
        Account account = new Account();
        account.setId(1);
        account.setUsername("admin");
        account.setRole(AccountRole.ADMIN);

        String token = jwtService.generateToken(account);

        assertEquals("admin", jwtService.extractUsername(token));
        assertTrue(jwtService.isValid(token, "admin"));
    }
}
