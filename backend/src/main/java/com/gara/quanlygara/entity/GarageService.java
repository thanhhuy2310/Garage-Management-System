package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;

@Entity
@Table(name = "DichVu")
public class GarageService {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaDichVu")
    private Integer id;

    @Column(name = "TenDichVu", nullable = false, length = 150)
    private String name;

    @Column(name = "LoaiDichVu", length = 100)
    private String type;

    @Column(name = "DonGia", nullable = false, precision = 18, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "MoTa", length = 500)
    private String description;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
