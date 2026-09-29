package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.technician.TechnicianAssignmentRequest;
import com.gara.quanlygara.dto.technician.TechnicianAssignmentResponse;
import com.gara.quanlygara.service.TechnicianAssignmentService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/repair-orders/{repairOrderId}/technicians")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER')")
public class TechnicianAssignmentController {

    private final TechnicianAssignmentService assignmentService;

    public TechnicianAssignmentController(TechnicianAssignmentService assignmentService) {
        this.assignmentService = assignmentService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<TechnicianAssignmentResponse>>> getAssignments(
            @PathVariable Integer repairOrderId
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                "Lấy danh sách phân công thành công.", assignmentService.getAssignments(repairOrderId)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<TechnicianAssignmentResponse>> assign(
            @PathVariable Integer repairOrderId, @Valid @RequestBody TechnicianAssignmentRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.success(
                "Phân công kỹ thuật viên thành công.", assignmentService.assign(repairOrderId, request)));
    }
}
