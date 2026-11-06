// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.IdClass;
import jakarta.persistence.Table;

import java.io.Serializable;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Objects;

/**
 * Chi tiết phiếu xuất: bảng ChiTietPhieuXuat.
 * quantity (SoLuong) = số lượng CẤP PHÁT; actualUsedQuantity = KTV xác nhận thực dùng;
 * returnedQuantity = quantity - actualUsedQuantity; chỉ cộng tồn sau khi kho xác nhận nhận trả.
 */
@Entity
@Table(name = "ChiTietPhieuXuat")
@IdClass(StockIssueItem.Key.class)
public class StockIssueItem {
    @Column(name="DaXuatKho",nullable=false)
    private boolean issued;
    @Column(name="DaNhapTra",nullable=false)
    private boolean returnConfirmed;
    @Column(name="NgayXuatKho") private LocalDateTime issuedAt;
    @Column(name="NguoiXuatKho") private Integer issuedBy;
    @Column(name="NgayNhapTra") private LocalDateTime returnedAt;
    @Column(name="NguoiNhapTra") private Integer returnedBy;
    public boolean isIssued(){return issued;}
    public void setIssued(boolean value){issued=value;}
    public boolean isReturnConfirmed(){return returnConfirmed;}
    public void setReturnConfirmed(boolean value){returnConfirmed=value;}
    public void recordIssue(Integer staff){issued=true;issuedBy=staff;issuedAt=LocalDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));}
    public void recordReturn(Integer staff){returnConfirmed=true;returnedBy=staff;returnedAt=LocalDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"));}

    @Id
    @Column(name = "MaPhieuXuat")
    private Integer issueId;

    @Id
    @Column(name = "MaPhuTung")
    private Integer partId;

    @Column(name = "SoLuong", nullable = false)
    private Integer quantity;

    @Column(name = "DonGia", precision = 18, scale = 2)
    private BigDecimal unitPrice;

    @Column(name = "DaXacNhanSuDung", nullable = false)
    private boolean confirmed;

    @Column(name = "NgayXacNhan")
    private LocalDateTime confirmedAt;

    @Column(name = "MaKyThuatVienXacNhan")
    private Integer confirmedTechnicianId;

    @Column(name = "SoLuongThucDung")
    private Integer actualUsedQuantity;

    @Column(name = "SoLuongHoanTra")
    private Integer returnedQuantity;

    public static class Key implements Serializable {
        private Integer issueId;
        private Integer partId;

        public Key() {
        }

        public Key(Integer issueId, Integer partId) {
            this.issueId = issueId;
            this.partId = partId;
        }

        @Override
        public boolean equals(Object other) {
            if (this == other) return true;
            if (!(other instanceof Key key)) return false;
            return Objects.equals(issueId, key.issueId) && Objects.equals(partId, key.partId);
        }

        @Override
        public int hashCode() {
            return Objects.hash(issueId, partId);
        }
    }

    public Integer getIssueId() { return issueId; }
    public void setIssueId(Integer issueId) { this.issueId = issueId; }
    public Integer getPartId() { return partId; }
    public void setPartId(Integer partId) { this.partId = partId; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public BigDecimal getUnitPrice() { return unitPrice; }
    public void setUnitPrice(BigDecimal unitPrice) { this.unitPrice = unitPrice; }
    public boolean isConfirmed() { return confirmed; }
    public void setConfirmed(boolean confirmed) { this.confirmed = confirmed; }
    public LocalDateTime getConfirmedAt() { return confirmedAt; }
    public void setConfirmedAt(LocalDateTime confirmedAt) { this.confirmedAt = confirmedAt; }
    public Integer getConfirmedTechnicianId() { return confirmedTechnicianId; }
    public void setConfirmedTechnicianId(Integer confirmedTechnicianId) { this.confirmedTechnicianId = confirmedTechnicianId; }
    public Integer getActualUsedQuantity() { return actualUsedQuantity; }
    public void setActualUsedQuantity(Integer actualUsedQuantity) { this.actualUsedQuantity = actualUsedQuantity; }
    public Integer getReturnedQuantity() { return returnedQuantity; }
    public void setReturnedQuantity(Integer returnedQuantity) { this.returnedQuantity = returnedQuantity; }
}
