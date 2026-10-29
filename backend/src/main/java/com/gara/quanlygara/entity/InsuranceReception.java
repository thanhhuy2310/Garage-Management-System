package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

/** Chỉ ánh xạ các cột phiếu tiếp nhận cần để kiểm tra hồ sơ bảo hiểm. */
@Entity
@Table(name = "PhieuTiepNhan")
public class InsuranceReception {
    @Id
    @Column(name = "MaTiepNhan")
    private Integer id;

    @Column(name = "MaXe", nullable = false)
    private Integer vehicleId;

    // H2 integration tests build the reception table from JPA metadata.
    @Column(name = "NgayTiepNhan")
    private LocalDateTime receivedAt;
    @Column(name = "TinhTrangBanDau", length = 1000)
    private String initialCondition;
    @Column(name = "YeuCauKhachHang", length = 1000)
    private String customerRequest;
    @Column(name = "GhiChu", length = 1000)
    private String notes;

    protected InsuranceReception() {}

    public InsuranceReception(Integer id, Integer vehicleId) {
        this.id = id;
        this.vehicleId = vehicleId;
    }

    public Integer getId() { return id; }
    public Integer getVehicleId() { return vehicleId; }
}
