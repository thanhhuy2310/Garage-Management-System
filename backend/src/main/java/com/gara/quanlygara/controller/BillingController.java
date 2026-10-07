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
@PreAuthorize("hasAnyRole('ADMIN','MANAGER','RECEPTIONIST')")
public class BillingController {
    private final BillingService billing;
    public BillingController(BillingService billing) { this.billing = billing; }
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
            @Valid @RequestBody BillingRequests.RecordPayment request) {
        return ApiResponse.success("Đã ghi nhận thanh toán.", billing.recordPayment(id, request));
    }
}
