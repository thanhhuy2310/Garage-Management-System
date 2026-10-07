// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.warehouse.ConfirmUsageRequest;
import com.gara.quanlygara.dto.warehouse.IssueRequest;
import com.gara.quanlygara.dto.warehouse.IssueResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.StockIssueService;
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

@RestController
@RequestMapping("/api/warehouse/exports")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE', 'TECHNICIAN')")
public class StockIssueController {

    private final StockIssueService issueService;
    private final StaffContext staffContext;

    public StockIssueController(StockIssueService issueService, StaffContext staffContext) {
        this.issueService = issueService;
        this.staffContext = staffContext;
    }

    // Kỹ thuật viên chỉ thấy các phiếu xuất liên quan tới mình.
    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<IssueResponse>>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            Authentication authentication
    ) {
        int technicianId = staffContext.isTechnician(authentication) ? staffContext.employeeId(authentication) : 0;
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách phiếu xuất thành công.",
                issueService.getAll(page, size, technicianId)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<IssueResponse>> get(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy phiếu xuất thành công.", issueService.get(id)));
    }

    @PostMapping
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE')")
    public ResponseEntity<ApiResponse<IssueResponse>> create(
            @Valid @RequestBody IssueRequest request, Authentication authentication
    ) {
        Integer staffId = staffContext.employeeId(authentication);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Đã cấp phát phụ tùng, chờ kỹ thuật viên xác nhận thực dùng.",
                        issueService.create(request, staffId)));
    }

    @PostMapping("/{issueId}/items/{partId}/confirm")
    @PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'TECHNICIAN')")
    public ResponseEntity<ApiResponse<IssueResponse.Item>> confirmUsage(
            @PathVariable Integer issueId,
            @PathVariable Integer partId,
            @Valid @RequestBody ConfirmUsageRequest request,
            Authentication authentication
    ) {
        boolean technician = staffContext.isTechnician(authentication);
        // Với ADMIN/MANAGER người xác nhận lấy từ request nên không bắt buộc tài khoản liên kết nhân viên.
        Integer callerId = technician ? staffContext.employeeId(authentication) : null;
        return ResponseEntity.ok(ApiResponse.success("Đã xác nhận số lượng thực dùng.",
                issueService.confirmUsage(issueId, partId, request, callerId, technician)));
    }
}
