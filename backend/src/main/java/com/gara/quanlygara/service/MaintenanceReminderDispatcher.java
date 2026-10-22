// TV3-TUAN10
package com.gara.quanlygara.service;

import com.gara.quanlygara.entity.CustomerNotification;
import com.gara.quanlygara.repository.CustomerNotificationRepository;
import com.gara.quanlygara.repository.MaintenanceReminderRepository;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;

/**
 * Xử lý MỘT lịch nhắc đến hạn trong transaction riêng: giành quyền (CHO_NHAC -> DA_NHAC) rồi tạo đúng một thông báo.
 * Cả hai thay đổi cùng commit hoặc cùng rollback. Chống trùng bằng ba lớp: UPDATE có điều kiện trạng thái (một lượt thắng),
 * trạng thái DA_NHAC (job chạy lại/khởi động lại không chọn lại) và chỉ mục duy nhất ThongBao.MaLichNhac.
 */
@Component
public class MaintenanceReminderDispatcher {

    static final ZoneId ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter DATE = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    public record DueReminder(
            int reminderId, int vehicleId, int customerId, String plate,
            LocalDate dueDate, Integer dueKm, Integer currentKm, String note, String serviceName
    ) {
        static DueReminder from(Object[] row) {
            return new DueReminder(
                    ((Number) row[0]).intValue(), ((Number) row[1]).intValue(), ((Number) row[2]).intValue(),
                    row[3] == null ? "" : row[3].toString(), toDate(row[4]),
                    row[5] == null ? null : ((Number) row[5]).intValue(),
                    row[6] == null ? null : ((Number) row[6]).intValue(),
                    row[7] == null ? "" : row[7].toString(), row[8] == null ? "" : row[8].toString());
        }

        private static LocalDate toDate(Object value) {
            if (value == null) return null;
            if (value instanceof LocalDate date) return date;
            if (value instanceof java.sql.Date date) return date.toLocalDate();
            if (value instanceof java.sql.Timestamp timestamp) return timestamp.toLocalDateTime().toLocalDate();
            return LocalDate.parse(value.toString().substring(0, 10));
        }
    }

    private final MaintenanceReminderRepository reminderRepository;
    private final CustomerNotificationRepository notificationRepository;

    public MaintenanceReminderDispatcher(
            MaintenanceReminderRepository reminderRepository,
            CustomerNotificationRepository notificationRepository
    ) {
        this.reminderRepository = reminderRepository;
        this.notificationRepository = notificationRepository;
    }

    /** @return true nếu lượt này đã tạo thông báo; false nếu lịch đã được nhắc/hủy hoặc lượt khác đã xử lý. */
    @Transactional
    public boolean dispatch(DueReminder due, LocalDate today) {
        if (reminderRepository.claim(due.reminderId()) == 0) {
            return false;
        }
        CustomerNotification notification = new CustomerNotification();
        notification.setCustomerId(due.customerId());
        notification.setMaintenanceReminderId(due.reminderId());
        notification.setTypeCode(CustomerNotification.TYPE_MAINTENANCE);
        notification.setTitle("Đến hạn bảo dưỡng xe " + due.plate());
        notification.setMessage(message(due, today));
        notification.setCreatedAt(LocalDateTime.now(ZONE));
        notification.setRead(false);
        notificationRepository.saveAndFlush(notification);
        return true;
    }

    static String message(DueReminder due, LocalDate today) {
        List<String> reasons = new ArrayList<>();
        if (due.dueDate() != null && !due.dueDate().isAfter(today)) {
            reasons.add("đã đến hạn bảo dưỡng theo lịch (ngày " + DATE.format(due.dueDate()) + ")");
        }
        if (due.dueKm() != null && due.currentKm() != null && due.currentKm() >= due.dueKm()) {
            reasons.add("đã đạt " + due.currentKm() + " km (mốc bảo dưỡng " + due.dueKm() + " km)");
        }
        StringBuilder text = new StringBuilder("Xe ").append(due.plate()).append(' ')
                .append(String.join("; ", reasons)).append('.');
        if (!due.serviceName().isBlank()) text.append(" Dịch vụ: ").append(due.serviceName()).append('.');
        if (!due.note().isBlank()) text.append(" Ghi chú: ").append(due.note()).append('.');
        text.append(" Vui lòng đặt lịch bảo dưỡng.");
        return text.toString();
    }
}
