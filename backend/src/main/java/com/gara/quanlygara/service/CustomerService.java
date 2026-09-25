package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.customer.CustomerRequest;
import com.gara.quanlygara.dto.customer.CustomerResponse;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.Customer;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CustomerService {

    private final CustomerRepository customerRepository;
    private final AccountRepository accountRepository;

    public CustomerService(CustomerRepository customerRepository, AccountRepository accountRepository) {
        this.customerRepository = customerRepository;
        this.accountRepository = accountRepository;
    }

    @Transactional(readOnly = true)
    public List<CustomerResponse> getAll() {
        return customerRepository.findAll(Sort.by(Sort.Direction.DESC, "id"))
                .stream()
                .map(CustomerResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public CustomerResponse getById(Integer id) {
        return CustomerResponse.from(findEntity(id));
    }

    @Transactional
    public CustomerResponse create(CustomerRequest request) {
        String phone = normalizeRequired(request.phone());
        if (customerRepository.existsByPhone(phone)) {
            throw new ConflictException("Số điện thoại đã được sử dụng bởi khách hàng khác.");
        }

        Customer customer = new Customer();
        apply(customer, request, phone);
        return CustomerResponse.from(customerRepository.save(customer));
    }

    @Transactional
    public CustomerResponse update(Integer id, CustomerRequest request) {
        Customer customer = findEntity(id);
        String phone = normalizeRequired(request.phone());
        if (customerRepository.existsByPhoneAndIdNot(phone, id)) {
            throw new ConflictException("Số điện thoại đã được sử dụng bởi khách hàng khác.");
        }

        apply(customer, request, phone);
        return CustomerResponse.from(customerRepository.save(customer));
    }

    @Transactional
    public CustomerResponse changeStatus(Integer id, boolean active) {
        Customer customer = findEntity(id);
        customer.setActive(active);

        accountRepository.findByCustomerId(id).ifPresent(account -> syncAccountStatus(account, active));
        return CustomerResponse.from(customerRepository.save(customer));
    }

    private Customer findEntity(Integer id) {
        return customerRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy khách hàng."));
    }

    private void apply(Customer customer, CustomerRequest request, String phone) {
        customer.setFullName(normalizeRequired(request.fullName()));
        customer.setPhone(phone);
        customer.setEmail(normalizeOptional(request.email()));
        customer.setAddress(normalizeOptional(request.address()));
    }

    private void syncAccountStatus(Account account, boolean active) {
        account.setActive(active);
        accountRepository.save(account);
    }

    private String normalizeRequired(String value) {
        return value.trim();
    }

    private String normalizeOptional(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }
}
