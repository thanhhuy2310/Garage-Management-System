package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InsurancePolicy;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InsurancePolicyRepository extends JpaRepository<InsurancePolicy, Integer> {
    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select p from InsurancePolicy p where p.id=:id")
    java.util.Optional<InsurancePolicy> forVerification(@org.springframework.data.repository.query.Param("id") Integer id);

    boolean existsByCompanyIdAndPolicyNumber(Integer companyId, String policyNumber);
    List<InsurancePolicy> findByVehicleIdOrderByEndDateDescIdDesc(Integer vehicleId);
}
