package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.auth.ChangePasswordRequest;
import com.gara.quanlygara.dto.auth.LoginRequest;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.exception.ForbiddenException;
import com.gara.quanlygara.exception.UnauthorizedException;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(accountRepository, passwordEncoder, jwtService);
    }

    @Test
    void loginReturnsTokenWhenPasswordIsCorrect() {
        Account account = account(true);
        when(accountRepository.findByUsername("admin")).thenReturn(Optional.of(account));
        when(passwordEncoder.matches("correct-password", account.getPasswordHash())).thenReturn(true);
        when(jwtService.generateToken(account)).thenReturn("jwt-token");
        when(jwtService.getExpirationSeconds()).thenReturn(3600L);

        var response = authService.login(new LoginRequest("admin", "correct-password"));

        assertEquals("jwt-token", response.accessToken());
        assertEquals("ADMIN", response.account().role());
    }

    @Test
    void loginRejectsWrongPassword() {
        Account account = account(true);
        when(accountRepository.findByUsername("admin")).thenReturn(Optional.of(account));
        when(passwordEncoder.matches("wrong-password", account.getPasswordHash())).thenReturn(false);

        assertThrows(UnauthorizedException.class,
                () -> authService.login(new LoginRequest("admin", "wrong-password")));
    }

    @Test
    void loginRejectsUnknownUsername() {
        when(accountRepository.findByUsername("missing")).thenReturn(Optional.empty());

        assertThrows(UnauthorizedException.class,
                () -> authService.login(new LoginRequest("missing", "any-password")));
    }

    @Test
    void loginRejectsLockedAccount() {
        when(accountRepository.findByUsername("admin")).thenReturn(Optional.of(account(false)));

        assertThrows(ForbiddenException.class,
                () -> authService.login(new LoginRequest("admin", "correct-password")));
    }

    @Test
    void changePasswordEncodesAndSavesNewPassword() {
        Account account = account(true);
        when(accountRepository.findByUsername("admin")).thenReturn(Optional.of(account));
        when(passwordEncoder.matches("old-password", account.getPasswordHash())).thenReturn(true);
        when(passwordEncoder.encode("new-password")).thenReturn("new-bcrypt-hash");

        authService.changePassword("admin", new ChangePasswordRequest("old-password", "new-password"));

        assertEquals("new-bcrypt-hash", account.getPasswordHash());
        verify(accountRepository).save(account);
    }

    private Account account(boolean active) {
        Account account = new Account();
        account.setId(1);
        account.setUsername("admin");
        account.setPasswordHash("bcrypt-hash");
        account.setRole(AccountRole.ADMIN);
        account.setActive(active);
        account.setEmployeeId(6);
        return account;
    }
}
