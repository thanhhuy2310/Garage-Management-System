package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Invoice;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.Optional;

public interface InvoiceRepository extends JpaRepository<Invoice, Integer> {
    boolean existsByRepairOrderId(Integer repairOrderId);
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select i from Invoice i where i.id = :id")
    Optional<Invoice> findForUpdate(@Param("id") Integer id);
}
