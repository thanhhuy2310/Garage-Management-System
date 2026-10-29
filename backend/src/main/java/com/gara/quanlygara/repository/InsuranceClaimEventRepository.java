package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InsuranceClaimEvent;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InsuranceClaimEventRepository extends JpaRepository<InsuranceClaimEvent, Long> {
    List<InsuranceClaimEvent> findByClaimIdOrderByIdAsc(Integer claimId);
}
