// TV3-TUAN7
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.sparepart.SparePartPageResponse;
import com.gara.quanlygara.dto.sparepart.SparePartRequest;
import com.gara.quanlygara.dto.sparepart.SparePartResponse;
import com.gara.quanlygara.dto.sparepart.WarehouseOptionResponse;
import com.gara.quanlygara.service.SparePartService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/spare-parts")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE', 'RECEPTIONIST', 'TECHNICIAN')")
public class SparePartController {

    private static final String CAN_WRITE = "hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE')";

    private final SparePartService sparePartService;

    public SparePartController(SparePartService sparePartService) {
        this.sparePartService = sparePartService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<SparePartPageResponse>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách phụ tùng thành công.",
                sparePartService.getAll(page, size, search)));
    }

    @GetMapping("/warehouses")
    public ResponseEntity<ApiResponse<List<WarehouseOptionResponse>>> getWarehouses() {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách kho thành công.",
                sparePartService.getWarehouses()));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<SparePartResponse>> getById(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy thông tin phụ tùng thành công.",
                sparePartService.getById(id)));
    }

    @PostMapping
    @PreAuthorize(CAN_WRITE)
    public ResponseEntity<ApiResponse<SparePartResponse>> create(@Valid @RequestBody SparePartRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Thêm phụ tùng thành công.", sparePartService.create(request)));
    }

    @PutMapping("/{id}")
    @PreAuthorize(CAN_WRITE)
    public ResponseEntity<ApiResponse<SparePartResponse>> update(
            @PathVariable Integer id,
            @Valid @RequestBody SparePartRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật phụ tùng thành công.",
                sparePartService.update(id, request)));
    }
}
