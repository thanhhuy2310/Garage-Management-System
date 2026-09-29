package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.service.ServiceRequest;
import com.gara.quanlygara.dto.service.ServiceResponse;
import com.gara.quanlygara.service.ServiceCatalogService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/services")
@PreAuthorize("isAuthenticated()")
public class ServiceController {

    private final ServiceCatalogService serviceCatalogService;

    public ServiceController(ServiceCatalogService serviceCatalogService) {
        this.serviceCatalogService = serviceCatalogService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<ServiceResponse>>> getAll(
            @RequestParam(required = false) String keyword
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                "Lấy danh sách dịch vụ thành công.", serviceCatalogService.getAll(keyword)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ServiceResponse>> getById(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success(
                "Lấy thông tin dịch vụ thành công.", serviceCatalogService.getById(id)));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ApiResponse<ServiceResponse>> create(@Valid @RequestBody ServiceRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(
                "Thêm dịch vụ thành công.", serviceCatalogService.create(request)));
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ApiResponse<ServiceResponse>> update(
            @PathVariable Integer id, @Valid @RequestBody ServiceRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                "Cập nhật dịch vụ thành công.", serviceCatalogService.update(id, request)));
    }
}
