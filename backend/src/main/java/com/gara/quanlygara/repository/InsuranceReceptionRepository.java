package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InsuranceReception;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InsuranceReceptionRepository extends JpaRepository<InsuranceReception, Integer> {
    @Override
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    java.util.Optional<InsuranceReception> findById(Integer id);

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select r from RepairOrder r where r.receptionId = :id")
    java.util.Optional<com.gara.quanlygara.entity.RepairOrder> repairForUpdate(@org.springframework.data.repository.query.Param("id") Integer id);
}
