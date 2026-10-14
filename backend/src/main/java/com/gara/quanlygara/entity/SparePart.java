// TV3-TUAN7
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.math.BigDecimal;

/**
 * Danh mục phụ tùng, ánh xạ bảng PhuTung (không đổi tên bảng/cột, không thêm cột).
 * SoLuongTon chỉ đọc: tồn kho do các procedure nhập/xuất kho của CSDL thay đổi,
 * entity này không có setter và Hibernate không bao giờ ghi cột đó.
 */
@Entity
@Table(name = "PhuTung")
public class SparePart {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaPhuTung")
    private Integer id;

    @Column(name = "MaKho", nullable = false)
    private Integer warehouseId;

    @Column(name = "TenPhuTung", nullable = false, length = 150)
    private String name;

    @Column(name = "HangSanXuat", length = 150)
    private String manufacturer;

    @Column(name = "DonGia", nullable = false, precision = 18, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "SoLuongTon", insertable = false, updatable = false)
    private Integer stockQuantity;

    @Column(name = "MucTonToiThieu", nullable = false)
    private Integer minStockLevel;

    public Integer getId() {
        return id;
    }

    public void setId(Integer id) {
        this.id = id;
    }

    public Integer getWarehouseId() {
        return warehouseId;
    }

    public void setWarehouseId(Integer warehouseId) {
        this.warehouseId = warehouseId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getManufacturer() {
        return manufacturer;
    }

    public void setManufacturer(String manufacturer) {
        this.manufacturer = manufacturer;
    }

    public BigDecimal getUnitPrice() {
        return unitPrice;
    }

    public void setUnitPrice(BigDecimal unitPrice) {
        this.unitPrice = unitPrice;
    }

    public Integer getStockQuantity() {
        return stockQuantity;
    }

    public Integer getMinStockLevel() {
        return minStockLevel;
    }

    public void setMinStockLevel(Integer minStockLevel) {
        this.minStockLevel = minStockLevel;
    }
}
