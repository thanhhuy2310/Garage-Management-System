package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.insurance.InsurancePolicyRequest;
import com.gara.quanlygara.dto.insurance.InsurancePolicyVerificationRequest;
import com.gara.quanlygara.entity.InsurancePolicy;
import com.gara.quanlygara.entity.Vehicle;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.repository.InsuranceCompanyRepository;
import com.gara.quanlygara.repository.InsurancePolicyRepository;
import com.gara.quanlygara.repository.VehicleRepository;
import com.gara.quanlygara.security.StaffContext;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InsuranceCatalogServiceTest {
    @Mock InsuranceCompanyRepository companyRepository;
    @Mock InsurancePolicyRepository policyRepository;
    @Mock VehicleRepository vehicleRepository;
    @Mock StaffContext staffContext;
    @Mock Authentication authentication;

    private InsuranceCatalogService service;

    @BeforeEach
    void setUp() {
        service = new InsuranceCatalogService(companyRepository, policyRepository, vehicleRepository, staffContext);
    }

    @Test
    void createPolicyKeepsVerificationPendingAndDerivesCustomerFromVehicle() {
        Vehicle vehicle = new Vehicle();
        vehicle.setId(8);
        vehicle.setCustomerId(12);
        when(companyRepository.existsById(3)).thenReturn(true);
        when(vehicleRepository.findById(8)).thenReturn(Optional.of(vehicle));
        when(policyRepository.saveAndFlush(any(InsurancePolicy.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        var result = service.createPolicy(request(LocalDate.of(2026, 1, 1), LocalDate.of(2027, 1, 1)));

        assertEquals(12, result.customerId());
        assertEquals("CHUA_XAC_MINH", result.verificationStatus());
        assertEquals(new BigDecimal("500000.00"), result.deductible());
        assertTrue(result.verifiedAt() == null);
    }

    @Test
    void createPolicyRejectsInvertedDatesBeforeWriting() {
        assertThrows(BadRequestException.class, () -> service.createPolicy(
                request(LocalDate.of(2027, 1, 1), LocalDate.of(2026, 1, 1))));
        verify(policyRepository, never()).saveAndFlush(any());
    }

    @Test
    void createPolicyRejectsDuplicateWithinCompany() {
        Vehicle vehicle = new Vehicle();
        vehicle.setId(8);
        vehicle.setCustomerId(12);
        when(companyRepository.existsById(3)).thenReturn(true);
        when(vehicleRepository.findById(8)).thenReturn(Optional.of(vehicle));
        when(policyRepository.existsByCompanyIdAndPolicyNumber(3, "HD-123")).thenReturn(true);

        assertThrows(ConflictException.class, () -> service.createPolicy(
                request(LocalDate.of(2026, 1, 1), LocalDate.of(2027, 1, 1))));
        verify(policyRepository, never()).saveAndFlush(any());
    }

    @Test
    void verificationRecordsEmployeeAndDoesNotInferApprovalFromDates() {
        InsurancePolicy policy = new InsurancePolicy(3, 8, 12, "HD-123", "VAT_CHAT_XE",
                LocalDate.of(2026, 1, 1), LocalDate.of(2027, 1, 1), null, null, null, null, null);
        when(policyRepository.findById(5)).thenReturn(Optional.of(policy));
        when(staffContext.employeeId(authentication)).thenReturn(9);
        when(policyRepository.saveAndFlush(policy)).thenReturn(policy);

        var result = service.verifyPolicy(5,
                new InsurancePolicyVerificationRequest("DA_XAC_MINH", "Đã đối chiếu chứng nhận gốc."),
                authentication);

        assertEquals("DA_XAC_MINH", result.verificationStatus());
        assertEquals(9, result.verifiedByEmployeeId());
        assertTrue(result.verifiedAt() != null);
    }

    @Test
    void verificationCannotOverwritePreviousResult() {
        InsurancePolicy policy = new InsurancePolicy(3, 8, 12, "HD-123", "VAT_CHAT_XE",
                LocalDate.of(2026, 1, 1), LocalDate.of(2027, 1, 1), null, null, null, null, null);
        policy.verify("KHONG_HOP_LE", "Không tìm thấy hợp đồng.", 9, java.time.LocalDateTime.now());
        when(policyRepository.findById(5)).thenReturn(Optional.of(policy));

        assertThrows(ConflictException.class, () -> service.verifyPolicy(5,
                new InsurancePolicyVerificationRequest("DA_XAC_MINH", "Đã đối chiếu."), authentication));
        verify(policyRepository, never()).saveAndFlush(any());
    }

    private InsurancePolicyRequest request(LocalDate start, LocalDate end) {
        return new InsurancePolicyRequest(3, 8, " HD-123 ", "VAT_CHAT_XE", start, end,
                new BigDecimal("1000000000.00"), new BigDecimal("500000.00"), null, null, null);
    }
}
