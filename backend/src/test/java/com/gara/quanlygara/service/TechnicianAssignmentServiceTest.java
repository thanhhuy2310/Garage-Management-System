package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.technician.TechnicianAssignmentRequest;
import com.gara.quanlygara.dto.technician.TechnicianResponse;
import com.gara.quanlygara.entity.TechnicianAssignment;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.RepairOrderRepository;
import com.gara.quanlygara.repository.TechnicianAssignmentRepository;
import com.gara.quanlygara.repository.TechnicianRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.dao.DataIntegrityViolationException;

import java.sql.SQLException;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TechnicianAssignmentServiceTest {

    @Mock private RepairOrderRepository repairOrderRepository;
    @Mock private TechnicianRepository technicianRepository;
    @Mock private TechnicianAssignmentRepository assignmentRepository;
    @Mock private AccountRepository accountRepository;

    private TechnicianAssignmentService service;

    @BeforeEach
    void setUp() {
        service = new TechnicianAssignmentService(repairOrderRepository, technicianRepository,
                assignmentRepository, accountRepository);
        var order = new com.gara.quanlygara.entity.RepairOrder();
        order.setId(1);
        order.setStatus("DANG_SUA");
        when(repairOrderRepository.findForUpdate(1)).thenReturn(Optional.of(order));
        when(technicianRepository.findOptionById(2))
                .thenReturn(Optional.of(new TechnicianResponse(2, "Kỹ thuật viên")));
    }

    @ParameterizedTest
    @ValueSource(ints = {2627, 2601})
    void duplicateDuringInsertReturnsBusinessConflict(int sqlServerError) {
        when(assignmentRepository.saveAndFlush(any(TechnicianAssignment.class)))
                .thenThrow(new DataIntegrityViolationException("duplicate",
                        new SQLException("duplicate", "23000", sqlServerError)));
        var exception = assertThrows(ConflictException.class,
                () -> service.assign(1, new TechnicianAssignmentRequest(2, null)));
        assertEquals("Kỹ thuật viên đã được phân công cho phiếu sửa chữa này.", exception.getMessage());
    }

    @Test
    void otherConstraintFailuresAreNotReportedAsDuplicateAssignments() {
        var failure = new DataIntegrityViolationException("foreign key",
                new SQLException("foreign key", "23000", 547));
        when(assignmentRepository.saveAndFlush(any(TechnicianAssignment.class))).thenThrow(failure);
        assertSame(failure, assertThrows(DataIntegrityViolationException.class,
                () -> service.assign(1, new TechnicianAssignmentRequest(2, null))));
    }
}
