package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.account.AccountResponse;
import com.gara.quanlygara.dto.account.CreateAccountRequest;
import com.gara.quanlygara.dto.account.UpdateAccountRequest;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.AccountRepository;
import org.springframework.data.domain.Sort;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class AccountService {

    private final AccountRepository accountRepository;
    private final PasswordEncoder passwordEncoder;

    public AccountService(AccountRepository accountRepository, PasswordEncoder passwordEncoder) {
        this.accountRepository = accountRepository;
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

    @Transactional
    public AccountResponse create(CreateAccountRequest request) {
        String username = normalizeUsername(request.username());
        if (accountRepository.existsByUsername(username)) {
            throw new ConflictException("Tên đăng nhập đã tồn tại.");
        }
        validateOwner(request.customerId(), request.employeeId());

        Account account = new Account();
        account.setUsername(username);
        account.setPasswordHash(passwordEncoder.encode(request.password()));
        account.setRole(AccountRole.from(request.role()));
        account.setActive(request.active() == null || request.active());
        account.setCustomerId(request.customerId());
        account.setEmployeeId(request.employeeId());
        return AccountResponse.from(accountRepository.save(account));
    }

    @Transactional
    public AccountResponse update(Integer id, UpdateAccountRequest request) {
        Account account = findEntity(id);
        String username = normalizeUsername(request.username());
        if (accountRepository.existsByUsernameAndIdNot(username, id)) {
            throw new ConflictException("Tên đăng nhập đã tồn tại.");
        }
        validateOwner(request.customerId(), request.employeeId());

        account.setUsername(username);
        if (request.password() != null && !request.password().isBlank()) {
            account.setPasswordHash(passwordEncoder.encode(request.password()));
        }
        account.setRole(AccountRole.from(request.role()));
        account.setActive(request.active() == null ? account.isActive() : request.active());
        account.setCustomerId(request.customerId());
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
        account.setRole(AccountRole.from(role));
        return AccountResponse.from(accountRepository.save(account));
    }

    public Account findEntity(Integer id) {
        return accountRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản có mã " + id + "."));
    }

    private String normalizeUsername(String username) {
        return username.trim();
    }

    private void validateOwner(Integer customerId, Integer employeeId) {
        boolean hasCustomer = customerId != null;
        boolean hasEmployee = employeeId != null;
        if (hasCustomer == hasEmployee) {
            throw new BadRequestException("Tài khoản phải liên kết đúng một khách hàng hoặc một nhân viên.");
        }
    }
}
