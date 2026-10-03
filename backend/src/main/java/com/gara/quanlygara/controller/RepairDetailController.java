// TV3-TUAN7
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.repairdetail.RepairDetailCreateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailResponse;
import com.gara.quanlygara.dto.repairdetail.RepairDetailType;
import com.gara.quanlygara.dto.repairdetail.RepairDetailUpdateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailsResponse;
import com.gara.quanlygara.service.RepairDetailService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Chi tiết phiếu sửa chữa. Một hạng mục được xác định bởi (loại, mã): vì CSDL dùng khóa chính
 * (phiếu + dịch vụ) và (phiếu + phụ tùng) nên đường dẫn là /details/{service|spare-part}/{itemId}.
 */
@RestController
@RequestMapping("/api/repair-orders/{repairOrderId}/details")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST', 'TECHNICIAN', 'WAREHOUSE')")
public class RepairDetailController {

    private static final String CAN_WRITE = "hasAnyRole('ADMIN', 'MANAGER', 'RECEPTIONIST')";

    private final RepairDetailService repairDetailService;

    public RepairDetailController(RepairDetailService repairDetailService) {
        this.repairDetailService = repairDetailService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<RepairDetailsResponse>> getAll(@PathVariable Integer repairOrderId) {
        return ResponseEntity.ok(ApiResponse.success("Lấy chi tiết phiếu sửa chữa thành công.",
                repairDetailService.getAll(repairOrderId)));
    }

    @GetMapping("/{type}/{itemId}")
    public ResponseEntity<ApiResponse<RepairDetailResponse>> get(
            @PathVariable Integer repairOrderId,
            @PathVariable String type,
            @PathVariable Integer itemId
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy hạng mục thành công.",
                repairDetailService.get(repairOrderId, RepairDetailType.fromPath(type), itemId)));
    }

    @PostMapping
    @PreAuthorize(CAN_WRITE)
    public ResponseEntity<ApiResponse<RepairDetailResponse>> create(
            @PathVariable Integer repairOrderId,
            @Valid @RequestBody RepairDetailCreateRequest request
    ) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Thêm hạng mục thành công.",
                        repairDetailService.create(repairOrderId, request)));
    }

    @PutMapping("/{type}/{itemId}")
    @PreAuthorize(CAN_WRITE)
    public ResponseEntity<ApiResponse<RepairDetailResponse>> update(
            @PathVariable Integer repairOrderId,
            @PathVariable String type,
            @PathVariable Integer itemId,
            @Valid @RequestBody RepairDetailUpdateRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật hạng mục thành công.",
                repairDetailService.update(repairOrderId, RepairDetailType.fromPath(type), itemId, request)));
    }

    @DeleteMapping("/{type}/{itemId}")
    @PreAuthorize(CAN_WRITE)
    public ResponseEntity<ApiResponse<Void>> delete(
            @PathVariable Integer repairOrderId,
            @PathVariable String type,
            @PathVariable Integer itemId
    ) {
        repairDetailService.delete(repairOrderId, RepairDetailType.fromPath(type), itemId);
        return ResponseEntity.ok(ApiResponse.success("Xóa hạng mục thành công."));
    }
}
