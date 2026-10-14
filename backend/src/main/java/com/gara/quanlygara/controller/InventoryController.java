// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.warehouse.InventoryPageResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.dto.warehouse.StockMovementResponse;
import com.gara.quanlygara.service.InventoryService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/inventory")
@PreAuthorize("hasAnyRole('ADMIN', 'MANAGER', 'WAREHOUSE')")
public class InventoryController {

    private final InventoryService inventoryService;

    public InventoryController(InventoryService inventoryService) {
        this.inventoryService = inventoryService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<InventoryPageResponse>> getStock(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String search,
            @RequestParam(required = false) String status
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy tồn kho thành công.",
                inventoryService.getStock(page, size, search, status)));
    }

    @GetMapping("/movements")
    public ResponseEntity<ApiResponse<PageResponse<StockMovementResponse>>> getMovements(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) Integer partId,
            @RequestParam(required = false) String type
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy lịch sử biến động kho thành công.",
                inventoryService.getMovements(page, size, partId, type)));
    }
}
