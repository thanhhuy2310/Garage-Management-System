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

/** Hạng mục dịch vụ của phiếu sửa chữa: bảng ChiTietDichVu (khóa chính = phiếu + dịch vụ). */
@Entity
@Table(name = "ChiTietDichVu")
@IdClass(RepairServiceItem.Key.class)
public class RepairServiceItem {

    @Id
    @Column(name = "MaPhieuSuaChua")
    private Integer repairOrderId;

    @Id
    @Column(name = "MaDichVu")
    private Integer serviceId;

    @Column(name = "SoLuong", nullable = false)
    private Integer quantity;

    @Column(name = "DonGia", nullable = false, precision = 18, scale = 2)
    private BigDecimal unitPrice;

    // Tiến độ do nghiệp vụ kỹ thuật viên cập nhật (Huy); ThanhTien là cột tính toán của CSDL nên không ánh xạ.
    @Column(name = "TrangThai", length = 50)
    private String status;

    public static class Key implements Serializable {
        private Integer repairOrderId;
        private Integer serviceId;

        public Key() {
        }

        public Key(Integer repairOrderId, Integer serviceId) {
            this.repairOrderId = repairOrderId;
            this.serviceId = serviceId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(repairOrderId, key.repairOrderId) && Objects.equals(serviceId, key.serviceId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(repairOrderId, serviceId);
        }
    }

    public Integer getRepairOrderId() {
        return repairOrderId;
    }

    public void setRepairOrderId(Integer repairOrderId) {
        this.repairOrderId = repairOrderId;
    }

    public Integer getServiceId() {
        return serviceId;
    }

    public void setServiceId(Integer serviceId) {
        this.serviceId = serviceId;
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

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
