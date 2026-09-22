package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.account.CreateAccountRequest;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.repository.AccountRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AccountServiceTest {

    @Mock
    private AccountRepository accountRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    private AccountService accountService;

    @BeforeEach
    void setUp() {
        accountService = new AccountService(accountRepository, passwordEncoder);
    }

    @Test
    void createRequiresExactlyOneOwner() {
        var request = new CreateAccountRequest(
                "new-user", "password123", "CUSTOMER", true, null, null);

        assertThrows(BadRequestException.class, () -> accountService.create(request));
    }

    @Test
    void createRejectsDuplicateUsername() {
        when(accountRepository.existsByUsername("admin")).thenReturn(true);
        var request = new CreateAccountRequest(
                "admin", "password123", "ADMIN", true, null, 6);

        assertThrows(ConflictException.class, () -> accountService.create(request));
    }

    @Test
    void createEncodesPasswordAndKeepsSqlRoleValue() {
        when(accountRepository.existsByUsername("customer-01")).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("bcrypt-hash");
        when(accountRepository.save(any(Account.class))).thenAnswer(invocation -> {
            Account account = invocation.getArgument(0);
            account.setId(10);
            return account;
        });

        var response = accountService.create(new CreateAccountRequest(
                "customer-01", "password123", "customer", true, 1, null));

        assertEquals("CUSTOMER", response.role());
        assertEquals(1, response.customerId());
    }
}
