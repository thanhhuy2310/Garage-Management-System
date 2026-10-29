package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.insurance.InsuranceCompanyRequest;
import com.gara.quanlygara.dto.insurance.InsuranceCompanyResponse;
import com.gara.quanlygara.dto.insurance.InsurancePolicyRequest;
import com.gara.quanlygara.dto.insurance.InsurancePolicyResponse;
import com.gara.quanlygara.dto.insurance.InsurancePolicyVerificationRequest;
import com.gara.quanlygara.entity.InsuranceCompany;
import com.gara.quanlygara.entity.InsurancePolicy;
import com.gara.quanlygara.entity.Customer;
import com.gara.quanlygara.entity.Vehicle;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.InsuranceCompanyRepository;
import com.gara.quanlygara.repository.InsurancePolicyRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.VehicleRepository;
import com.gara.quanlygara.security.StaffContext;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Locale;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class InsuranceCatalogService {
    private final InsuranceCompanyRepository companyRepository;
    private final InsurancePolicyRepository policyRepository;
    private final VehicleRepository vehicleRepository;
    private final CustomerRepository customerRepository;
    private final StaffContext staffContext;

    public InsuranceCatalogService(InsuranceCompanyRepository companyRepository,
                                   InsurancePolicyRepository policyRepository,
                                   VehicleRepository vehicleRepository, CustomerRepository customerRepository,
                                   StaffContext staffContext) {
        this.companyRepository = companyRepository;
        this.policyRepository = policyRepository;
        this.vehicleRepository = vehicleRepository;
        this.customerRepository = customerRepository;
        this.staffContext = staffContext;
    }

    @Transactional(readOnly = true)
    public List<InsuranceCompanyResponse> companies() {
        return companyRepository.findAll().stream().map(InsuranceCompanyResponse::from).toList();
    }

    @Transactional
    public InsuranceCompanyResponse createCompany(InsuranceCompanyRequest request) {
        String code = request.code().strip().toUpperCase(Locale.ROOT);
        if (companyRepository.existsByCode(code)) {
            throw new ConflictException("Mã công ty bảo hiểm đã tồn tại.");
        }
        InsuranceCompany company = new InsuranceCompany(code, request.name().strip(), trim(request.phone()),
                trim(request.email()), trim(request.address()), trim(request.assessorName()),
                trim(request.assessorContact()), request.active());
        return InsuranceCompanyResponse.from(companyRepository.saveAndFlush(company));
    }

    @Transactional
    public InsuranceCompanyResponse updateCompany(Integer id, InsuranceCompanyRequest request) {
        InsuranceCompany company = companyRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy công ty bảo hiểm."));
        String code = request.code().strip().toUpperCase(Locale.ROOT);
        if (companyRepository.existsByCodeAndIdNot(code, id)) {
            throw new ConflictException("Mã công ty bảo hiểm đã tồn tại.");
        }
        company.update(code, request.name().strip(), trim(request.phone()), trim(request.email()),
                trim(request.address()), trim(request.assessorName()), trim(request.assessorContact()),
                request.active());
        return InsuranceCompanyResponse.from(companyRepository.saveAndFlush(company));
    }

    @Transactional(readOnly = true)
    public List<InsurancePolicyResponse> policiesForVehicle(Integer vehicleId) {
        if (!vehicleRepository.existsById(vehicleId)) {
            throw new ResourceNotFoundException("Không tìm thấy xe.");
        }
        return policyRepository.findByVehicleIdOrderByEndDateDescIdDesc(vehicleId).stream()
                .map(InsurancePolicyResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public InsurancePolicyResponse policy(Integer id) {
        return InsurancePolicyResponse.from(findPolicy(id));
    }

    @Transactional
    public InsurancePolicyResponse createPolicy(InsurancePolicyRequest request) {
        if (request.endDate().isBefore(request.startDate())) {
            throw new BadRequestException("Ngày kết thúc phải từ ngày bắt đầu trở đi.");
        }
        if (!companyRepository.existsById(request.companyId())) {
            throw new ResourceNotFoundException("Không tìm thấy công ty bảo hiểm.");
        }
        Vehicle vehicle = vehicleRepository.findById(request.vehicleId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy xe."));
        if (!vehicle.getCustomerId().equals(request.policyholderCustomerId())) {
            throw new BadRequestException("Người đứng tên hợp đồng phải trùng với chủ xe trên đăng ký.");
        }
        Customer owner = customerRepository.findById(vehicle.getCustomerId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chủ xe."));
        validateOwnerNames(request.registeredOwnerName(), request.certificateOwnerName(), owner.getFullName());
        String number = request.policyNumber().strip();
        if (policyRepository.existsByCompanyIdAndPolicyNumber(request.companyId(), number)) {
            throw new ConflictException("Số hợp đồng đã tồn tại tại công ty bảo hiểm này.");
        }
        InsurancePolicy policy = new InsurancePolicy(request.companyId(), vehicle.getId(),
                request.policyholderCustomerId(), number, request.insuranceType(), request.startDate(), request.endDate(),
                request.insuredAmount(), request.deductible(), trim(request.repairShopTerms()),
                trim(request.partsTerms()), trim(request.certificateReference()),
                request.registeredOwnerName().strip(), request.certificateOwnerName().strip());
        return InsurancePolicyResponse.from(policyRepository.saveAndFlush(policy));
    }

    @Transactional
    public InsurancePolicyResponse verifyPolicy(Integer id, InsurancePolicyVerificationRequest request,
                                                Authentication authentication) {
        InsurancePolicy policy = findPolicy(id);
        if (!"CHUA_XAC_MINH".equals(policy.getVerificationStatus())) {
            throw new ConflictException("Hợp đồng đã được xác minh. Không được ghi đè kết quả cũ.");
        }
        Vehicle vehicle = vehicleRepository.findById(policy.getVehicleId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy xe."));
        Customer owner = customerRepository.findById(vehicle.getCustomerId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chủ xe."));
        if (!vehicle.getCustomerId().equals(policy.getCustomerId())) {
            throw new BadRequestException("Người đứng tên hợp đồng không trùng với chủ xe hiện tại.");
        }
        validateOwnerNames(policy.getRegisteredOwnerName(), policy.getCertificateOwnerName(), owner.getFullName());
        policy.verify(request.status(), request.note().strip(), staffContext.employeeId(authentication),
                LocalDateTime.now());
        return InsurancePolicyResponse.from(policyRepository.saveAndFlush(policy));
    }

    private InsurancePolicy findPolicy(Integer id) {
        return policyRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hợp đồng bảo hiểm."));
    }

    private String trim(String value) {
        return value == null || value.isBlank() ? null : value.strip();
    }

    private void validateOwnerNames(String registrationName, String certificateName, String customerName) {
        if (registrationName == null || certificateName == null || customerName == null
                || !normalizeName(registrationName).equals(normalizeName(certificateName))
                || !normalizeName(registrationName).equals(normalizeName(customerName))) {
            throw new BadRequestException("Tên chủ xe trên đăng ký, giấy chứng nhận bảo hiểm và hồ sơ khách hàng phải khớp.");
        }
    }

    private String normalizeName(String value) {
        return value.strip().replaceAll("\\s+", " ").toUpperCase(Locale.ROOT);
    }
}
