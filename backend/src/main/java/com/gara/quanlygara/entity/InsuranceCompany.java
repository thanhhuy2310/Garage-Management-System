package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "CongTyBaoHiem")
public class InsuranceCompany {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaCongTyBaoHiem")
    private Integer id;
    @Column(name = "MaCongTy", nullable = false, length = 30, unique = true)
    private String code;
    @Column(name = "TenCongTy", nullable = false, length = 200)
    private String name;
    @Column(name = "SoDienThoai", length = 30)
    private String phone;
    @Column(name = "Email", length = 150)
    private String email;
    @Column(name = "DiaChi", length = 255)
    private String address;
    @Column(name = "DauMoiGiamDinh", length = 150)
    private String assessorName;
    @Column(name = "LienHeGiamDinh", length = 150)
    private String assessorContact;
    @Column(name = "DangHopTac", nullable = false)
    private boolean active = true;

    protected InsuranceCompany() {}

    public InsuranceCompany(String code, String name, String phone, String email, String address,
                            String assessorName, String assessorContact, boolean active) {
        update(code, name, phone, email, address, assessorName, assessorContact, active);
    }

    public void update(String code, String name, String phone, String email, String address,
                       String assessorName, String assessorContact, boolean active) {
        this.code = code;
        this.name = name;
        this.phone = phone;
        this.email = email;
        this.address = address;
        this.assessorName = assessorName;
        this.assessorContact = assessorContact;
        this.active = active;
    }

    public Integer getId() { return id; }
    public String getCode() { return code; }
    public String getName() { return name; }
    public String getPhone() { return phone; }
    public String getEmail() { return email; }
    public String getAddress() { return address; }
    public String getAssessorName() { return assessorName; }
    public String getAssessorContact() { return assessorContact; }
    public boolean isActive() { return active; }
}
