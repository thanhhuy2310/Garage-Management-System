package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.account.AccountResponse;
import com.gara.quanlygara.dto.account.CreateAccountRequest;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.EmployeeRepository;
import com.gara.quanlygara.repository.TechnicianRepository;
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
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AccountServiceTest {

    @Mock
    private AccountRepository accountRepository;
    @Mock
    private CustomerRepository customerRepository;
    @Mock
    private EmployeeRepository employeeRepository;
    @Mock
    private TechnicianRepository technicianRepository;
    @Mock
    private PasswordEncoder passwordEncoder;

    private AccountService accountService;

    @BeforeEach
    void setUp() {
        accountService = new AccountService(
                accountRepository,
                customerRepository,
                employeeRepository,
                technicianRepository,
                passwordEncoder
        );
    }

    @Test
    void adminCanCreateReceptionistAccount() {
        var response = createStaffAccount("RECEPTIONIST", 1, false);

        assertEquals("RECEPTIONIST", response.role());
        assertEquals(1, response.employeeId());
        assertNull(response.customerId());
    }

    @Test
    void adminCanCreateManagerAccount() {
        var response = createStaffAccount("MANAGER", 5, false);

        assertEquals("MANAGER", response.role());
        assertEquals(5, response.employeeId());
    }

    @Test
    void adminCanCreateTechnicianAccountForDeclaredTechnician() {
        var response = createStaffAccount("TECHNICIAN", 2, true);

        assertEquals("TECHNICIAN", response.role());
        assertEquals(2, response.employeeId());
    }

    @Test
    void createTechnicianRejectsEmployeeWithoutTechnicianRecord() {
        when(employeeRepository.existsById(4)).thenReturn(true);
        when(technicianRepository.existsById(4)).thenReturn(false);

        var request = new CreateAccountRequest(
                "not-technician", "password123", "TECHNICIAN", true, null, 4);

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
    void createRejectsPublicCustomerRole() {
        var request = new CreateAccountRequest(
                "customer", "password123", "CUSTOMER", true, 1, null);

        assertThrows(BadRequestException.class, () -> accountService.create(request));
    }

    @Test
    void customerWithEmployeeOwnerFailsValidation() {
        assertThrows(BadRequestException.class,
                () -> accountService.validateAccountOwner(AccountRole.CUSTOMER, null, 1));
    }

    @Test
    void customerWithoutCustomerOwnerFailsValidation() {
        assertThrows(BadRequestException.class,
                () -> accountService.validateAccountOwner(AccountRole.CUSTOMER, null, null));
    }

    @Test
    void adminWithCustomerOwnerFailsValidation() {
        assertThrows(BadRequestException.class,
                () -> accountService.validateAccountOwner(AccountRole.ADMIN, 1, null));
    }

    @Test
    void receptionistWithoutEmployeeOwnerFailsValidation() {
        assertThrows(BadRequestException.class,
                () -> accountService.validateAccountOwner(AccountRole.RECEPTIONIST, null, null));
    }

    @Test
    void technicianWithMissingEmployeeFailsValidation() {
        when(employeeRepository.existsById(99)).thenReturn(false);

        assertThrows(BadRequestException.class,
                () -> accountService.validateAccountOwner(AccountRole.TECHNICIAN, null, 99));
    }

    @Test
    void staffWithMissingEmployeeFailsValidation() {
        when(employeeRepository.existsById(99)).thenReturn(false);

        assertThrows(BadRequestException.class,
                () -> accountService.validateAccountOwner(AccountRole.MANAGER, null, 99));
    }

    @Test
    void changeRoleAllowsStaffToStaffWhenOwnerMatches() {
        Account account = staffAccount(AccountRole.RECEPTIONIST, 1);
        when(accountRepository.findById(10)).thenReturn(Optional.of(account));
        when(employeeRepository.existsById(1)).thenReturn(true);
        when(accountRepository.save(account)).thenReturn(account);

        var response = accountService.changeRole(10, "MANAGER");

        assertEquals("MANAGER", response.role());
        assertEquals(1, response.employeeId());
    }

    @Test
    void changeRoleRejectsCustomerToStaff() {
        Account account = new Account();
        account.setId(11);
        account.setUsername("customer");
        account.setRole(AccountRole.CUSTOMER);
        account.setCustomerId(1);
        when(accountRepository.findById(11)).thenReturn(Optional.of(account));

        assertThrows(BadRequestException.class, () -> accountService.changeRole(11, "ADMIN"));
    }

    private AccountResponse createStaffAccount(String role, int employeeId, boolean technician) {
        String username = role.toLowerCase() + "-new";
        when(accountRepository.existsByUsername(username)).thenReturn(false);
        when(employeeRepository.existsById(employeeId)).thenReturn(true);
        if (AccountRole.TECHNICIAN.name().equals(role)) {
            when(technicianRepository.existsById(employeeId)).thenReturn(technician);
        }
        when(accountRepository.existsByEmployeeId(employeeId)).thenReturn(false);
        when(passwordEncoder.encode("password123")).thenReturn("bcrypt-hash");
        when(accountRepository.save(any(Account.class))).thenAnswer(invocation -> {
            Account account = invocation.getArgument(0);
            account.setId(20);
            return account;
        });

        return accountService.create(new CreateAccountRequest(
                username, "password123", role, true, null, employeeId));
    }

    private Account staffAccount(AccountRole role, int employeeId) {
        Account account = new Account();
        account.setId(10);
        account.setUsername("staff");
        account.setPasswordHash("bcrypt-hash");
        account.setRole(role);
        account.setActive(true);
        account.setEmployeeId(employeeId);
        return account;
    }
}
