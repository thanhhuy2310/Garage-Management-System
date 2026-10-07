package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.repair.RepairOrderDetailResponse;
import com.gara.quanlygara.service.CustomerRepairService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/customer/repairs")
@PreAuthorize("hasRole('CUSTOMER')")
public class CustomerRepairController {
    private final CustomerRepairService repairs;
    public CustomerRepairController(CustomerRepairService repairs) { this.repairs = repairs; }
    @GetMapping
    public ApiResponse<List<RepairOrderDetailResponse>> getMyRepairs(Authentication auth) {
        return ApiResponse.success("Tiến độ sửa chữa của bạn.", repairs.getMyRepairs(auth.getName()));
    }
}
