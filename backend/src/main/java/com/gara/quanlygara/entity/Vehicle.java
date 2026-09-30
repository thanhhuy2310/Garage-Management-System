package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

/**
 * Xe của khách hàng. Ánh xạ trực tiếp vào bảng Xe của QuanLyGaraOTo.sql,
 * không đổi tên bảng/cột và không thêm cột mới.
 */
@Entity
@Table(name = "Xe")
public class Vehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaXe")
    private Integer id;

    @Column(name = "MaKhachHang", nullable = false)
    private Integer customerId;

    @Column(name = "BienSo", nullable = false, length = 20, unique = true)
    private String licensePlate;

    @Column(name = "HangXe", length = 100)
    private String brand;

    @Column(name = "DongXe", length = 100)
    private String model;

    @Column(name = "NamSanXuat")
    private Short year;

    @Column(name = "SoKm")
    private Integer mileage;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getCustomerId() {
        return customerId;
    }

    public void setCustomerId(Integer customerId) {
        this.customerId = customerId;
    }

    public String getLicensePlate() {
        return licensePlate;
    }

    public void setLicensePlate(String licensePlate) {
        this.licensePlate = licensePlate;
    }

    public String getBrand() {
        return brand;
    }

    public void setBrand(String brand) {
        this.brand = brand;
    }

    public String getModel() {
        return model;
    }

    public void setModel(String model) {
        this.model = model;
    }

    public Short getYear() {
        return year;
    }

    public void setYear(Short year) {
        this.year = year;
    }

    public Integer getMileage() {
        return mileage;
    }

    public void setMileage(Integer mileage) {
        this.mileage = mileage;
    }
}
