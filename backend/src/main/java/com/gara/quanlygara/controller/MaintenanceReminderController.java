// TV3-TUAN10
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.notification.MaintenanceReminderRequest;
import com.gara.quanlygara.dto.notification.MaintenanceReminderResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.MaintenanceReminderService;
import jakarta.validation.Valid;
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

/** Nhân viên thiết lập, xem và hủy lịch nhắc bảo dưỡng. Khách hàng không có quyền. */
@RestController
@RequestMapping("/api/maintenance-reminders")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST')")
public class MaintenanceReminderController {

    private final MaintenanceReminderService reminderService;
    private final StaffContext staffContext;

    public MaintenanceReminderController(MaintenanceReminderService reminderService, StaffContext staffContext) {
        this.reminderService = reminderService;
        this.staffContext = staffContext;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<MaintenanceReminderResponse>>> getAll(
            @RequestParam(required = false) Integer vehicleId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách lịch nhắc bảo dưỡng thành công.",
                reminderService.getAll(vehicleId, status, page, size)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<MaintenanceReminderResponse>> create(
            @Valid @RequestBody MaintenanceReminderRequest request,
            Authentication authentication
    ) {
        // Nhân viên tạo (nếu tài khoản có liên kết nhân viên) được ghi lại; ADMIN không bắt buộc có.
        Integer staffId = staffContext.account(authentication).getEmployeeId();
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Đã thiết lập lịch nhắc bảo dưỡng.", reminderService.create(request, staffId)));
    }

    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse<MaintenanceReminderResponse>> cancel(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Đã hủy lịch nhắc bảo dưỡng.", reminderService.cancel(id)));
    }
}
