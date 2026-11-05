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

    public record ContactDetails(@jakarta.validation.constraints.NotBlank @jakarta.validation.constraints.Pattern(regexp="^\\+?[0-9]{9,15}$") String phone,
                                 @jakarta.validation.constraints.Size(max=255) String address) {}
    @org.springframework.web.bind.annotation.PutMapping
    public ApiResponse<CustomerResponse> updateProfile(Authentication auth,@jakarta.validation.Valid @org.springframework.web.bind.annotation.RequestBody ContactDetails input){
        return ApiResponse.success("Đã cập nhật thông tin liên hệ.",customerService.updateContact(auth.getName(),input.phone(),input.address()));
    }
    @GetMapping
    public ApiResponse<CustomerResponse> getProfile(Authentication authentication) {
        return ApiResponse.success("Thông tin khách hàng.",
                customerService.getCurrentProfile(authentication.getName()));
    }
}
