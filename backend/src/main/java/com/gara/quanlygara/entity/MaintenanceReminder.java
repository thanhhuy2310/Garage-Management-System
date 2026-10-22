// TV3-TUAN10
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDate;
import java.time.LocalDateTime;

/**
 * Lịch nhắc bảo dưỡng đến hạn của một xe: bảng LichNhacBaoDuong (migration V004).
 * Đây là nguồn dữ liệu đến hạn do nhân viên khai báo (ngày và/hoặc số km); hệ thống KHÔNG tự suy ra chu kỳ bảo dưỡng.
 * Thông báo gửi khách hàng vẫn lưu ở ThongBao.
 */
@Entity
@Table(name = "LichNhacBaoDuong")
public class MaintenanceReminder {

    public static final String PENDING = "CHO_NHAC";
    public static final String REMINDED = "DA_NHAC";
    public static final String CANCELLED = "DA_HUY";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaLichNhac")
    private Integer id;

    @Column(name = "MaXe", nullable = false)
    private Integer vehicleId;

    @Column(name = "MaDichVu")
    private Integer serviceId;

    @Column(name = "NgayDenHan")
    private LocalDate dueDate;

    @Column(name = "SoKmDenHan")
    private Integer dueKm;

    @Column(name = "GhiChu", length = 500)
    private String note;

    @Column(name = "TrangThai", nullable = false, length = 20)
    private String status;

    @Column(name = "NgayTao", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "MaNhanVienTao")
    private Integer createdBy;

    @Column(name = "NgayNhac")
    private LocalDateTime remindedAt;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public Integer getVehicleId() { return vehicleId; }
    public void setVehicleId(Integer vehicleId) { this.vehicleId = vehicleId; }
    public Integer getServiceId() { return serviceId; }
    public void setServiceId(Integer serviceId) { this.serviceId = serviceId; }
    public LocalDate getDueDate() { return dueDate; }
    public void setDueDate(LocalDate dueDate) { this.dueDate = dueDate; }
    public Integer getDueKm() { return dueKm; }
    public void setDueKm(Integer dueKm) { this.dueKm = dueKm; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public Integer getCreatedBy() { return createdBy; }
    public void setCreatedBy(Integer createdBy) { this.createdBy = createdBy; }
    public LocalDateTime getRemindedAt() { return remindedAt; }
    public void setRemindedAt(LocalDateTime remindedAt) { this.remindedAt = remindedAt; }
}
