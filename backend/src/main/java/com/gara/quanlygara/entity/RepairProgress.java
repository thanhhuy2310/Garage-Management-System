package com.gara.quanlygara.entity;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "NhatKySuaChua")
public class RepairProgress {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaNhatKy")
    private Long id;
    @Column(name = "MaPhieuSuaChua", nullable = false)
    private Integer repairOrderId;
    @Column(name = "MaDichVu")
    private Integer serviceId;
    @Column(name = "TrangThai", nullable = false, length = 50)
    private String status;
    @Column(name = "NoiDung", nullable = false, length = 1000)
    private String notes;
    @Column(name = "NguoiCapNhat", nullable = false, length = 100)
    private String updatedBy;
    @Column(name = "ThoiGian", nullable = false)
    private LocalDateTime createdAt;

    protected RepairProgress() { }
    public RepairProgress(Integer orderId, Integer serviceId, String status, String notes,
                          String updatedBy, LocalDateTime createdAt) {
        this.repairOrderId = orderId;
        this.serviceId = serviceId;
        this.status = status;
        this.notes = notes;
        this.updatedBy = updatedBy;
        this.createdAt = createdAt;
    }
    public Long getId() { return id; }
    public Integer getRepairOrderId() { return repairOrderId; }
    public Integer getServiceId() { return serviceId; }
    public String getStatus() { return status; }
    public String getNotes() { return notes; }
    public String getUpdatedBy() { return updatedBy; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
