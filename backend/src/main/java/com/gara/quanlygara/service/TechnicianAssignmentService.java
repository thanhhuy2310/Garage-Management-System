package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.technician.TechnicianAssignmentRequest;
import com.gara.quanlygara.dto.technician.TechnicianAssignmentResponse;
import com.gara.quanlygara.dto.technician.TechnicianRepairOrderResponse;
import com.gara.quanlygara.dto.technician.TechnicianResponse;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.TechnicianAssignment;
import com.gara.quanlygara.entity.TechnicianAssignmentId;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ForbiddenException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.exception.UnauthorizedException;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.RepairOrderRepository;
import com.gara.quanlygara.repository.TechnicianAssignmentRepository;
import com.gara.quanlygara.repository.TechnicianRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;

@Service
public class TechnicianAssignmentService {

    private static final String DUPLICATE_ASSIGNMENT = "Kỹ thuật viên đã được phân công cho phiếu sửa chữa này.";

    private final RepairOrderRepository repairOrderRepository;
    private final TechnicianRepository technicianRepository;
    private final TechnicianAssignmentRepository assignmentRepository;
    private final AccountRepository accountRepository;

    public TechnicianAssignmentService(RepairOrderRepository repairOrderRepository,
                                       TechnicianRepository technicianRepository,
                                       TechnicianAssignmentRepository assignmentRepository,
                                       AccountRepository accountRepository) {
        this.repairOrderRepository = repairOrderRepository;
        this.technicianRepository = technicianRepository;
        this.assignmentRepository = assignmentRepository;
        this.accountRepository = accountRepository;
    }

    @Transactional(readOnly = true)
    public List<TechnicianResponse> getTechnicians() {
        return technicianRepository.findOptions();
    }

    @Transactional(readOnly = true)
    public List<TechnicianAssignmentResponse> getAssignments(Integer repairOrderId) {
        requireRepairOrder(repairOrderId);
        return assignmentRepository.findAssignments(repairOrderId);
    }

    @Transactional
    public TechnicianAssignmentResponse assign(Integer repairOrderId, TechnicianAssignmentRequest request) {
        requireRepairOrder(repairOrderId);
        TechnicianResponse technician = technicianRepository.findOptionById(request.technicianId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy kỹ thuật viên."));
        TechnicianAssignmentId id = new TechnicianAssignmentId(repairOrderId, technician.id());
        if (assignmentRepository.existsById(id)) {
            throw new ConflictException(DUPLICATE_ASSIGNMENT);
        }

        TechnicianAssignment assignment = new TechnicianAssignment();
        assignment.setId(id);
        assignment.setAssignedAt(LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).withNano(0));
        assignment.setNotes(request.notes());
        try {
            assignmentRepository.saveAndFlush(assignment);
        } catch (DataIntegrityViolationException exception) {
            if (isDuplicateKey(exception)) {
                throw new ConflictException(DUPLICATE_ASSIGNMENT);
            }
            throw exception;
        }
        return new TechnicianAssignmentResponse(repairOrderId, technician,
                assignment.getAssignedAt(), assignment.getNotes());
    }

    @Transactional(readOnly = true)
    public List<TechnicianRepairOrderResponse> getMyRepairOrders(String username) {
        Account account = accountRepository.findByUsername(username)
                .orElseThrow(() -> new UnauthorizedException("Bạn cần đăng nhập lại để xem công việc."));
        if (!account.isActive() || account.getRole() != AccountRole.TECHNICIAN
                || account.getEmployeeId() == null
                || !technicianRepository.existsById(account.getEmployeeId())) {
            throw new ForbiddenException("Tài khoản chưa được liên kết với kỹ thuật viên đang sử dụng hệ thống.");
        }
        return assignmentRepository.findRepairOrders(account.getEmployeeId());
    }

    private void requireRepairOrder(Integer id) {
        if (!repairOrderRepository.existsById(id)) {
            throw new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa.");
        }
    }

    private boolean isDuplicateKey(Throwable exception) {
        for (Throwable cause = exception; cause != null; cause = cause.getCause()) {
            if (cause instanceof SQLException sql && (sql.getErrorCode() == 2627
                    || sql.getErrorCode() == 2601 || "23505".equals(sql.getSQLState()))) {
                return true;
            }
        }
        return false;
    }
}
