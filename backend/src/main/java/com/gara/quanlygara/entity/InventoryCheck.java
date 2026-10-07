// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** Phiên kiểm kê: bảng PhieuKiemKe (migration V002). */
@Entity
@Table(name = "PhieuKiemKe")
public class InventoryCheck {

    public static final String COUNTING = "DANG_KIEM_KE";
    public static final String PENDING_APPROVAL = "CHO_PHE_DUYET";
    public static final String COMPLETED = "DA_HOAN_TAT";
    public static final String REJECTED = "DA_TU_CHOI";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaPhieuKiemKe")
    private Integer id;

    @Column(name = "NgayKiemKe", nullable = false)
    private LocalDateTime checkDate;

    @Column(name = "MaNhanVienKiemKe", nullable = false)
    private Integer createdBy;

    @Column(name = "MaNhanVienDuyet")
    private Integer approvedBy;

    @Column(name = "NgayDuyet")
    private LocalDateTime approvedAt;

    @Column(name = "TrangThai", nullable = false, length = 30)
    private String status;

    @Column(name = "GhiChu", length = 500)
    private String note;

    @Column(name = "LyDoDuyet", length = 500)
    private String decisionReason;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public LocalDateTime getCheckDate() { return checkDate; }
    public void setCheckDate(LocalDateTime checkDate) { this.checkDate = checkDate; }
    public Integer getCreatedBy() { return createdBy; }
    public void setCreatedBy(Integer createdBy) { this.createdBy = createdBy; }
    public Integer getApprovedBy() { return approvedBy; }
    public void setApprovedBy(Integer approvedBy) { this.approvedBy = approvedBy; }
    public LocalDateTime getApprovedAt() { return approvedAt; }
    public void setApprovedAt(LocalDateTime approvedAt) { this.approvedAt = approvedAt; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
    public String getDecisionReason() { return decisionReason; }
    public void setDecisionReason(String decisionReason) { this.decisionReason = decisionReason; }
}
