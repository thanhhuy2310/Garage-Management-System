package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.account.AccountResponse;
import com.gara.quanlygara.dto.account.CreateAccountRequest;
import com.gara.quanlygara.dto.account.EmployeeOptionResponse;
import com.gara.quanlygara.dto.account.UpdateAccountRequest;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.EmployeeRepository;
import com.gara.quanlygara.repository.TechnicianRepository;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.EnumSet;
import java.util.List;
import java.util.Set;

@Service
public class AccountService {

    private static final Set<AccountRole> STAFF_ROLES = EnumSet.of(
            AccountRole.RECEPTIONIST,
            AccountRole.TECHNICIAN,
            AccountRole.WAREHOUSE,
            AccountRole.MANAGER,
            AccountRole.ADMIN
    );

    private final AccountRepository accountRepository;
    private final CustomerRepository customerRepository;
    private final EmployeeRepository employeeRepository;
    private final TechnicianRepository technicianRepository;
    private final PasswordEncoder passwordEncoder;

    public AccountService(
            AccountRepository accountRepository,
            CustomerRepository customerRepository,
            EmployeeRepository employeeRepository,
            TechnicianRepository technicianRepository,
            PasswordEncoder passwordEncoder
    ) {
        this.accountRepository = accountRepository;
        this.customerRepository = customerRepository;
        this.employeeRepository = employeeRepository;
        this.technicianRepository = technicianRepository;
        this.passwordEncoder = passwordEncoder;
    }

    @Transactional(readOnly = true)
    public List<AccountResponse> getAll() {
        return accountRepository.findAll(Sort.by(Sort.Direction.ASC, "id"))
                .stream()
                .map(AccountResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public AccountResponse getById(Integer id) {
        return AccountResponse.from(findEntity(id));
    }

    @Transactional(readOnly = true)
    public List<EmployeeOptionResponse> getEmployeeOptions() {
        return employeeRepository.findAll(Sort.by(Sort.Direction.ASC, "id"))
                .stream()
                .map(employee -> EmployeeOptionResponse.from(
                        employee,
                        technicianRepository.existsById(employee.getId()),
                        accountRepository.existsByEmployeeId(employee.getId())
                ))
                .toList();
    }

    @Transactional
    public AccountResponse create(CreateAccountRequest request) {
        String username = normalizeUsername(request.username());
        if (accountRepository.existsByUsername(username)) {
            throw new ConflictException("Tên đăng nhập đã tồn tại.");
        }
        AccountRole role = AccountRole.from(request.role());
        validateStaffRole(role);
        validateAccountOwner(role, request.customerId(), request.employeeId());
        validateEmployeeAccountAvailable(request.employeeId(), null);

        Account account = new Account();
        account.setUsername(username);
        account.setPasswordHash(passwordEncoder.encode(request.password()));
        account.setRole(role);
        account.setActive(request.active() == null || request.active());
        account.setCustomerId(null);
        account.setEmployeeId(request.employeeId());
        return AccountResponse.from(accountRepository.save(account));
    }

    @Transactional
    public AccountResponse update(Integer id, UpdateAccountRequest request) {
        Account account = findEntity(id);
        ensureStaffAccount(account);
        String username = normalizeUsername(request.username());
        if (accountRepository.existsByUsernameAndIdNot(username, id)) {
            throw new ConflictException("Tên đăng nhập đã tồn tại.");
        }
        AccountRole role = AccountRole.from(request.role());
        validateStaffRole(role);
        validateAccountOwner(role, request.customerId(), request.employeeId());
        validateEmployeeAccountAvailable(request.employeeId(), id);

        account.setUsername(username);
        if (request.password() != null && !request.password().isBlank()) {
            account.setPasswordHash(passwordEncoder.encode(request.password()));
        }
        account.setRole(role);
        account.setActive(request.active() == null ? account.isActive() : request.active());
        account.setCustomerId(null);
        account.setEmployeeId(request.employeeId());
        return AccountResponse.from(accountRepository.save(account));
    }

    @Transactional
    public AccountResponse changeStatus(Integer id, boolean active) {
        Account account = findEntity(id);
        account.setActive(active);
        return AccountResponse.from(accountRepository.save(account));
    }

    @Transactional
    public AccountResponse changeRole(Integer id, String role) {
        Account account = findEntity(id);
        ensureStaffAccount(account);
        AccountRole newRole = AccountRole.from(role);
        validateStaffRole(newRole);
        validateAccountOwner(newRole, account.getCustomerId(), account.getEmployeeId());
        account.setRole(newRole);
        return AccountResponse.from(accountRepository.save(account));
    }

    public Account findEntity(Integer id) {
        return accountRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản có mã " + id + "."));
    }

    private String normalizeUsername(String username) {
        return username.trim();
    }

    void validateAccountOwner(AccountRole role, Integer customerId, Integer employeeId) {
        if (role == AccountRole.CUSTOMER) {
            if (customerId == null || employeeId != null) {
                throw new BadRequestException("Tài khoản khách hàng phải liên kết đúng một khách hàng và không được liên kết nhân viên.");
            }
            if (!customerRepository.existsById(customerId)) {
                throw new BadRequestException("Khách hàng được chọn không tồn tại.");
            }
            return;
        }

        if (!STAFF_ROLES.contains(role)) {
            throw new BadRequestException("Vai trò tài khoản không hợp lệ.");
        }
        if (employeeId == null || customerId != null) {
            throw new BadRequestException("Tài khoản nhân viên phải liên kết đúng một nhân viên và không được liên kết khách hàng.");
        }
        if (!employeeRepository.existsById(employeeId)) {
            throw new BadRequestException("Nhân viên được chọn không tồn tại.");
        }
        if (role == AccountRole.TECHNICIAN && !technicianRepository.existsById(employeeId)) {
            throw new BadRequestException("Nhân viên này chưa được khai báo là kỹ thuật viên.");
        }
    }

    private void validateStaffRole(AccountRole role) {
        if (!STAFF_ROLES.contains(role)) {
            throw new BadRequestException("Tài khoản khách hàng chỉ được tạo qua chức năng đăng ký công khai.");
        }
    }

    private void ensureStaffAccount(Account account) {
        if (account.getRole() == AccountRole.CUSTOMER || account.getCustomerId() != null) {
            throw new BadRequestException("Không thể đổi tài khoản khách hàng thành tài khoản nhân viên.");
        }
    }

    private void validateEmployeeAccountAvailable(Integer employeeId, Integer currentAccountId) {
        boolean used = currentAccountId == null
                ? accountRepository.existsByEmployeeId(employeeId)
                : accountRepository.existsByEmployeeIdAndIdNot(employeeId, currentAccountId);
        if (used) {
            throw new ConflictException("Nhân viên này đã có tài khoản.");
        }
    }
}
