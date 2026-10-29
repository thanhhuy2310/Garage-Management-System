package com.gara.quanlygara.dto.insurance;

import com.gara.quanlygara.entity.InsurancePolicy;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

public record InsurancePolicyResponse(
        Integer id, Integer companyId, Integer vehicleId, Integer customerId, String policyNumber,
        String insuranceType, LocalDate startDate, LocalDate endDate, BigDecimal insuredAmount,
        BigDecimal deductible, String repairShopTerms, String partsTerms, String certificateReference,
        String verificationStatus, String verificationNote, Integer verifiedByEmployeeId,
        LocalDateTime verifiedAt
) {
    public static InsurancePolicyResponse from(InsurancePolicy policy) {
        return new InsurancePolicyResponse(policy.getId(), policy.getCompanyId(), policy.getVehicleId(),
                policy.getCustomerId(), policy.getPolicyNumber(), policy.getInsuranceType(),
                policy.getStartDate(), policy.getEndDate(), policy.getInsuredAmount(), policy.getDeductible(),
                policy.getRepairShopTerms(), policy.getPartsTerms(), policy.getCertificateReference(),
                policy.getVerificationStatus(), policy.getVerificationNote(),
                policy.getVerifiedByEmployeeId(), policy.getVerifiedAt());
    }
}
