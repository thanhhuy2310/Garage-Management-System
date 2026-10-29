package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.insurance.InsuranceClaimRequest;
import com.gara.quanlygara.dto.insurance.InsuranceClaimResponse;
import com.gara.quanlygara.service.InsuranceClaimService;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/insurance/claims")
@PreAuthorize("hasAnyRole('MANAGER', 'RECEPTIONIST')")
public class InsuranceClaimController {
    private final InsuranceClaimService service;

    public InsuranceClaimController(InsuranceClaimService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<ApiResponse<InsuranceClaimResponse>> create(
            @Valid @RequestBody InsuranceClaimRequest request, Authentication authentication) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Đã tạo hồ sơ yêu cầu bồi thường.",
                        service.create(request, authentication)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<InsuranceClaimResponse>> get(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Thông tin hồ sơ bảo hiểm.", service.get(id)));
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<InsuranceClaimResponse>>> byVehicle(
            @RequestParam Integer vehicleId) {
        return ResponseEntity.ok(ApiResponse.success("Danh sách hồ sơ bảo hiểm của xe.",
                service.byVehicle(vehicleId)));
    }
}
