package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

/** Phiếu tiếp nhận dùng chung cho sửa chữa và liên kết hồ sơ bảo hiểm. */
@Entity
@Table(name = "PhieuTiepNhan")
public class InsuranceReception {
    @Id
    @jakarta.persistence.GeneratedValue(strategy = jakarta.persistence.GenerationType.IDENTITY)
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

    @Column(name = "MaLichHen")
    private Integer appointmentId;
    @Column(name = "SoKmTiepNhan")
    private Integer mileage;
    @Column(name = "MaNhanVienTiepNhan")
    private Integer receivedBy;
    @Column(name = "NgayCapNhat")
    private LocalDateTime updatedAt;
    @jakarta.persistence.Version
    @org.hibernate.annotations.ColumnDefault("0")
    @Column(name = "PhienBan", nullable = false)
    private int version;

    public InsuranceReception() {}

    public InsuranceReception(Integer id, Integer vehicleId) {
        this.id = id;
        this.vehicleId = vehicleId;
    }

    public Integer getId() { return id; }
    public Integer getVehicleId() { return vehicleId; }

    public LocalDateTime getReceivedAt() { return receivedAt; }
    public String getInitialCondition() { return initialCondition; }
    public String getCustomerRequest() { return customerRequest; }
    public String getNotes() { return notes; }
    public Integer getAppointmentId() { return appointmentId; }
    public Integer getMileage() { return mileage; }
    public Integer getReceivedBy() { return receivedBy; }
    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public int getVersion() { return version; }
    public void setVehicleId(Integer value) { vehicleId = value; }
    public void setReceivedAt(LocalDateTime value) { receivedAt = value; }
    public void setInitialCondition(String value) { initialCondition = value; }
    public void setCustomerRequest(String value) { customerRequest = value; }
    public void setNotes(String value) { notes = value; }
    public void setAppointmentId(Integer value) { appointmentId = value; }
    public void setMileage(Integer value) { mileage = value; }
    public void setReceivedBy(Integer value) { receivedBy = value; }
    public void setUpdatedAt(LocalDateTime value) { updatedAt = value; }
}
