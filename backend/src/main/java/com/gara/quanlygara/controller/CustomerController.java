package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.customer.CustomerRequest;
import com.gara.quanlygara.dto.customer.CustomerResponse;
import com.gara.quanlygara.dto.customer.CustomerStatusRequest;
import com.gara.quanlygara.service.CustomerService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/customers")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST')")
public class CustomerController {

    private final CustomerService customerService;

    public CustomerController(CustomerService customerService) {
        this.customerService = customerService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<CustomerResponse>>> getAll() {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách khách hàng thành công.", customerService.getAll()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CustomerResponse>> getById(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy thông tin khách hàng thành công.", customerService.getById(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CustomerResponse>> create(@Valid @RequestBody CustomerRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Tạo khách hàng thành công.", customerService.create(request)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<CustomerResponse>> update(
            @PathVariable Integer id,
            @Valid @RequestBody CustomerRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật khách hàng thành công.", customerService.update(id, request)));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<CustomerResponse>> changeStatus(
            @PathVariable Integer id,
            @Valid @RequestBody CustomerStatusRequest request
    ) {
        String message = request.active()
                ? "Kích hoạt lại khách hàng thành công."
                : "Ngừng hoạt động khách hàng thành công.";
        return ResponseEntity.ok(ApiResponse.success(message, customerService.changeStatus(id, request.active())));
    }
}
