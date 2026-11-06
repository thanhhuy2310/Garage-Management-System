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
    private final com.gara.quanlygara.service.TechnicianWorkloadService workload;

    public TechnicianController(TechnicianAssignmentService assignmentService,
                                com.gara.quanlygara.service.TechnicianWorkloadService workload) {
        this.assignmentService = assignmentService;
        this.workload = workload;
    }

    @GetMapping("/workload")
    @PreAuthorize("hasRole('MANAGER')")
    public Object workload(@org.springframework.web.bind.annotation.RequestParam(required=false) java.time.LocalDate date) {
        return ApiResponse.success("Tải công việc kỹ thuật viên.",workload.list(date==null?java.time.LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")):date));
    }

    @GetMapping("/shifts")
    @PreAuthorize("hasRole('MANAGER')")
    public Object shifts() { return ApiResponse.success("Ca làm việc.",workload.shifts()); }

    @org.springframework.web.bind.annotation.PostMapping("/shifts")
    @PreAuthorize("hasRole('MANAGER')")
    public Object createShift(@jakarta.validation.Valid @org.springframework.web.bind.annotation.RequestBody com.gara.quanlygara.service.TechnicianWorkloadService.ShiftRequest request) {
        workload.saveShift(null,request); return ApiResponse.success("Đã thêm ca làm.",null);
    }

    @org.springframework.web.bind.annotation.PutMapping("/shifts/{id}")
    @PreAuthorize("hasRole('MANAGER')")
    public Object updateShift(@org.springframework.web.bind.annotation.PathVariable Integer id,
        @jakarta.validation.Valid @org.springframework.web.bind.annotation.RequestBody com.gara.quanlygara.service.TechnicianWorkloadService.ShiftRequest request) {
        workload.saveShift(id,request); return ApiResponse.success("Đã cập nhật ca làm.",null);
    }

    @org.springframework.web.bind.annotation.PutMapping("/{id}/schedule")
    @PreAuthorize("hasRole('MANAGER')")
    public Object schedule(@org.springframework.web.bind.annotation.PathVariable int id,
        @jakarta.validation.Valid @org.springframework.web.bind.annotation.RequestBody com.gara.quanlygara.service.TechnicianWorkloadService.ScheduleRequest request) {
        workload.saveSchedule(id,request); return ApiResponse.success("Đã lưu lịch làm việc.",null);
    }

    @GetMapping
    @PreAuthorize("hasRole('MANAGER')")
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
