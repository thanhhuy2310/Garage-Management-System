package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.technician.TechnicianRepairOrderResponse;
import com.gara.quanlygara.dto.technician.TechnicianResponse;
import com.gara.quanlygara.service.TechnicianAssignmentService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/technicians")
public class TechnicianController {

    private final TechnicianAssignmentService assignmentService;

    public TechnicianController(TechnicianAssignmentService assignmentService) {
        this.assignmentService = assignmentService;
    }

    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
    public ResponseEntity<ApiResponse<List<TechnicianResponse>>> getTechnicians() {
        return ResponseEntity.ok(ApiResponse.success(
                "Lấy danh sách kỹ thuật viên thành công.", assignmentService.getTechnicians()));
    }

    @GetMapping("/me/repair-orders")
    @PreAuthorize("hasRole('TECHNICIAN')")
    public ResponseEntity<ApiResponse<List<TechnicianRepairOrderResponse>>> getMyRepairOrders(
            Authentication authentication
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                "Lấy công việc được phân công thành công.",
                assignmentService.getMyRepairOrders(authentication.getName())));
    }
}
