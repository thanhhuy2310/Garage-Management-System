// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.warehouse.CheckActualRequest;
import com.gara.quanlygara.dto.warehouse.CheckCreateRequest;
import com.gara.quanlygara.dto.warehouse.CheckDecisionRequest;
import com.gara.quanlygara.dto.warehouse.CheckResponse;
import com.gara.quanlygara.dto.warehouse.CheckSummaryResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.InventoryCheckService;
import jakarta.validation.Valid;
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
@RequestMapping("/api/warehouse/checks")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE')")
public class InventoryCheckController {

    private static final String MANAGER_ONLY = "hasRole('MANAGER')";

    private final InventoryCheckService checkService;
    private final StaffContext staffContext;

    public InventoryCheckController(InventoryCheckService checkService, StaffContext staffContext) {
        this.checkService = checkService;
        this.staffContext = staffContext;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<CheckSummaryResponse>>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách phiên kiểm kê thành công.",
                checkService.getAll(page, size)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<CheckResponse>> get(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy phiên kiểm kê thành công.", checkService.get(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<CheckResponse>> create(
            @Valid @RequestBody CheckCreateRequest request, Authentication authentication
    ) {
        Integer staffId = staffContext.employeeId(authentication);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Đã tạo phiên kiểm kê.", checkService.create(request, staffId)));
    }

    @PutMapping("/{id}/items/{partId}")
    public ResponseEntity<ApiResponse<CheckResponse>> setActual(
            @PathVariable Integer id,
            @PathVariable Integer partId,
            @Valid @RequestBody CheckActualRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success("Đã ghi nhận số lượng thực tế.",
                checkService.setActual(id, partId, request)));
    }

    // Chỉ MANAGER được duyệt/từ chối điều chỉnh tồn kho.
    @PostMapping("/{id}/approve")
    @PreAuthorize(MANAGER_ONLY)
    public ResponseEntity<ApiResponse<CheckResponse>> approve(
            @PathVariable Integer id,
            @Valid @RequestBody(required = false) CheckDecisionRequest request,
            Authentication authentication
    ) {
        Integer approverId = staffContext.employeeId(authentication);
        return ResponseEntity.ok(ApiResponse.success("Đã phê duyệt điều chỉnh tồn kho.",
                checkService.approve(id, request == null ? null : request.reason(), approverId)));
    }

    @PostMapping("/{id}/reject")
    @PreAuthorize(MANAGER_ONLY)
    public ResponseEntity<ApiResponse<CheckResponse>> reject(
            @PathVariable Integer id,
            @Valid @RequestBody CheckDecisionRequest request,
            Authentication authentication
    ) {
        Integer approverId = staffContext.employeeId(authentication);
        return ResponseEntity.ok(ApiResponse.success("Đã từ chối điều chỉnh tồn kho.",
                checkService.reject(id, request.reason(), approverId)));
    }
}
