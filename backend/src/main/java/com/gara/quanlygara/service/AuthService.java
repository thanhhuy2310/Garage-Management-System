package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.account.AccountResponse;
import com.gara.quanlygara.dto.auth.ChangePasswordRequest;
import com.gara.quanlygara.dto.auth.LoginRequest;
import com.gara.quanlygara.dto.auth.LoginResponse;
import com.gara.quanlygara.dto.auth.RegisterRequest;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.Customer;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ForbiddenException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.exception.UnauthorizedException;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.security.JwtService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final AccountRepository accountRepository;
    private final CustomerRepository customerRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(
            AccountRepository accountRepository,
            CustomerRepository customerRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService
    ) {
        this.accountRepository = accountRepository;
        this.customerRepository = customerRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
    }

    @Transactional(readOnly = true)
    public LoginResponse login(LoginRequest request) {
        Account account = accountRepository.findByUsername(request.username().trim())
                .orElseThrow(() -> new UnauthorizedException("Tên đăng nhập hoặc mật khẩu không đúng."));

        if (!account.isActive()) {
            throw new ForbiddenException("Tài khoản đã bị khóa.");
        }
        if (!passwordEncoder.matches(request.password(), account.getPasswordHash())) {
            throw new UnauthorizedException("Tên đăng nhập hoặc mật khẩu không đúng.");
        }

        return issueToken(account);
    }

    @Transactional
    public LoginResponse register(RegisterRequest request) {
        String username = request.username().trim();
        String phone = request.phone().trim();
        if (accountRepository.existsByUsername(username)) {
            throw new ConflictException("Tên đăng nhập đã tồn tại.");
        }
        if (customerRepository.existsByPhone(phone)) {
            throw new ConflictException("Số điện thoại đã được sử dụng.");
        }

        Customer customer = new Customer();
        customer.setFullName(request.fullName().trim());
        customer.setPhone(phone);
        customer.setEmail(normalizeOptional(request.email()));
        customer.setAddress(normalizeOptional(request.address()));
        customer = customerRepository.save(customer);

        Account account = new Account();
        account.setUsername(username);
        account.setPasswordHash(passwordEncoder.encode(request.password()));
        account.setRole(AccountRole.CUSTOMER);
        account.setActive(true);
        account.setCustomerId(customer.getId());
        account = accountRepository.save(account);
        return issueToken(account);
    }

    @Transactional(readOnly = true)
    public AccountResponse getCurrentUser(String username) {
        return AccountResponse.from(findByUsername(username));
    }

    @Transactional
    public void changePassword(String username, ChangePasswordRequest request) {
        Account account = findByUsername(username);
        if (!passwordEncoder.matches(request.currentPassword(), account.getPasswordHash())) {
            throw new UnauthorizedException("Mật khẩu hiện tại không đúng.");
        }
        account.setPasswordHash(passwordEncoder.encode(request.newPassword()));
        accountRepository.save(account);
    }

    private Account findByUsername(String username) {
        return accountRepository.findByUsername(username)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy tài khoản đang đăng nhập."));
    }

    private LoginResponse issueToken(Account account) {
        return new LoginResponse(
                jwtService.generateToken(account),
                "Bearer",
                jwtService.getExpirationSeconds(),
                AccountResponse.from(account)
        );
    }

    private String normalizeOptional(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
