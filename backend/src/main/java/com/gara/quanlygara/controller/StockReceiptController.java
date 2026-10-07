// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.warehouse.ImportRequest;
import com.gara.quanlygara.dto.warehouse.ImportResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.StockReceiptService;
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
@RequestMapping("/api/warehouse/imports")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE')")
public class StockReceiptController {

    private final StockReceiptService receiptService;
    private final StaffContext staffContext;

    public StockReceiptController(StockReceiptService receiptService, StaffContext staffContext) {
        this.receiptService = receiptService;
        this.staffContext = staffContext;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<PageResponse<ImportResponse>>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách phiếu nhập thành công.",
                receiptService.getAll(page, size)));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ImportResponse>> get(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy phiếu nhập thành công.", receiptService.get(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<ImportResponse>> create(
            @Valid @RequestBody ImportRequest request, Authentication authentication
    ) {
        Integer staffId = staffContext.employeeId(authentication);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Nhập kho thành công.", receiptService.create(request, staffId)));
    }
}
