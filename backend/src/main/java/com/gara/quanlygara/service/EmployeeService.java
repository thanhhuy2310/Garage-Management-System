package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.employee.*;
import com.gara.quanlygara.entity.*;
import com.gara.quanlygara.exception.*;
import com.gara.quanlygara.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class EmployeeService {
    private final EmployeeRepository employees;
    private final TechnicianRepository technicians;
    private final AccountRepository accounts;
    private final TechnicianAssignmentRepository assignments;

    public EmployeeService(EmployeeRepository employees, TechnicianRepository technicians,
                           AccountRepository accounts, TechnicianAssignmentRepository assignments) {
        this.employees = employees;
        this.technicians = technicians;
        this.accounts = accounts;
        this.assignments = assignments;
    }

    public List<EmployeeResponse> list() { return employees.findOverview(); }

    public EmployeeResponse get(Integer id) {
        return response(employees.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy nhân viên.")));
    }

    @Transactional
    public EmployeeResponse create(EmployeeRequest request) {
        Employee employee = new Employee();
        apply(employee, request);
        employees.saveAndFlush(employee);
        syncTechnician(employee.getId(), request.technician());
        return response(employee);
    }

    @Transactional
    public EmployeeResponse update(Integer id, EmployeeRequest request) {
        Employee employee = employees.findForUpdate(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy nhân viên."));
        syncTechnician(id, request.technician());
        apply(employee, request);
        employees.flush();
        return response(employee);
    }

    private void syncTechnician(Integer id, boolean enabled) {
        var existing = technicians.findForUpdate(id);
        if (enabled && existing.isEmpty()) {
            Technician technician = new Technician();
            technician.setEmployeeId(id);
            technicians.saveAndFlush(technician);
        } else if (!enabled && existing.isPresent()) {
            if (assignments.existsById_TechnicianId(id)
                    || accounts.findByEmployeeId(id).map(a -> a.getRole() == AccountRole.TECHNICIAN).orElse(false)) {
                throw new ConflictException("Không thể bỏ kỹ thuật viên đã có lịch sử phân công hoặc tài khoản KTV.");
            }
            technicians.delete(existing.get());
            technicians.flush();
        }
    }

    private void apply(Employee employee, EmployeeRequest request) {
        employee.setFullName(request.fullName().trim());
        employee.setPhone(clean(request.phone()));
        employee.setEmail(clean(request.email()));
        employee.setPosition(request.position().trim());
    }

    private String clean(String value) { return value == null || value.isBlank() ? null : value.trim(); }

    private EmployeeResponse response(Employee employee) {
        Account account = accounts.findByEmployeeId(employee.getId()).orElse(null);
        return new EmployeeResponse(employee.getId(), employee.getFullName(), employee.getPhone(),
                employee.getEmail(), employee.getPosition(), technicians.existsById(employee.getId()),
                account == null ? null : account.getUsername(), account == null ? null : account.getRole().name(),
                account == null ? null : account.isActive());
    }
}
