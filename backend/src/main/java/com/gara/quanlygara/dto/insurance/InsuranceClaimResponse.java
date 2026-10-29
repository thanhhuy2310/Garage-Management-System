package com.gara.quanlygara.dto.insurance;

import com.gara.quanlygara.entity.InsuranceClaim;
import java.time.LocalDateTime;
import java.util.List;

public record InsuranceClaimResponse(
        Integer id, String code, String insurerClaimNumber, Integer companyId, Integer policyId,
        Integer receptionId, Integer vehicleId, Integer customerId, LocalDateTime incidentAt,
        String incidentLocation, String causeDescription, String damageDescription,
        LocalDateTime notifiedAt, String assessorName, String assessorContact, String status,
        Integer createdByEmployeeId, LocalDateTime createdAt, List<InsuranceClaimEventResponse> events
) {
    public static InsuranceClaimResponse from(InsuranceClaim claim, List<InsuranceClaimEventResponse> events) {
        return new InsuranceClaimResponse(claim.getId(), claim.getCode(), claim.getInsurerClaimNumber(),
                claim.getCompanyId(), claim.getPolicyId(), claim.getReceptionId(), claim.getVehicleId(),
                claim.getCustomerId(), claim.getIncidentAt(), claim.getIncidentLocation(),
                claim.getCauseDescription(), claim.getDamageDescription(), claim.getNotifiedAt(),
                claim.getAssessorName(), claim.getAssessorContact(), claim.getStatus(),
                claim.getCreatedByEmployeeId(), claim.getCreatedAt(), events);
    }
}
