// TV3-TUAN10
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.notification.NotificationPageResponse;
import com.gara.quanlygara.dto.notification.NotificationResponse;
import com.gara.quanlygara.dto.notification.ReadAllResponse;
import com.gara.quanlygara.dto.notification.UnreadCountResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.CustomerNotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * Thông báo của CHÍNH khách hàng đang đăng nhập. Không có tham số customerId: khách hàng lấy từ tài khoản trong JWT.
 */
@RestController
@RequestMapping("/api/customers/me/notifications")
@PreAuthorize("hasRole('CUSTOMER')")
public class CustomerNotificationController {

    private final CustomerNotificationService notificationService;
    private final StaffContext accountContext;

    public CustomerNotificationController(CustomerNotificationService notificationService, StaffContext accountContext) {
        this.notificationService = notificationService;
        this.accountContext = accountContext;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<NotificationPageResponse>> getAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication
    ) {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách thông báo thành công.",
                notificationService.getAll(customerId(authentication), page, size)));
    }

    @GetMapping("/unread-count")
    public ResponseEntity<ApiResponse<UnreadCountResponse>> unreadCount(Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.success("Lấy số thông báo chưa đọc thành công.",
                notificationService.unreadCount(customerId(authentication))));
    }

    @PatchMapping("/read-all")
    public ResponseEntity<ApiResponse<ReadAllResponse>> markAllRead(Authentication authentication) {
        return ResponseEntity.ok(ApiResponse.success("Đã đánh dấu tất cả thông báo là đã đọc.",
                notificationService.markAllRead(customerId(authentication))));
    }

    @PatchMapping("/{notificationId}/read")
    public ResponseEntity<ApiResponse<NotificationResponse>> markRead(
            @PathVariable Long notificationId,
            Authentication authentication
    ) {
        return ResponseEntity.ok(ApiResponse.success("Đã đánh dấu thông báo là đã đọc.",
                notificationService.markRead(customerId(authentication), notificationId)));
    }

    private Integer customerId(Authentication authentication) {
        Integer customerId = accountContext.account(authentication).getCustomerId();
        if (customerId == null) {
            throw new AccessDeniedException("Tài khoản chưa liên kết với khách hàng.");
        }
        return customerId;
    }
}
