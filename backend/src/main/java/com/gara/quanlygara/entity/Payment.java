package com.gara.quanlygara.entity;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "ThanhToan")
public class Payment {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "MaThanhToan")
    private Integer id;
    @Column(name = "MaHoaDon", nullable = false)
    private Integer invoiceId;
    @Column(name = "NgayThanhToan", nullable = false)
    private LocalDateTime paidAt;
    @Column(name = "SoTien", nullable = false, precision = 18, scale = 2)
    private BigDecimal amount;
    @Column(name = "PhuongThuc", nullable = false, length = 50)
    private String method;
    @Column(name = "MaYeuCau", length = 36)
    private String requestId;
    @Column(name = "MaTaiKhoanNhan")
    private Integer bankAccountId;
    public Integer getId() { return id; }
    public Integer getInvoiceId() { return invoiceId; }
    public void setInvoiceId(Integer value) { invoiceId = value; }
    public LocalDateTime getPaidAt() { return paidAt; }
    public void setPaidAt(LocalDateTime value) { paidAt = value; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal value) { amount = value; }
    public String getMethod() { return method; }
    public void setMethod(String value) { method = value; }
    public String getRequestId() { return requestId; }
    public void setRequestId(String value) { requestId = value; }
    public Integer getBankAccountId() { return bankAccountId; }
    public void setBankAccountId(Integer value) { bankAccountId = value; }
}
