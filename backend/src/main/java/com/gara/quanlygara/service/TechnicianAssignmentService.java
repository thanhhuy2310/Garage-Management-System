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
    private final RepairBusinessRules rules;

    private static final String DUPLICATE_ASSIGNMENT = "Kỹ thuật viên đã được phân công cho phiếu sửa chữa này.";

    private final RepairOrderRepository repairOrderRepository;
    private final TechnicianRepository technicianRepository;
    private final TechnicianAssignmentRepository assignmentRepository;
    private final AccountRepository accountRepository;
    private final TechnicianWorkloadService workload;

    public TechnicianAssignmentService(RepairOrderRepository repairOrderRepository,
                                       TechnicianRepository technicianRepository,
                                       TechnicianAssignmentRepository assignmentRepository,
                                       AccountRepository accountRepository, RepairBusinessRules rules,
                                       TechnicianWorkloadService workload) {
        this.workload = workload;
        this.rules = rules;
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
        // Serialize capacity checks before locking individual orders. Two requests for
        // the same technician must not each hold an order while waiting for this lock.
        technicianRepository.findForUpdate(request.technicianId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy kỹ thuật viên."));
        var order = repairOrderRepository.findForUpdate(repairOrderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
        if (java.util.Set.of("HOAN_TAT", "HUY", "DA_HUY").contains(order.getStatus())) {
            throw new ConflictException("Phiếu đã kết thúc, không thể phân công thêm kỹ thuật viên.");
        }
        if (!java.util.Set.of("MOI_TAO", "DANG_KIEM_TRA").contains(order.getStatus())) {
            rules.requireAcceptedQuote(repairOrderId);
        }
        TechnicianResponse technician = technicianRepository.findOptionById(request.technicianId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy kỹ thuật viên."));
        TechnicianAssignmentId id = new TechnicianAssignmentId(repairOrderId, technician.id());
        if (assignmentRepository.existsById(id)) {
            throw new ConflictException(DUPLICATE_ASSIGNMENT);
        }
        workload.requireAssignable(technician.id());

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

    @Transactional
    public TechnicianAssignmentResponse transfer(int orderId, int previousTechnician,
                                                 TechnicianAssignmentRequest request, String actor) {
        int nextTechnician = request.technicianId();
        if (previousTechnician == nextTechnician) {
            throw new ConflictException("Vui lòng chọn kỹ thuật viên khác để bàn giao.");
        }
        // Opposite handovers acquire both workload locks in the same order.
        for (int id : List.of(Math.min(previousTechnician, nextTechnician), Math.max(previousTechnician, nextTechnician))) {
            technicianRepository.findForUpdate(id)
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy kỹ thuật viên."));
        }
        rules.lock(orderId);
        var previous = assignmentRepository.findById(new TechnicianAssignmentId(orderId, previousTechnician))
                .orElseThrow(() -> new ConflictException("Phân công đã thay đổi. Vui lòng tải lại phiếu."));
        var replacement = assign(orderId, request);
        String history = "Bàn giao từ KTV #" + previousTechnician + " sang KTV #" + nextTechnician
                + ". Phân công trước vào " + previous.getAssignedAt()
                + (previous.getNotes() == null ? "." : ". Ghi chú cũ: " + previous.getNotes());
        assignmentRepository.recordTransfer(orderId, history, actor, replacement.assignedAt());
        assignmentRepository.delete(previous);
        assignmentRepository.flush();
        return replacement;
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
