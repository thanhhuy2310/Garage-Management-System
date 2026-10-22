// TV3-TUAN10
package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.CustomerNotification;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface CustomerNotificationRepository extends JpaRepository<CustomerNotification, Long> {

    Page<CustomerNotification> findByCustomerIdOrderByCreatedAtDescIdDesc(Integer customerId, Pageable pageable);

    long countByCustomerIdAndReadFalse(Integer customerId);

    Optional<CustomerNotification> findByIdAndCustomerId(Long id, Integer customerId);

    // Cập nhật có điều kiện sở hữu ngay trong câu UPDATE: thông báo của người khác không bao giờ bị đổi.
    // Trả về số dòng khớp (1 kể cả khi đã đọc từ trước => thao tác idempotent; 0 = không tồn tại hoặc không thuộc khách hàng).
    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = "UPDATE ThongBao SET DaDoc = 1 WHERE MaThongBao = :id AND MaKhachHang = :customerId", nativeQuery = true)
    int markRead(@Param("id") Long id, @Param("customerId") Integer customerId);

    @Modifying(flushAutomatically = true, clearAutomatically = true)
    @Query(value = "UPDATE ThongBao SET DaDoc = 1 WHERE MaKhachHang = :customerId AND DaDoc = 0", nativeQuery = true)
    int markAllRead(@Param("customerId") Integer customerId);
}
