package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.customer.CustomerRequest;
import com.gara.quanlygara.dto.customer.CustomerResponse;
import com.gara.quanlygara.entity.Customer;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.CustomerRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CustomerService {

    private final CustomerRepository customerRepository;

    public CustomerService(CustomerRepository customerRepository) {
        this.customerRepository = customerRepository;
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

    private String normalizeRequired(String value) {
        return value.trim();
    }

    private String normalizeOptional(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }
}
