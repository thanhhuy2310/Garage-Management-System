// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.util.Objects;

/** Chi tiết kiểm kê: bảng ChiTietKiemKe (ChenhLech là cột tính toán; Java tính lại bằng difference()). */
@Entity
@Table(name = "ChiTietKiemKe")
@IdClass(InventoryCheckItem.Key.class)
public class InventoryCheckItem {

    @Id
    @Column(name = "MaPhieuKiemKe")
    private Integer checkId;

    @Id
    @Column(name = "MaPhuTung")
    private Integer partId;

    @Column(name = "SoLuongHeThong", nullable = false)
    private Integer systemQuantity;

    @Column(name = "SoLuongThucTe")
    private Integer actualQuantity;

    @Column(name = "LyDo", length = 500)
    private String reason;

    @Column(name = "DaDuyetDieuChinh", nullable = false)
    private boolean adjustmentApproved;

    public static class Key implements Serializable {
        private Integer checkId;
        private Integer partId;

        public Key() {
        }

        public Key(Integer checkId, Integer partId) {
            this.checkId = checkId;
            this.partId = partId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(checkId, key.checkId) && Objects.equals(partId, key.partId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(checkId, partId);
        }
    }

    /** Chênh lệch = thực tế - hệ thống; null nếu chưa nhập thực tế. */
    public Integer difference() {
        return actualQuantity == null ? null : actualQuantity - systemQuantity;
    }

    public Integer getCheckId() { return checkId; }
    public void setCheckId(Integer checkId) { this.checkId = checkId; }
    public Integer getPartId() { return partId; }
    public void setPartId(Integer partId) { this.partId = partId; }
    public Integer getSystemQuantity() { return systemQuantity; }
    public void setSystemQuantity(Integer systemQuantity) { this.systemQuantity = systemQuantity; }
    public Integer getActualQuantity() { return actualQuantity; }
    public void setActualQuantity(Integer actualQuantity) { this.actualQuantity = actualQuantity; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
    public boolean isAdjustmentApproved() { return adjustmentApproved; }
    public void setAdjustmentApproved(boolean adjustmentApproved) { this.adjustmentApproved = adjustmentApproved; }
}
