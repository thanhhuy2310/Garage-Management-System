package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.LocalDateTime;

@Entity
@Table(name = "HoSoBaoHiem")
public class InsuranceClaim {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaHoSoBaoHiem")
    private Integer id;
    @Column(name = "MaHoSo", nullable = false, length = 40, unique = true)
    private String code;
    @Column(name = "MaHoSoCongTy", length = 100)
    private String insurerClaimNumber;
    @Column(name = "MaCongTyBaoHiem", nullable = false)
    private Integer companyId;
    @Column(name = "MaHopDongBaoHiem", nullable = false)
    private Integer policyId;
    @Column(name = "MaTiepNhan", nullable = false, unique = true)
    private Integer receptionId;
    @Column(name = "MaXe", nullable = false)
    private Integer vehicleId;
    @Column(name = "MaKhachHang", nullable = false)
    private Integer customerId;
    @Column(name = "ThoiDiemSuCo", nullable = false)
    private LocalDateTime incidentAt;
    @Column(name = "DiaDiemSuCo", nullable = false, length = 255)
    private String incidentLocation;
    @Column(name = "MoTaNguyenNhan", nullable = false, length = 1000)
    private String causeDescription;
    @Column(name = "MoTaTonThat", nullable = false, length = 2000)
    private String damageDescription;
    @Column(name = "NgayThongBao")
    private LocalDateTime notifiedAt;
    @Column(name = "GiamDinhVien", length = 150)
    private String assessorName;
    @Column(name = "LienHeGiamDinh", length = 150)
    private String assessorContact;
    @Column(name = "TrangThai", nullable = false, length = 30)
    private String status = "MOI_TAO";
    @Column(name = "MaNhanVienTao", nullable = false)
    private Integer createdByEmployeeId;
    @Column(name = "NgayTao", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    protected InsuranceClaim() {}

    public InsuranceClaim(String code, String insurerClaimNumber, Integer companyId, Integer policyId,
                          Integer receptionId, Integer vehicleId, Integer customerId, LocalDateTime incidentAt,
                          String incidentLocation, String causeDescription, String damageDescription,
                          LocalDateTime notifiedAt, String assessorName, String assessorContact,
                          Integer createdByEmployeeId) {
        this.code = code;
        this.insurerClaimNumber = insurerClaimNumber;
        this.companyId = companyId;
        this.policyId = policyId;
        this.receptionId = receptionId;
        this.vehicleId = vehicleId;
        this.customerId = customerId;
        this.incidentAt = incidentAt;
        this.incidentLocation = incidentLocation;
        this.causeDescription = causeDescription;
        this.damageDescription = damageDescription;
        this.notifiedAt = notifiedAt;
        this.assessorName = assessorName;
        this.assessorContact = assessorContact;
        this.createdByEmployeeId = createdByEmployeeId;
        this.createdAt = LocalDateTime.now();
    }

    public Integer getId() { return id; }
    public String getCode() { return code; }
    public String getInsurerClaimNumber() { return insurerClaimNumber; }
    public Integer getCompanyId() { return companyId; }
    public Integer getPolicyId() { return policyId; }
    public Integer getReceptionId() { return receptionId; }
    public Integer getVehicleId() { return vehicleId; }
    public Integer getCustomerId() { return customerId; }
    public LocalDateTime getIncidentAt() { return incidentAt; }
    public String getIncidentLocation() { return incidentLocation; }
    public String getCauseDescription() { return causeDescription; }
    public String getDamageDescription() { return damageDescription; }
    public LocalDateTime getNotifiedAt() { return notifiedAt; }
    public String getAssessorName() { return assessorName; }
    public String getAssessorContact() { return assessorContact; }
    public String getStatus() { return status; }
    public Integer getCreatedByEmployeeId() { return createdByEmployeeId; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
