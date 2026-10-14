package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Payment;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

public interface PaymentRepository extends JpaRepository<Payment, Integer> {
    List<Payment> findByInvoiceIdOrderByPaidAtDescIdDesc(Integer invoiceId);
    Optional<Payment> findByRequestId(String requestId);
    @Query("select coalesce(sum(p.amount), 0) from Payment p where p.invoiceId = :invoiceId")
    BigDecimal totalPaid(@Param("invoiceId") Integer invoiceId);
}
