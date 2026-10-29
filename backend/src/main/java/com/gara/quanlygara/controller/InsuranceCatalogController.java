package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.insurance.InsuranceCompanyRequest;
import com.gara.quanlygara.dto.insurance.InsuranceCompanyResponse;
import com.gara.quanlygara.dto.insurance.InsurancePolicyRequest;
import com.gara.quanlygara.dto.insurance.InsurancePolicyResponse;
import com.gara.quanlygara.dto.insurance.InsurancePolicyVerificationRequest;
import com.gara.quanlygara.service.InsuranceCatalogService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/insurance")
@PreAuthorize("hasAnyRole('MANAGER', 'RECEPTIONIST')")
public class InsuranceCatalogController {
    private final InsuranceCatalogService service;

    public InsuranceCatalogController(InsuranceCatalogService service) {
        this.service = service;
    }

    @GetMapping("/companies")
    public ResponseEntity<ApiResponse<List<InsuranceCompanyResponse>>> companies() {
        return ResponseEntity.ok(ApiResponse.success("Danh sách công ty bảo hiểm.", service.companies()));
    }

    @PostMapping("/companies")
    public ResponseEntity<ApiResponse<InsuranceCompanyResponse>> createCompany(
            @Valid @RequestBody InsuranceCompanyRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Đã tạo công ty bảo hiểm.", service.createCompany(request)));
    }

    @PutMapping("/companies/{id}")
    public ResponseEntity<ApiResponse<InsuranceCompanyResponse>> updateCompany(
            @PathVariable Integer id, @Valid @RequestBody InsuranceCompanyRequest request) {
        return ResponseEntity.ok(ApiResponse.success("Đã cập nhật công ty bảo hiểm.",
                service.updateCompany(id, request)));
    }

    @GetMapping("/policies")
    public ResponseEntity<ApiResponse<List<InsurancePolicyResponse>>> policies(
            @RequestParam Integer vehicleId) {
        return ResponseEntity.ok(ApiResponse.success("Danh sách hợp đồng bảo hiểm.",
                service.policiesForVehicle(vehicleId)));
    }

    @GetMapping("/policies/{id}")
    public ResponseEntity<ApiResponse<InsurancePolicyResponse>> policy(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Thông tin hợp đồng bảo hiểm.", service.policy(id)));
    }

    @PostMapping("/policies")
    public ResponseEntity<ApiResponse<InsurancePolicyResponse>> createPolicy(
            @Valid @RequestBody InsurancePolicyRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Đã tạo hợp đồng bảo hiểm.", service.createPolicy(request)));
    }

    @PostMapping("/policies/{id}/verification")
    public ResponseEntity<ApiResponse<InsurancePolicyResponse>> verifyPolicy(
            @PathVariable Integer id, @Valid @RequestBody InsurancePolicyVerificationRequest request,
            Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.success("Đã ghi nhận kết quả xác minh hợp đồng.",
                service.verifyPolicy(id, request, authentication)));
    }
}
