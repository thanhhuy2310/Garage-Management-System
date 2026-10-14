package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.RepairProgress;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface RepairProgressRepository extends JpaRepository<RepairProgress, Long> {
    List<RepairProgress> findByRepairOrderIdOrderByCreatedAtDescIdDesc(Integer repairOrderId);
}
