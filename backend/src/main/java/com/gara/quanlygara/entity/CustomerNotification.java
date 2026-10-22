// TV3-TUAN10
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/**
 * Thông báo gửi khách hàng: bảng ThongBao (dùng lại bảng có sẵn, không tạo bảng thông báo thứ hai).
 * MaLichNhac (migration V004) liên kết thông báo nhắc bảo dưỡng với lịch nhắc; chỉ mục duy nhất trên cột này
 * bảo đảm mỗi lịch nhắc chỉ sinh đúng một thông báo.
 */
@Entity
@Table(name = "ThongBao")
public class CustomerNotification {

    public static final String TYPE_APPOINTMENT = "LICH_HEN";
    public static final String TYPE_REPAIR_PROGRESS = "TIEN_DO_SUA_CHUA";
    public static final String TYPE_REPAIR_DONE = "HOAN_TAT_SUA_CHUA";
    public static final String TYPE_MAINTENANCE = "NHAC_BAO_DUONG";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaThongBao")
    private Long id;

    @Column(name = "MaKhachHang", nullable = false)
    private Integer customerId;

    @Column(name = "MaLichHen")
    private Integer appointmentId;

    @Column(name = "MaPhieuSuaChua")
    private Integer repairOrderId;

    @Column(name = "MaLichNhac")
    private Integer maintenanceReminderId;

    @Column(name = "LoaiThongBao", nullable = false, length = 50)
    private String typeCode;

    @Column(name = "TieuDe", nullable = false, length = 200)
    private String title;

    @Column(name = "NoiDung", nullable = false, length = 1000)
    private String message;

    @Column(name = "ThoiGian", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "DaDoc", nullable = false)
    private boolean read;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Integer getCustomerId() { return customerId; }
    public void setCustomerId(Integer customerId) { this.customerId = customerId; }
    public Integer getAppointmentId() { return appointmentId; }
    public void setAppointmentId(Integer appointmentId) { this.appointmentId = appointmentId; }
    public Integer getRepairOrderId() { return repairOrderId; }
    public void setRepairOrderId(Integer repairOrderId) { this.repairOrderId = repairOrderId; }
    public Integer getMaintenanceReminderId() { return maintenanceReminderId; }
    public void setMaintenanceReminderId(Integer maintenanceReminderId) { this.maintenanceReminderId = maintenanceReminderId; }
    public String getTypeCode() { return typeCode; }
    public void setTypeCode(String typeCode) { this.typeCode = typeCode; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public boolean isRead() { return read; }
    public void setRead(boolean read) { this.read = read; }
}
