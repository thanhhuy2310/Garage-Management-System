// TV3-TUAN10
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.notification.NotificationPageResponse;
import com.gara.quanlygara.dto.notification.NotificationResponse;
import com.gara.quanlygara.dto.notification.ReadAllResponse;
import com.gara.quanlygara.dto.notification.UnreadCountResponse;
import com.gara.quanlygara.entity.CustomerNotification;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.CustomerNotificationRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Thông báo của khách hàng đăng nhập. customerId luôn do controller lấy từ JWT, không nhận từ client;
 * đánh dấu đã đọc luôn kiểm tra đồng thời mã thông báo và khách hàng sở hữu.
 * Service này chỉ đọc/đánh dấu đã đọc ThongBao: không thay đổi dữ liệu nghiệp vụ nào khác.
 */
@Service
public class CustomerNotificationService {

    public static final int MAX_PAGE_SIZE = 100;

    private final CustomerNotificationRepository repository;

    public CustomerNotificationService(CustomerNotificationRepository repository) {
        this.repository = repository;
    }

    @Transactional(readOnly = true)
    public NotificationPageResponse getAll(Integer customerId, int page, int size) {
        Page<CustomerNotification> result = repository.findByCustomerIdOrderByCreatedAtDescIdDesc(
                customerId, PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE)));
        return new NotificationPageResponse(
                result.getContent().stream().map(NotificationResponse::from).toList(),
                result.getNumber(), result.getSize(), result.getTotalElements(), result.getTotalPages());
    }

    @Transactional(readOnly = true)
    public UnreadCountResponse unreadCount(Integer customerId) {
        return new UnreadCountResponse(repository.countByCustomerIdAndReadFalse(customerId));
    }

    /** Không tồn tại và không thuộc khách hàng hiện tại đều trả 404 giống nhau (không lộ dữ liệu người khác). */
    @Transactional
    public NotificationResponse markRead(Integer customerId, Long notificationId) {
        if (repository.markRead(notificationId, customerId) == 0) {
            throw new ResourceNotFoundException("Không tìm thấy thông báo.");
        }
        return repository.findByIdAndCustomerId(notificationId, customerId)
                .map(NotificationResponse::from)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thông báo."));
    }

    @Transactional
    public ReadAllResponse markAllRead(Integer customerId) {
        int updated = repository.markAllRead(customerId);
        return new ReadAllResponse(updated, repository.countByCustomerIdAndReadFalse(customerId));
    }
}
