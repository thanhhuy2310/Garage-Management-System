package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "NhatKyHoSoBaoHiem")
public class InsuranceClaimEvent {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaNhatKy")
    private Long id;
    @Column(name = "MaHoSoBaoHiem", nullable = false)
    private Integer claimId;
    @Column(name = "MaNhanVien", nullable = false)
    private Integer employeeId;
    @Column(name = "HanhDong", nullable = false, length = 50)
    private String action;
    @Column(name = "TrangThaiTruoc", length = 30)
    private String previousStatus;
    @Column(name = "TrangThaiSau", nullable = false, length = 30)
    private String nextStatus;
    @Column(name = "GhiChu", length = 1000)
    private String note;
    @Column(name = "ThoiGian", nullable = false, updatable = false)
    private LocalDateTime occurredAt;

    protected InsuranceClaimEvent() {}

    public InsuranceClaimEvent(Integer claimId, Integer employeeId, String action,
                               String previousStatus, String nextStatus, String note) {
        this.claimId = claimId;
        this.employeeId = employeeId;
        this.action = action;
        this.previousStatus = previousStatus;
        this.nextStatus = nextStatus;
        this.note = note;
        this.occurredAt = LocalDateTime.now();
    }

    public Long getId() { return id; }
    public Integer getClaimId() { return claimId; }
    public Integer getEmployeeId() { return employeeId; }
    public String getAction() { return action; }
    public String getPreviousStatus() { return previousStatus; }
    public String getNextStatus() { return nextStatus; }
    public String getNote() { return note; }
    public LocalDateTime getOccurredAt() { return occurredAt; }
}
