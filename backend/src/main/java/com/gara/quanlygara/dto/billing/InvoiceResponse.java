package com.gara.quanlygara.dto.billing;

import com.gara.quanlygara.entity.Payment;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

public record InvoiceResponse(Integer id, Integer repairOrderId, LocalDateTime createdAt, String status,
                              BigDecimal total, BigDecimal paid, BigDecimal remaining,
                              String licensePlate, String customerName) {
    public record Line(String type, Integer id, String name, Integer quantity, BigDecimal unitPrice) { }
    public record Detail(InvoiceResponse invoice, List<Line> lines, List<Payment> payments) { }
}
