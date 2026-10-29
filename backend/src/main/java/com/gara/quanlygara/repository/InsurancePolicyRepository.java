package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InsurancePolicy;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InsurancePolicyRepository extends JpaRepository<InsurancePolicy, Integer> {
    boolean existsByCompanyIdAndPolicyNumber(Integer companyId, String policyNumber);
    List<InsurancePolicy> findByVehicleIdOrderByEndDateDescIdDesc(Integer vehicleId);
}
