// TV3-TUAN8
package com.gara.quanlygara.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/** Phiếu xuất kho (cấp phát phụ tùng): bảng PhieuXuatKho. Tạo phiếu KHÔNG giảm tồn. */
@Entity
@Table(name = "PhieuXuatKho")
public class StockIssue {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaPhieuXuat")
    private Integer id;

    @Column(name = "MaPhieuSuaChua")
    private Integer repairOrderId;

    @Column(name = "MaNhanVienKho", nullable = false)
    private Integer warehouseStaffId;

    @Column(name = "MaKyThuatVienYeuCau")
    private Integer requestedTechnicianId;

    @Column(name = "NgayXuat", nullable = false)
    private LocalDateTime issueDate;

    @Column(name = "LyDo", nullable = false, length = 500)
    private String reason;

    public Integer getId() { return id; }
    public void setId(Integer id) { this.id = id; }
    public Integer getRepairOrderId() { return repairOrderId; }
    public void setRepairOrderId(Integer repairOrderId) { this.repairOrderId = repairOrderId; }
    public Integer getWarehouseStaffId() { return warehouseStaffId; }
    public void setWarehouseStaffId(Integer warehouseStaffId) { this.warehouseStaffId = warehouseStaffId; }
    public Integer getRequestedTechnicianId() { return requestedTechnicianId; }
    public void setRequestedTechnicianId(Integer requestedTechnicianId) { this.requestedTechnicianId = requestedTechnicianId; }
    public LocalDateTime getIssueDate() { return issueDate; }
    public void setIssueDate(LocalDateTime issueDate) { this.issueDate = issueDate; }
    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }
}
