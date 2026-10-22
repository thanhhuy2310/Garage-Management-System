// TV3-TUAN10
package com.gara.quanlygara.dto.notification;

/** updatedCount: số thông báo vừa được đánh dấu đã đọc; unreadCount: số chưa đọc sau thao tác (luôn 0 nếu không có thông báo mới chen vào). */
public record ReadAllResponse(int updatedCount, long unreadCount) {
}
