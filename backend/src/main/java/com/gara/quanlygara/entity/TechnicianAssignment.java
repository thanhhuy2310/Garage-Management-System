package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.EmbeddedId;
import jakarta.persistence.Entity;
import jakarta.persistence.PostLoad;
import jakarta.persistence.PostPersist;
import jakarta.persistence.Table;
import jakarta.persistence.Transient;
import org.springframework.data.domain.Persistable;

import java.time.LocalDateTime;

@Entity
@Table(name = "PhanCongKyThuatVien")
public class TechnicianAssignment implements Persistable<TechnicianAssignmentId> {

    @EmbeddedId
    private TechnicianAssignmentId id;

    @Column(name = "NgayPhanCong", nullable = false)
    private LocalDateTime assignedAt;

    @Column(name = "GhiChu", length = 500)
    private String notes;

    // Khóa ghép được gán trước khi save: phải INSERT, không merge đè phân công đã có.
    @Transient
    private boolean newAssignment = true;

    @Override
    public TechnicianAssignmentId getId() { return id; }
    public void setId(TechnicianAssignmentId id) { this.id = id; }
    public LocalDateTime getAssignedAt() { return assignedAt; }
    public void setAssignedAt(LocalDateTime assignedAt) { this.assignedAt = assignedAt; }
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }

    @Override
    public boolean isNew() { return newAssignment; }

    @PostLoad
    @PostPersist
    private void markPersisted() {
        newAssignment = false;
    }
}
