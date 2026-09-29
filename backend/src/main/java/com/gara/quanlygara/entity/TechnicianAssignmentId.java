package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class TechnicianAssignmentId implements Serializable {

    @Column(name = "MaPhieuSuaChua", nullable = false)
    private Integer repairOrderId;

    @Column(name = "MaKyThuatVien", nullable = false)
    private Integer technicianId;

    public TechnicianAssignmentId() {
    }

    public TechnicianAssignmentId(Integer repairOrderId, Integer technicianId) {
        this.repairOrderId = repairOrderId;
        this.technicianId = technicianId;
    }

    public Integer getRepairOrderId() { return repairOrderId; }
    public Integer getTechnicianId() { return technicianId; }

    @Override
    public boolean equals(Object other) {
        if (this == other) return true;
        if (!(other instanceof TechnicianAssignmentId that)) return false;
        return Objects.equals(repairOrderId, that.repairOrderId)
                && Objects.equals(technicianId, that.technicianId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(repairOrderId, technicianId);
    }
}
