package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.billing.BillingRequests;
import com.gara.quanlygara.dto.billing.InvoiceResponse;
import com.gara.quanlygara.service.BillingService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/invoices")
@PreAuthorize("hasAnyRole('MANAGER','RECEPTIONIST')")
public class BillingController {
    private final BillingService billing;
    private final com.gara.quanlygara.security.StaffContext staff;
    public BillingController(BillingService billing, com.gara.quanlygara.security.StaffContext staff) {
        this.billing = billing;
        this.staff = staff;
    }
    @GetMapping
    public ApiResponse<List<InvoiceResponse>> getAll() {
        return ApiResponse.success("Danh sách hóa đơn.", billing.getAll());
    }
    @GetMapping("/{id}")
    public ApiResponse<InvoiceResponse.Detail> getById(@PathVariable Integer id) {
        return ApiResponse.success("Chi tiết hóa đơn.", billing.getById(id));
    }
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<InvoiceResponse.Detail> create(@Valid @RequestBody BillingRequests.CreateInvoice request) {
        return ApiResponse.success("Đã lập hóa đơn.", billing.create(request.repairOrderId()));
    }
    @PostMapping("/{id}/payments")
    public ApiResponse<InvoiceResponse.Detail> pay(@PathVariable Integer id,
            @Valid @RequestBody BillingRequests.RecordPayment request,
            org.springframework.security.core.Authentication authentication) {
        return ApiResponse.success("Đã ghi nhận thanh toán.", billing.recordPayment(id, request, "INSURER".equals(request.payer()) ? staff.employeeId(authentication) : null));
    }
}
