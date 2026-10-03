package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.repair.RepairOrderDetailResponse;
import com.gara.quanlygara.dto.repair.RepairOrderResponse;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.exception.ForbiddenException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.exception.UnauthorizedException;
import com.gara.quanlygara.mapper.RepairOrderMapper;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.RepairOrderRepository;
import com.gara.quanlygara.repository.TechnicianAssignmentRepository;
import com.gara.quanlygara.repository.TechnicianRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional(readOnly = true)
public class RepairOrderQueryService {

    private final RepairOrderRepository repairOrderRepository;
    private final TechnicianAssignmentRepository assignmentRepository;
    private final AccountRepository accountRepository;
    private final TechnicianRepository technicianRepository;
    private final RepairOrderMapper mapper;

    public RepairOrderQueryService(RepairOrderRepository repairOrderRepository,
                                   TechnicianAssignmentRepository assignmentRepository,
                                   AccountRepository accountRepository,
                                   TechnicianRepository technicianRepository,
                                   RepairOrderMapper mapper) {
        this.repairOrderRepository = repairOrderRepository;
        this.assignmentRepository = assignmentRepository;
        this.accountRepository = accountRepository;
        this.technicianRepository = technicianRepository;
        this.mapper = mapper;
    }

    public List<RepairOrderResponse> getAll(Authentication authentication) {
        return repairOrderRepository.findOverviews(0, technicianScope(authentication))
                .stream().map(mapper::toResponse).toList();
    }

    public RepairOrderDetailResponse getById(Integer id, Authentication authentication) {
        if (id <= 0) {
            throw new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa.");
        }
        RepairOrderResponse order = repairOrderRepository.findOverviews(id, technicianScope(authentication))
                .stream().findFirst().map(mapper::toResponse)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
        return new RepairOrderDetailResponse(order,
                repairOrderRepository.findServiceLines(id).stream().map(mapper::toServiceLine).toList(),
                assignmentRepository.findAssignments(id));
    }

    private int technicianScope(Authentication authentication) {
        boolean technician = authentication.getAuthorities().stream()
                .anyMatch(authority -> authority.getAuthority().equals("ROLE_TECHNICIAN"));
        if (!technician) {
            return 0;
        }
        Account account = accountRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new UnauthorizedException("Bạn cần đăng nhập lại để xem công việc."));
        if (!account.isActive() || account.getRole() != AccountRole.TECHNICIAN
                || account.getEmployeeId() == null || account.getEmployeeId() <= 0
                || !technicianRepository.existsById(account.getEmployeeId())) {
            throw new ForbiddenException("Tài khoản chưa được liên kết với kỹ thuật viên.");
        }
        return account.getEmployeeId();
    }
}
