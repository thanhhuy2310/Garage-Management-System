package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.auth.ChangePasswordRequest;
import com.gara.quanlygara.dto.auth.LoginRequest;
import com.gara.quanlygara.dto.auth.RegisterRequest;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.Customer;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ForbiddenException;
import com.gara.quanlygara.exception.UnauthorizedException;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.security.JwtService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtService jwtService;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(accountRepository, customerRepository, passwordEncoder, jwtService);
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

    @Test
    void changePasswordRejectsWrongCurrentPassword() {
        Account account = account(true);
        when(accountRepository.findByUsername("admin")).thenReturn(Optional.of(account));
        when(passwordEncoder.matches("wrong-password", account.getPasswordHash())).thenReturn(false);

        assertThrows(BadRequestException.class,
                () -> authService.changePassword(
                        "admin",
                        new ChangePasswordRequest("wrong-password", "new-password")
                ));
    }

    @Test
    void changedPasswordRejectsOldLoginAndAllowsNewLogin() {
        Account account = account(true);
        when(accountRepository.findByUsername("admin")).thenReturn(Optional.of(account));
        when(passwordEncoder.matches("old-password", "bcrypt-hash")).thenReturn(true);
        when(passwordEncoder.encode("new-password")).thenReturn("new-bcrypt-hash");
        when(passwordEncoder.matches("old-password", "new-bcrypt-hash")).thenReturn(false);
        when(passwordEncoder.matches("new-password", "new-bcrypt-hash")).thenReturn(true);
        when(jwtService.generateToken(account)).thenReturn("new-jwt-token");
        when(jwtService.getExpirationSeconds()).thenReturn(3600L);

        authService.changePassword("admin", new ChangePasswordRequest("old-password", "new-password"));

        assertThrows(UnauthorizedException.class,
                () -> authService.login(new LoginRequest("admin", "old-password")));
        assertEquals("new-jwt-token",
                authService.login(new LoginRequest("admin", "new-password")).accessToken());
    }

    @Test
    void registerCreatesCustomerAccountAndReturnsToken() {
        var request = new RegisterRequest(
                "Nguyễn Văn Mới",
                "0901234567",
                "moi@example.com",
                "Quận 1, TP.HCM",
                "khachmoi",
                "password123"
        );
        when(accountRepository.existsByUsername("khachmoi")).thenReturn(false);
        when(customerRepository.existsByPhone("0901234567")).thenReturn(false);
        when(customerRepository.save(org.mockito.ArgumentMatchers.any(Customer.class)))
                .thenAnswer(invocation -> {
                    Customer customer = invocation.getArgument(0);
                    customer.setId(10);
                    return customer;
                });
        when(passwordEncoder.encode("password123")).thenReturn("bcrypt-hash");
        when(accountRepository.save(org.mockito.ArgumentMatchers.any(Account.class)))
                .thenAnswer(invocation -> {
                    Account account = invocation.getArgument(0);
                    account.setId(20);
                    return account;
                });
        when(jwtService.generateToken(org.mockito.ArgumentMatchers.any(Account.class))).thenReturn("jwt-token");
        when(jwtService.getExpirationSeconds()).thenReturn(3600L);

        var response = authService.register(request);

        assertEquals("jwt-token", response.accessToken());
        assertEquals("CUSTOMER", response.account().role());
        assertEquals(10, response.account().customerId());
        assertNull(response.account().employeeId());
        verify(passwordEncoder).encode("password123");
    }

    @Test
    void registerRejectsDuplicateUsername() {
        when(accountRepository.existsByUsername("khachmoi")).thenReturn(true);

        assertThrows(ConflictException.class, () -> authService.register(registerRequest()));
    }

    @Test
    void registerRejectsDuplicatePhone() {
        when(accountRepository.existsByUsername("khachmoi")).thenReturn(false);
        when(customerRepository.existsByPhone("0901234567")).thenReturn(true);

        assertThrows(ConflictException.class, () -> authService.register(registerRequest()));
    }

    private RegisterRequest registerRequest() {
        return new RegisterRequest(
                "Nguyễn Văn Mới",
                "0901234567",
                "moi@example.com",
                "Quận 1, TP.HCM",
                "khachmoi",
                "password123"
        );
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
