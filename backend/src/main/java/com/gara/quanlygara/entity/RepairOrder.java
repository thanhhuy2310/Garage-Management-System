package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "PhieuSuaChua")
public class RepairOrder {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaPhieuSuaChua")
    private Integer id;

    @Column(name = "MaTiepNhan", nullable = false, unique = true)
    private Integer receptionId;

    @Column(name = "NgayLap", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "NgayBatDau")
    private LocalDateTime startedAt;

    @Column(name = "NgayHoanThanh")
    private LocalDateTime completedAt;

    @Column(name = "TrangThai", nullable = false, length = 50)
    private String status;

    @Column(name = "KetQua", length = 1000)
    private String result;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public Integer getReceptionId() { return receptionId; }
    public void setReceptionId(Integer receptionId) { this.receptionId = receptionId; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
    public LocalDateTime getStartedAt() { return startedAt; }
    public void setStartedAt(LocalDateTime startedAt) { this.startedAt = startedAt; }
    public LocalDateTime getCompletedAt() { return completedAt; }
    public void setCompletedAt(LocalDateTime completedAt) { this.completedAt = completedAt; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getResult() { return result; }
    public void setResult(String result) { this.result = result; }
}
