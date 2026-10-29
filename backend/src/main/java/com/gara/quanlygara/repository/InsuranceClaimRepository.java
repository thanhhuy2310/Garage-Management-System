package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InsuranceClaim;
import java.time.LocalDateTime;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InsuranceClaimRepository extends JpaRepository<InsuranceClaim, Integer> {
    boolean existsByReceptionId(Integer receptionId);
    boolean existsByVehicleIdAndIncidentAtAndIncidentLocation(
            Integer vehicleId, LocalDateTime incidentAt, String incidentLocation);
    boolean existsByCompanyIdAndInsurerClaimNumber(Integer companyId, String insurerClaimNumber);
    List<InsuranceClaim> findByVehicleIdOrderByIdDesc(Integer vehicleId);
}
