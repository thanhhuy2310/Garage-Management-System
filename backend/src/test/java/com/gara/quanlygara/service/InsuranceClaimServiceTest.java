package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.insurance.InsuranceClaimRequest;
import com.gara.quanlygara.entity.InsuranceClaim;
import com.gara.quanlygara.entity.InsuranceClaimEvent;
import com.gara.quanlygara.entity.InsurancePolicy;
import com.gara.quanlygara.entity.InsuranceReception;
import com.gara.quanlygara.entity.Vehicle;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.repository.InsuranceClaimEventRepository;
import com.gara.quanlygara.repository.InsuranceClaimRepository;
import com.gara.quanlygara.repository.InsurancePolicyRepository;
import com.gara.quanlygara.repository.InsuranceReceptionRepository;
import com.gara.quanlygara.repository.VehicleRepository;
import com.gara.quanlygara.security.StaffContext;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Optional;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.core.Authentication;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InsuranceClaimServiceTest {
    @Mock InsuranceClaimRepository claimRepository;
    @Mock InsuranceClaimEventRepository eventRepository;
    @Mock InsurancePolicyRepository policyRepository;
    @Mock InsuranceReceptionRepository receptionRepository;
    @Mock VehicleRepository vehicleRepository;
    @Mock StaffContext staffContext;
    @Mock Authentication authentication;

    private InsuranceClaimService service;

    @BeforeEach
    void setUp() {
        service = new InsuranceClaimService(claimRepository, eventRepository, policyRepository,
                receptionRepository, vehicleRepository, staffContext);
    }

    @Test
    void createLinksReceptionAndPolicyAndWritesAuditEvent() {
        matchingEntities();
        when(staffContext.employeeId(authentication)).thenReturn(7);
        when(claimRepository.saveAndFlush(any(InsuranceClaim.class))).thenAnswer(invocation -> {
            InsuranceClaim claim = invocation.getArgument(0);
            ReflectionTestUtils.setField(claim, "id", 21);
            return claim;
        });
        when(eventRepository.saveAndFlush(any(InsuranceClaimEvent.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));

        var result = service.create(request(), authentication);

        assertEquals(21, result.id());
        assertEquals(8, result.vehicleId());
        assertEquals(12, result.customerId());
        assertEquals("MOI_TAO", result.status());
        assertTrue(result.code().startsWith("BH-"));
        assertTrue(result.createdAt() != null);
        assertEquals("TAO_HO_SO", result.events().getFirst().action());
        assertEquals(7, result.events().getFirst().employeeId());
        assertTrue(result.events().getFirst().occurredAt() != null);
        verify(eventRepository).saveAndFlush(any(InsuranceClaimEvent.class));
    }

    @Test
    void createRejectsCivilLiabilityPolicyForOwnVehicleRepair() {
        InsurancePolicy policy = policy("TNDS", 8);
        when(policyRepository.findById(3)).thenReturn(Optional.of(policy));

        assertThrows(BadRequestException.class, () -> service.create(request(), authentication));
        verify(claimRepository, never()).saveAndFlush(any());
    }

    @Test
    void createRejectsPolicyForAnotherVehicle() {
        InsurancePolicy policy = policy("VAT_CHAT_XE", 99);
        when(policyRepository.findById(3)).thenReturn(Optional.of(policy));
        when(receptionRepository.findById(14)).thenReturn(Optional.of(new InsuranceReception(14, 8)));

        assertThrows(BadRequestException.class, () -> service.create(request(), authentication));
        verify(claimRepository, never()).saveAndFlush(any());
    }

    @Test
    void createRejectsDuplicateReception() {
        matchingEntities();
        when(claimRepository.existsByReceptionId(14)).thenReturn(true);

        assertThrows(ConflictException.class, () -> service.create(request(), authentication));
        verify(claimRepository, never()).saveAndFlush(any());
        verify(eventRepository, never()).saveAndFlush(any());
    }

    private void matchingEntities() {
        when(policyRepository.findById(3)).thenReturn(Optional.of(policy("VAT_CHAT_XE", 8)));
        when(receptionRepository.findById(14)).thenReturn(Optional.of(new InsuranceReception(14, 8)));
        Vehicle vehicle = new Vehicle();
        vehicle.setId(8);
        vehicle.setCustomerId(12);
        when(vehicleRepository.findById(8)).thenReturn(Optional.of(vehicle));
    }

    private InsurancePolicy policy(String type, Integer vehicleId) {
        InsurancePolicy policy = new InsurancePolicy(2, vehicleId, 12, "HD-123", type,
                LocalDate.of(2026, 1, 1), LocalDate.of(2027, 1, 1),
                null, null, null, null, null, "Nguyễn Văn An", "Nguyễn Văn An");
        ReflectionTestUtils.setField(policy, "id", 3);
        return policy;
    }

    private InsuranceClaimRequest request() {
        return new InsuranceClaimRequest(3, 14, null, LocalDateTime.of(2026, 10, 20, 8, 0),
                "Quận 7, TP.HCM", "Va chạm khi lùi xe", "Hư cản sau", null, null, null);
    }
}
