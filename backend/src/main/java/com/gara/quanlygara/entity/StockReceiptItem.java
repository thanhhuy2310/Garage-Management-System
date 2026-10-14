// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.math.BigDecimal;
import java.util.Objects;

/** Chi tiết phiếu nhập: bảng ChiTietPhieuNhap (ThanhTien là cột tính toán nên không ánh xạ). */
@Entity
@Table(name = "ChiTietPhieuNhap")
@IdClass(StockReceiptItem.Key.class)
public class StockReceiptItem {

    @Id
    @Column(name = "MaPhieuNhap")
    private Integer receiptId;

    @Id
    @Column(name = "MaPhuTung")
    private Integer partId;

    @Column(name = "SoLuong", nullable = false)
    private Integer quantity;

    @Column(name = "DonGiaNhap", nullable = false, precision = 18, scale = 2)
    private BigDecimal unitPrice;

    public static class Key implements Serializable {
        private Integer receiptId;
        private Integer partId;

        public Key() {
        }

        public Key(Integer receiptId, Integer partId) {
            this.receiptId = receiptId;
            this.partId = partId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(receiptId, key.receiptId) && Objects.equals(partId, key.partId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(receiptId, partId);
        }
    }

    public Integer getReceiptId() { return receiptId; }
    public void setReceiptId(Integer receiptId) { this.receiptId = receiptId; }
    public Integer getPartId() { return partId; }
    public void setPartId(Integer partId) { this.partId = partId; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
}
