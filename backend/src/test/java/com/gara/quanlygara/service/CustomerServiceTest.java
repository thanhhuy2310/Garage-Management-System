package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.customer.CustomerRequest;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.Customer;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CustomerServiceTest {

    @Mock
    private CustomerRepository customerRepository;

    @Mock
    private AccountRepository accountRepository;

    private CustomerService customerService;

    @BeforeEach
    void setUp() {
        customerService = new CustomerService(customerRepository, accountRepository);
    }

    @Test
    void createNormalizesAndPersistsCustomer() {
        when(customerRepository.existsByPhone("0901234567")).thenReturn(false);
        when(customerRepository.save(any(Customer.class))).thenAnswer(invocation -> {
            Customer customer = invocation.getArgument(0);
            customer.setId(9);
            return customer;
        });

        var response = customerService.create(new CustomerRequest(
                "  Nguyễn Văn A  ", " 0901234567 ", " ", "  Quận 1  "));

        assertEquals(9, response.id());
        assertEquals("Nguyễn Văn A", response.fullName());
        assertEquals("0901234567", response.phone());
        assertNull(response.email());
        assertEquals("Quận 1", response.address());
    }

    @Test
    void createRejectsDuplicatePhone() {
        when(customerRepository.existsByPhone("0901234567")).thenReturn(true);

        assertThrows(ConflictException.class, () -> customerService.create(request("0901234567")));
    }

    @Test
    void updateKeepsCustomerIdentity() {
        Customer customer = customer(3, "Tên cũ", "0900000000");
        when(customerRepository.findById(3)).thenReturn(Optional.of(customer));
        when(customerRepository.existsByPhoneAndIdNot("0911111111", 3)).thenReturn(false);
        when(customerRepository.save(customer)).thenReturn(customer);

        var response = customerService.update(3, request("0911111111"));

        assertEquals(3, response.id());
        assertEquals("Khách hàng", response.fullName());
        assertEquals("0911111111", response.phone());
    }

    @Test
    void updateRejectsPhoneOwnedByAnotherCustomer() {
        when(customerRepository.findById(3)).thenReturn(Optional.of(customer(3, "Tên cũ", "0900000000")));
        when(customerRepository.existsByPhoneAndIdNot("0911111111", 3)).thenReturn(true);

        assertThrows(ConflictException.class, () -> customerService.update(3, request("0911111111")));
    }

    @Test
    void getByIdRejectsMissingCustomer() {
        when(customerRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> customerService.getById(404));
    }

    @Test
    void changeStatusKeepsCustomerHistoryAndLocksLinkedAccount() {
        Customer customer = customer(3, "Khách hàng", "0900000000");
        Account account = new Account();
        account.setId(7);
        account.setActive(true);
        when(customerRepository.findById(3)).thenReturn(Optional.of(customer));
        when(customerRepository.save(customer)).thenReturn(customer);
        when(accountRepository.findByCustomerId(3)).thenReturn(Optional.of(account));

        var response = customerService.changeStatus(3, false);

        assertFalse(response.active());
        assertFalse(account.isActive());
        verify(accountRepository).save(account);
        verify(customerRepository).save(customer);
    }

    private CustomerRequest request(String phone) {
        return new CustomerRequest("Khách hàng", phone, "khach@example.com", "TP.HCM");
    }

    private Customer customer(int id, String fullName, String phone) {
        Customer customer = new Customer();
        customer.setId(id);
        customer.setFullName(fullName);
        customer.setPhone(phone);
        return customer;
    }
}
