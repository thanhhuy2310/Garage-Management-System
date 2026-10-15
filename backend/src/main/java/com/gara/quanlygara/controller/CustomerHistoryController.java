// TV3-TUAN9
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.history.HistoryDetailResponse;
import com.gara.quanlygara.dto.history.HistoryItemResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.RepairHistoryService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * Lịch sử sửa chữa/bảo dưỡng của CHÍNH khách hàng đang đăng nhập. Không có tham số customerId:
 * khách hàng lấy từ tài khoản trong JWT, nên không thể xem dữ liệu của khách hàng khác.
 */
@RestController
@RequestMapping("/api/customers/me/history")
@PreAuthorize("hasRole('CUSTOMER')")
public class CustomerHistoryController {

    private final RepairHistoryService historyService;
    private final StaffContext accountContext;

    public CustomerHistoryController(RepairHistoryService historyService, StaffContext accountContext) {
        this.historyService = historyService;
        this.accountContext = accountContext;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<HistoryItemResponse>>> getHistory(
            @RequestParam(required = false) Integer vehicleId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy lịch sử sửa chữa thành công.",
                historyService.getHistory(customerId(authentication), vehicleId)));
    }

    @GetMapping("/{repairOrderId}")
    public ResponseEntity<ApiResponse<HistoryDetailResponse>> getDetail(
            @PathVariable Integer repairOrderId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy chi tiết lịch sử sửa chữa thành công.",
                historyService.getDetail(customerId(authentication), repairOrderId)));
    }

    private Integer customerId(Authentication authentication) {
        Integer customerId = accountContext.account(authentication).getCustomerId();
        if (customerId == null) {
            throw new AccessDeniedException("Tài khoản chưa liên kết với khách hàng.");
        }
        return customerId;
    }
}
