// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** Phiếu nhập kho: bảng PhieuNhapKho. */
@Entity
@Table(name = "PhieuNhapKho")
public class StockReceipt {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaPhieuNhap")
    private Integer id;

    @Column(name = "NgayNhap", nullable = false)
    private LocalDateTime receiptDate;

    @Column(name = "NhaCungCap", nullable = false, length = 200)
    private String supplier;

    @Column(name = "MaNhanVienKho", nullable = false)
    private Integer warehouseStaffId;

    @Column(name = "GhiChu", length = 500)
    private String note;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public LocalDateTime getReceiptDate() { return receiptDate; }
    public void setReceiptDate(LocalDateTime receiptDate) { this.receiptDate = receiptDate; }
    public String getSupplier() { return supplier; }
    public void setSupplier(String supplier) { this.supplier = supplier; }
    public Integer getWarehouseStaffId() { return warehouseStaffId; }
    public void setWarehouseStaffId(Integer warehouseStaffId) { this.warehouseStaffId = warehouseStaffId; }
    public String getNote() { return note; }
    public void setNote(String note) { this.note = note; }
}
