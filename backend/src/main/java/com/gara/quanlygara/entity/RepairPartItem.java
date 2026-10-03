// TV3-TUAN7
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;

/**
 * Hạng mục phụ tùng của phiếu sửa chữa: bảng ChiTietPhuTung (khóa chính = phiếu + phụ tùng).
 * Chỉ ghi dòng chi tiết; tuyệt đối không đụng SoLuongTon của PhuTung.
 */
@Entity
@Table(name = "ChiTietPhuTung")
@IdClass(RepairPartItem.Key.class)
public class RepairPartItem {

    @Id
    @Column(name = "MaPhieuSuaChua")
    private Integer repairOrderId;

    @Id
    @Column(name = "MaPhuTung")
    private Integer sparePartId;

    @Column(name = "SoLuong", nullable = false)
    private Integer quantity;

    @Column(name = "DonGia", nullable = false, precision = 18, scale = 2)
    private BigDecimal unitPrice;

    public static class Key implements Serializable {
        private Integer repairOrderId;
        private Integer sparePartId;

        public Key() {
        }

        public Key(Integer repairOrderId, Integer sparePartId) {
            this.repairOrderId = repairOrderId;
            this.sparePartId = sparePartId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(repairOrderId, key.repairOrderId) && Objects.equals(sparePartId, key.sparePartId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(repairOrderId, sparePartId);
        }
    }

    public Integer getRepairOrderId() {
        return repairOrderId;
    }

    public void setRepairOrderId(Integer repairOrderId) {
        this.repairOrderId = repairOrderId;
    }

    public Integer getSparePartId() {
        return sparePartId;
    }

    public void setSparePartId(Integer sparePartId) {
        this.sparePartId = sparePartId;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setQuantity(Integer quantity) {
        this.quantity = quantity;
    }

    public BigDecimal getUnitPrice() {
        return unitPrice;
    }

    public void setUnitPrice(BigDecimal unitPrice) {
        this.unitPrice = unitPrice;
    }
}
