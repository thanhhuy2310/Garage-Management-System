package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.repair.RepairOrderDetailResponse;
import com.gara.quanlygara.dto.repair.RepairOrderResponse;
import com.gara.quanlygara.service.RepairOrderQueryService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/repair-orders")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST', 'TECHNICIAN')")
public class RepairOrderController {

    private final RepairOrderQueryService repairOrderService;

    public RepairOrderController(RepairOrderQueryService repairOrderService) {
        this.repairOrderService = repairOrderService;
    }

    @GetMapping
    public ApiResponse<List<RepairOrderResponse>> getAll(Authentication authentication) {
        return ApiResponse.success("Lấy danh sách phiếu sửa chữa thành công.",
                repairOrderService.getAll(authentication));
    }

    @GetMapping("/{id}")
    public ApiResponse<RepairOrderDetailResponse> getById(@PathVariable Integer id,
                                                       Authentication authentication) {
        return ApiResponse.success("Lấy phiếu sửa chữa thành công.",
                repairOrderService.getById(id, authentication));
    }
}
