// TV3-TUAN10
package com.gara.quanlygara.dto.notification;

import java.util.List;

/** page bắt đầu từ 0. totalElements là tổng số thông báo của khách hàng (không bị cắt). */
public record NotificationPageResponse(
        List<NotificationResponse> items,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
}
