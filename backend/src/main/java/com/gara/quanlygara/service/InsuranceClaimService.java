package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.insurance.InsuranceClaimEventResponse;
import com.gara.quanlygara.dto.insurance.InsuranceClaimRequest;
import com.gara.quanlygara.dto.insurance.InsuranceClaimResponse;
import com.gara.quanlygara.entity.InsuranceClaim;
import com.gara.quanlygara.entity.InsuranceClaimEvent;
import com.gara.quanlygara.entity.InsurancePolicy;
import com.gara.quanlygara.entity.InsuranceReception;
import com.gara.quanlygara.entity.Vehicle;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.InsuranceClaimEventRepository;
import com.gara.quanlygara.repository.InsuranceClaimRepository;
import com.gara.quanlygara.repository.InsurancePolicyRepository;
import com.gara.quanlygara.repository.InsuranceReceptionRepository;
import com.gara.quanlygara.repository.VehicleRepository;
import com.gara.quanlygara.security.StaffContext;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class InsuranceClaimService {
    private final InsuranceClaimRepository claimRepository;
    private final InsuranceClaimEventRepository eventRepository;
    private final InsurancePolicyRepository policyRepository;
    private final InsuranceReceptionRepository receptionRepository;
    private final VehicleRepository vehicleRepository;
    private final StaffContext staffContext;

    public InsuranceClaimService(InsuranceClaimRepository claimRepository,
                                 InsuranceClaimEventRepository eventRepository,
                                 InsurancePolicyRepository policyRepository,
                                 InsuranceReceptionRepository receptionRepository,
                                 VehicleRepository vehicleRepository, StaffContext staffContext) {
        this.claimRepository = claimRepository;
        this.eventRepository = eventRepository;
        this.policyRepository = policyRepository;
        this.receptionRepository = receptionRepository;
        this.vehicleRepository = vehicleRepository;
        this.staffContext = staffContext;
    }

    @Transactional
    public InsuranceClaimResponse create(InsuranceClaimRequest request, Authentication authentication) {
        if (request.incidentAt().isAfter(LocalDateTime.now())) {
            throw new BadRequestException("Thời điểm sự cố không được ở tương lai.");
        }
        InsurancePolicy policy = policyRepository.findById(request.policyId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng bảo hiểm."));
        if (!"VAT_CHAT_XE".equals(policy.getInsuranceType())) {
            throw new BadRequestException("Hợp đồng này không phải bảo hiểm vật chất xe.");
        }
        InsuranceReception reception = receptionRepository.findById(request.receptionId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu tiếp nhận."));
        if (!policy.getVehicleId().equals(reception.getVehicleId())) {
            throw new BadRequestException("Hợp đồng bảo hiểm không thuộc xe trên phiếu tiếp nhận.");
        }
        Vehicle vehicle = vehicleRepository.findById(reception.getVehicleId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy xe."));
        if (!policy.getCustomerId().equals(vehicle.getCustomerId())) {
            throw new BadRequestException("Người đứng tên hợp đồng không khớp với chủ xe hiện tại.");
        }
        String location = request.incidentLocation().strip();
        String insurerNumber = normalize(request.insurerClaimNumber());
        if (insurerNumber != null) insurerNumber = insurerNumber.toUpperCase(Locale.ROOT);
        if (claimRepository.existsByReceptionId(reception.getId())) {
            throw new ConflictException("Phiếu tiếp nhận đã có hồ sơ bảo hiểm.");
        }
        if (claimRepository.existsByVehicleIdAndIncidentAtAndIncidentLocation(
                vehicle.getId(), request.incidentAt(), location)) {
            throw new ConflictException("Xe đã có hồ sơ cho sự cố cùng thời điểm và địa điểm.");
        }
        if (insurerNumber != null && claimRepository.existsByCompanyIdAndInsurerClaimNumber(
                policy.getCompanyId(), insurerNumber)) {
            throw new ConflictException("Mã hồ sơ của công ty bảo hiểm đã được sử dụng.");
        }
        Integer employeeId = staffContext.employeeId(authentication);
        String code = "BH-" + UUID.randomUUID().toString().toUpperCase(Locale.ROOT);
        InsuranceClaim claim = new InsuranceClaim(code, insurerNumber, policy.getCompanyId(), policy.getId(),
                reception.getId(), vehicle.getId(), vehicle.getCustomerId(), request.incidentAt(),
                location, request.causeDescription().strip(), request.damageDescription().strip(),
                request.notifiedAt(), normalize(request.assessorName()), normalize(request.assessorContact()),
                employeeId);
        claim = claimRepository.saveAndFlush(claim);
        InsuranceClaimEvent event = new InsuranceClaimEvent(claim.getId(), employeeId, "TAO_HO_SO",
                null, "MOI_TAO", "Tạo hồ sơ; chưa xác nhận phạm vi hoặc số tiền bồi thường.");
        eventRepository.saveAndFlush(event);
        return InsuranceClaimResponse.from(claim, List.of(InsuranceClaimEventResponse.from(event)));
    }

    @Transactional(readOnly = true)
    public InsuranceClaimResponse get(Integer id) {
        InsuranceClaim claim = claimRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hồ sơ bảo hiểm."));
        List<InsuranceClaimEventResponse> events = eventRepository.findByClaimIdOrderByIdAsc(id)
                .stream().map(InsuranceClaimEventResponse::from).toList();
        return InsuranceClaimResponse.from(claim, events);
    }

    @Transactional(readOnly = true)
    public List<InsuranceClaimResponse> byVehicle(Integer vehicleId) {
        if (!vehicleRepository.existsById(vehicleId)) {
            throw new ResourceNotFoundException("Không tìm thấy xe.");
        }
        return claimRepository.findByVehicleIdOrderByIdDesc(vehicleId).stream()
                .map(claim -> InsuranceClaimResponse.from(claim, List.of())).toList();
    }

    private String normalize(String value) {
        return value == null || value.isBlank() ? null : value.strip();
    }
}
