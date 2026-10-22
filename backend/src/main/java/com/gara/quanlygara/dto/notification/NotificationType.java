// TV3-TUAN10
package com.gara.quanlygara.dto.notification;

/** Giá trị type của API, suy ra từ ThongBao.LoaiThongBao (xem backend/docs/API_NOTIFICATIONS.md). */
public enum NotificationType {
    APPOINTMENT("appointment"),
    REPAIR("repair"),
    MAINTENANCE("maintenance"),
    GENERAL("general");

    private final String apiValue;

    NotificationType(String apiValue) {
        this.apiValue = apiValue;
    }

    public String apiValue() {
        return apiValue;
    }

    public static NotificationType fromCode(String code) {
        if (code == null) return GENERAL;
        return switch (code.trim().toUpperCase()) {
            case "LICH_HEN" -> APPOINTMENT;
            case "TIEN_DO_SUA_CHUA", "HOAN_TAT_SUA_CHUA" -> REPAIR;
            case "NHAC_BAO_DUONG" -> MAINTENANCE;
            default -> GENERAL;
        };
    }
}
