// TV3-TUAN10
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.notification.MaintenanceReminderRequest;
import com.gara.quanlygara.dto.notification.MaintenanceReminderResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.entity.MaintenanceReminder;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.MaintenanceReminderRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Lịch nhắc bảo dưỡng (do nhân viên khai báo ngày và/hoặc số km đến hạn) và việc phát sinh thông báo khi đến hạn.
 * Không tự suy ra chu kỳ bảo dưỡng; không thay đổi Xe, kho hay bất kỳ dữ liệu nghiệp vụ nào ngoài LichNhacBaoDuong/ThongBao.
 */
@Service
public class MaintenanceReminderService {

    private static final Logger log = LoggerFactory.getLogger(MaintenanceReminderService.class);
    private static final String MAINTENANCE_SERVICE_TYPE = "BAO_DUONG";
    private static final int MAX_PAGE_SIZE = 100;
    private static final Set<String> STATUSES = Set.of(
            MaintenanceReminder.PENDING, MaintenanceReminder.REMINDED, MaintenanceReminder.CANCELLED);

    private final MaintenanceReminderRepository repository;
    private final MaintenanceReminderDispatcher dispatcher;

    public MaintenanceReminderService(MaintenanceReminderRepository repository, MaintenanceReminderDispatcher dispatcher) {
        this.repository = repository;
        this.dispatcher = dispatcher;
    }

    @Transactional
    public MaintenanceReminderResponse create(MaintenanceReminderRequest request, Integer staffId) {
        if (request.dueDate() == null && request.dueKm() == null) {
            throw new BadRequestException("Phải nhập ngày đến hạn hoặc số km đến hạn.");
        }
        if (request.dueKm() != null && request.dueKm() < 0) {
            throw new BadRequestException("Số km đến hạn không được âm.");
        }
        if (repository.countVehicle(request.vehicleId()) == 0) {
            throw new ResourceNotFoundException("Không tìm thấy xe.");
        }
        if (request.serviceId() != null) {
            String type = repository.findServiceType(request.serviceId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy dịch vụ."));
            if (!MAINTENANCE_SERVICE_TYPE.equalsIgnoreCase(type)) {
                throw new BadRequestException("Dịch vụ được chọn không thuộc loại bảo dưỡng.");
            }
        }

        MaintenanceReminder reminder = new MaintenanceReminder();
        reminder.setVehicleId(request.vehicleId());
        reminder.setServiceId(request.serviceId());
        reminder.setDueDate(request.dueDate());
        reminder.setDueKm(request.dueKm());
        reminder.setNote(request.note() == null || request.note().isBlank() ? null : request.note().trim());
        reminder.setStatus(MaintenanceReminder.PENDING);
        reminder.setCreatedAt(LocalDateTime.now(MaintenanceReminderDispatcher.ZONE));
        reminder.setCreatedBy(staffId);
        return MaintenanceReminderResponse.from(repository.saveAndFlush(reminder));
    }

    @Transactional(readOnly = true)
    public PageResponse<MaintenanceReminderResponse> getAll(Integer vehicleId, String status, int page, int size) {
        String normalizedStatus = "ALL";
        if (status != null && !status.isBlank() && !status.trim().equalsIgnoreCase("ALL")) {
            normalizedStatus = status.trim().toUpperCase(Locale.ROOT);
            if (!STATUSES.contains(normalizedStatus)) {
                throw new BadRequestException("Trạng thái lịch nhắc không hợp lệ.");
            }
        }
        return PageResponse.of(
                repository.search(vehicleId == null ? 0 : vehicleId, normalizedStatus,
                        PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE))),
                MaintenanceReminderResponse::from);
    }

    /** Hủy lịch chưa nhắc. Hủy lại lịch đã hủy là idempotent; lịch đã nhắc không thể hủy (409). */
    @Transactional
    public MaintenanceReminderResponse cancel(Integer id) {
        if (repository.cancelPending(id) == 1) {
            return MaintenanceReminderResponse.from(find(id));
        }
        MaintenanceReminder reminder = find(id);
        if (MaintenanceReminder.CANCELLED.equals(reminder.getStatus())) {
            return MaintenanceReminderResponse.from(reminder);
        }
        throw new ConflictException("Lịch nhắc đã được gửi thông báo, không thể hủy.");
    }

    /** Điểm vào của scheduler. */
    public int processDue() {
        return processDue(LocalDate.now(MaintenanceReminderDispatcher.ZONE));
    }

    /** Có thể gọi trực tiếp (kể cả trong test) với ngày bất kỳ; an toàn khi gọi lặp nhiều lần. */
    public int processDue(LocalDate today) {
        List<Object[]> rows = repository.findDue(today);
        int created = 0;
        for (Object[] row : rows) {
            MaintenanceReminderDispatcher.DueReminder due = MaintenanceReminderDispatcher.DueReminder.from(row);
            try {
                if (dispatcher.dispatch(due, today)) created++;
            } catch (RuntimeException exception) {
                // Một lịch lỗi không chặn các lịch khác; transaction của lịch đó đã rollback nên lần chạy sau sẽ thử lại.
                log.warn("Không thể tạo thông báo cho lịch nhắc bảo dưỡng #{}: {}", due.reminderId(), exception.toString());
            }
        }
        if (created > 0) log.info("Đã tạo {} thông báo nhắc bảo dưỡng.", created);
        return created;
    }

    private MaintenanceReminder find(Integer id) {
        return repository.findById(id).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy lịch nhắc."));
    }
}
