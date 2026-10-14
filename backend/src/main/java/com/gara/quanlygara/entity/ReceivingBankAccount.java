package com.gara.quanlygara.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "TaiKhoanNganHangGara", uniqueConstraints = @UniqueConstraint(columnNames = {"MaNganHang", "SoTaiKhoan"}))
public class ReceivingBankAccount {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaTaiKhoan") private Integer id;
    @Column(name = "TenNganHang", nullable = false, length = 100) private String name;
    @Column(name = "MaNganHang", nullable = false, length = 6) private String bin;
    @Column(name = "SoTaiKhoan", nullable = false, length = 25) private String account;
    @Column(name = "ChuTaiKhoan", nullable = false, length = 100) private String accountName;
    @Column(name = "DangSuDung", nullable = false) private boolean active = true;
    public Integer getId() { return id; }
    public String getName() { return name; }
    public void setName(String value) { name = value; }
    public String getBin() { return bin; }
    public void setBin(String value) { bin = value; }
    public String getAccount() { return account; }
    public void setAccount(String value) { account = value; }
    public String getAccountName() { return accountName; }
    public void setAccountName(String value) { accountName = value; }
    public boolean isActive() { return active; }
    public void setActive(boolean value) { active = value; }
}
