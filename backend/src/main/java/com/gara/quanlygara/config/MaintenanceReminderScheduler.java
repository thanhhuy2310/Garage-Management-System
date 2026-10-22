// TV3-TUAN10
package com.gara.quanlygara.config;

import com.gara.quanlygara.service.MaintenanceReminderService;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.scheduling.annotation.Scheduled;

/**
 * Chạy hằng ngày (mặc định 07:00, múi giờ Asia/Ho_Chi_Minh) để tạo thông báo cho lịch bảo dưỡng đến hạn.
 * Cấu hình: app.reminders.enabled (mặc định true), app.reminders.cron (mặc định "0 0 7 * * *").
 * Logic nằm ở MaintenanceReminderService.processDue(...) nên test gọi trực tiếp, không cần chờ giờ thật.
 */
@Configuration
@EnableScheduling
@ConditionalOnProperty(name = "app.reminders.enabled", havingValue = "true", matchIfMissing = true)
public class MaintenanceReminderScheduler {

    private final MaintenanceReminderService service;

    public MaintenanceReminderScheduler(MaintenanceReminderService service) {
        this.service = service;
    }

    @Scheduled(cron = "${app.reminders.cron:0 0 7 * * *}", zone = "Asia/Ho_Chi_Minh")
    public void sendDueReminders() {
        service.processDue();
    }
}
