package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.vehicle.VehicleResponse;
import com.gara.quanlygara.service.VehicleService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * GET /api/customers/{id}/vehicles. Tách khỏi CustomerController vì controller đó
 * chỉ cho phép nhân viên, trong khi khách hàng cần xem xe của chính mình.
 */
@RestController
@RequestMapping("/api/customers")
public class CustomerVehicleController {

    private final VehicleService vehicleService;

    public CustomerVehicleController(VehicleService vehicleService) {
        this.vehicleService = vehicleService;
    }

    @GetMapping("/{id}/vehicles")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST')"
            + " or (hasRole('CUSTOMER') and @vehicleAccess.ownsCustomer(authentication, #id))")
    public ResponseEntity<ApiResponse<List<VehicleResponse>>> getByCustomer(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách xe của khách hàng thành công.",
                vehicleService.getByCustomer(id)));
    }
}
