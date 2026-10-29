package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "HopDongBaoHiem")
public class InsurancePolicy {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaHopDongBaoHiem")
    private Integer id;
    @Column(name = "MaCongTyBaoHiem", nullable = false)
    private Integer companyId;
    @Column(name = "MaXe", nullable = false)
    private Integer vehicleId;
    @Column(name = "MaKhachHang", nullable = false)
    private Integer customerId;
    @Column(name = "SoHopDong", nullable = false, length = 100)
    private String policyNumber;
    @Column(name = "LoaiBaoHiem", nullable = false, length = 30)
    private String insuranceType;
    @Column(name = "NgayBatDau", nullable = false)
    private LocalDate startDate;
    @Column(name = "NgayKetThuc", nullable = false)
    private LocalDate endDate;
    @Column(name = "SoTienBaoHiem", precision = 18, scale = 2)
    private BigDecimal insuredAmount;
    @Column(name = "MucMienThuong", precision = 18, scale = 2)
    private BigDecimal deductible;
    @Column(name = "QuyenChonGara", length = 500)
    private String repairShopTerms;
    @Column(name = "DieuKhoanPhuTung", length = 1000)
    private String partsTerms;
    @Column(name = "ThamChieuChungNhan", length = 500)
    private String certificateReference;
    @Column(name = "TenChuXeTrenDangKy", length = 200)
    private String registeredOwnerName;
    @Column(name = "TenChuXeTrenChungNhan", length = 200)
    private String certificateOwnerName;
    @Column(name = "TrangThaiXacMinh", nullable = false, length = 20)
    private String verificationStatus = "CHUA_XAC_MINH";
    @Column(name = "GhiChuXacMinh", length = 1000)
    private String verificationNote;
    @Column(name = "MaNhanVienXacMinh")
    private Integer verifiedByEmployeeId;
    @Column(name = "NgayXacMinh")
    private LocalDateTime verifiedAt;
    @Column(name = "NgayTao", nullable = false, insertable = false, updatable = false)
    private LocalDateTime createdAt;

    protected InsurancePolicy() {}

    public InsurancePolicy(Integer companyId, Integer vehicleId, Integer customerId, String policyNumber,
                           String insuranceType, LocalDate startDate, LocalDate endDate,
                           BigDecimal insuredAmount, BigDecimal deductible, String repairShopTerms,
                           String partsTerms, String certificateReference,
                           String registeredOwnerName, String certificateOwnerName) {
        this.companyId = companyId;
        this.vehicleId = vehicleId;
        this.customerId = customerId;
        this.policyNumber = policyNumber;
        this.insuranceType = insuranceType;
        this.startDate = startDate;
        this.endDate = endDate;
        this.insuredAmount = insuredAmount;
        this.deductible = deductible;
        this.repairShopTerms = repairShopTerms;
        this.partsTerms = partsTerms;
        this.certificateReference = certificateReference;
        this.registeredOwnerName = registeredOwnerName;
        this.certificateOwnerName = certificateOwnerName;
    }

    public void verify(String status, String note, Integer employeeId, LocalDateTime time) {
        this.verificationStatus = status;
        this.verificationNote = note;
        this.verifiedByEmployeeId = employeeId;
        this.verifiedAt = time;
    }

    public Integer getId() { return id; }
    public Integer getCompanyId() { return companyId; }
    public Integer getVehicleId() { return vehicleId; }
    public Integer getCustomerId() { return customerId; }
    public String getPolicyNumber() { return policyNumber; }
    public String getInsuranceType() { return insuranceType; }
    public LocalDate getStartDate() { return startDate; }
    public LocalDate getEndDate() { return endDate; }
    public BigDecimal getInsuredAmount() { return insuredAmount; }
    public BigDecimal getDeductible() { return deductible; }
    public String getRepairShopTerms() { return repairShopTerms; }
    public String getPartsTerms() { return partsTerms; }
    public String getCertificateReference() { return certificateReference; }
    public String getRegisteredOwnerName() { return registeredOwnerName; }
    public String getCertificateOwnerName() { return certificateOwnerName; }
    public String getVerificationStatus() { return verificationStatus; }
    public String getVerificationNote() { return verificationNote; }
    public Integer getVerifiedByEmployeeId() { return verifiedByEmployeeId; }
    public LocalDateTime getVerifiedAt() { return verifiedAt; }
    public LocalDateTime getCreatedAt() { return createdAt; }
}
