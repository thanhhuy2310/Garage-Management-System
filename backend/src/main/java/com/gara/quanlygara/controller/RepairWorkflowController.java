package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.repair.RepairOrderDetailResponse;
import com.gara.quanlygara.dto.repair.RepairRequests;
import com.gara.quanlygara.service.RepairOrderQueryService;
import com.gara.quanlygara.service.RepairWorkflowService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/repair-orders")
public class RepairWorkflowController {
    private final RepairWorkflowService workflow;
    private final RepairOrderQueryService queries;
    public RepairWorkflowController(RepairWorkflowService workflow, RepairOrderQueryService queries) {
        this.workflow = workflow;
        this.queries = queries;
    }

    @GetMapping("/receptions")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','RECEPTIONIST')")
    public ApiResponse<List<Map<String, Object>>> receptions() {
        return ApiResponse.success("Danh sách tiếp nhận chưa lập phiếu.", workflow.availableReceptions());
    }

    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','RECEPTIONIST')")
    public ApiResponse<RepairOrderDetailResponse> create(@Valid @RequestBody RepairRequests.Create request, Authentication auth) {
        var order = workflow.create(request, auth);
        return ApiResponse.success("Đã lập phiếu sửa chữa.", queries.getById(order.getId(), auth));
    }

    @PostMapping("/{id}/services")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','RECEPTIONIST')")
    public ApiResponse<RepairOrderDetailResponse> addService(@PathVariable Integer id,
            @Valid @RequestBody RepairRequests.ServiceLine request, Authentication auth) {
        workflow.addService(id, request, auth);
        return ApiResponse.success("Đã bổ sung dịch vụ.", queries.getById(id, auth));
    }

    @PutMapping("/{id}/progress")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','TECHNICIAN')")
    public ApiResponse<RepairOrderDetailResponse> progress(@PathVariable Integer id,
            @Valid @RequestBody RepairRequests.Progress request, Authentication auth) {
        workflow.updateProgress(id, request, auth);
        return ApiResponse.success("Đã cập nhật tiến độ.", queries.getById(id, auth));
    }

    @PutMapping("/{id}/services/{serviceId}/progress")
    @PreAuthorize("hasAnyRole('ADMIN','MANAGER','TECHNICIAN')")
    public ApiResponse<RepairOrderDetailResponse> serviceProgress(@PathVariable Integer id, @PathVariable Integer serviceId,
            @Valid @RequestBody RepairRequests.Progress request, Authentication auth) {
        workflow.updateServiceProgress(id, serviceId, request, auth);
        return ApiResponse.success("Đã cập nhật dịch vụ.", queries.getById(id, auth));
    }
}
