// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** Lịch sử biến động kho: bảng BienDongKho (bảng lịch sử duy nhất). */
@Entity
@Table(name = "BienDongKho")
public class StockMovement {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaBienDong")
    private Long id;

    @Column(name = "MaPhuTung", nullable = false)
    private Integer partId;

    @Column(name = "MaPhieuNhap")
    private Integer receiptId;

    @Column(name = "MaPhieuXuat")
    private Integer issueId;

    @Column(name = "ThoiGian", nullable = false)
    private LocalDateTime movedAt;

    /** NHAP, XUAT hoặc KIEM_KE (ràng buộc CK_BienDongKho_Loai). */
    @Column(name = "LoaiBienDong", nullable = false, length = 20)
    private String type;

    @Column(name = "SoLuong", nullable = false)
    private Integer quantity;

    @Column(name = "SoLuongTruoc")
    private Integer quantityBefore;

    @Column(name = "SoLuongSau")
    private Integer quantityAfter;

    @Column(name = "GhiChu", length = 500)
    private String note;

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public Integer getPartId() { return partId; }
    public void setPartId(Integer partId) { this.partId = partId; }
    public Integer getReceiptId() { return receiptId; }
    public void setReceiptId(Integer receiptId) { this.receiptId = receiptId; }
    public Integer getIssueId() { return issueId; }
    public void setIssueId(Integer issueId) { this.issueId = issueId; }
    public LocalDateTime getMovedAt() { return movedAt; }
    public void setMovedAt(LocalDateTime movedAt) { this.movedAt = movedAt; }
    public String getType() { return type; }
    public void setType(String type) { this.type = type; }
    public Integer getQuantity() { return quantity; }
    public void setQuantity(Integer quantity) { this.quantity = quantity; }
    public Integer getQuantityBefore() { return quantityBefore; }
    public void setQuantityBefore(Integer quantityBefore) { this.quantityBefore = quantityBefore; }
    public Integer getQuantityAfter() { return quantityAfter; }
    public void setQuantityAfter(Integer quantityAfter) { this.quantityAfter = quantityAfter; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
