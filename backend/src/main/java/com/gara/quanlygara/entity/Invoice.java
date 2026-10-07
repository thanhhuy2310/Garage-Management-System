package com.gara.quanlygara.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "HoaDon")
public class Invoice {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaHoaDon")
    private Integer id;
    @Column(name = "MaPhieuSuaChua", nullable = false, unique = true)
    private Integer repairOrderId;
    @Column(name = "NgayLap", nullable = false)
    private LocalDateTime createdAt;
    @Column(name = "TongTien", nullable = false, precision = 18, scale = 2)
    private BigDecimal total;
    @Column(name = "TrangThai", nullable = false, length = 50)
    private String status;
    public Integer getId() { return id; }
    public Integer getRepairOrderId() { return repairOrderId; }
    public void setRepairOrderId(Integer value) { repairOrderId = value; }
    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime value) { createdAt = value; }
    public BigDecimal getTotal() { return total; }
    public void setTotal(BigDecimal value) { total = value; }
    public String getStatus() { return status; }
    public void setStatus(String value) { status = value; }
}
