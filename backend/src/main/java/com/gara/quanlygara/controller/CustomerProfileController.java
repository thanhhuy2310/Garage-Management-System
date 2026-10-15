package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.customer.CustomerResponse;
import com.gara.quanlygara.service.CustomerService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/customer/profile")
@PreAuthorize("hasRole('CUSTOMER')")
public class CustomerProfileController {

    private final CustomerService customerService;

    public CustomerProfileController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @GetMapping
    public ApiResponse<CustomerResponse> getProfile(Authentication authentication) {
        return ApiResponse.success("Thông tin khách hàng.",
                customerService.getCurrentProfile(authentication.getName()));
    }
}
