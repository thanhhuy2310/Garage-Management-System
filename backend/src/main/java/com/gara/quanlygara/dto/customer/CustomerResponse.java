package com.gara.quanlygara.dto.customer;

import com.gara.quanlygara.entity.Customer;

public record CustomerResponse(
        Integer id,
        String fullName,
        String phone,
        String email,
        String address,
        boolean active
) {
    public static CustomerResponse from(Customer customer) {
        return new CustomerResponse(
                customer.getId(),
                customer.getFullName(),
                customer.getPhone(),
                customer.getEmail(),
                customer.getAddress(),
                customer.isActive()
        );
    }
}
