package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.account.AccountResponse;
import com.gara.quanlygara.dto.auth.ChangePasswordRequest;
import com.gara.quanlygara.dto.auth.LoginRequest;
import com.gara.quanlygara.dto.auth.LoginResponse;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.exception.ForbiddenException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.exception.UnauthorizedException;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.security.JwtService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final AccountRepository accountRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;

    public AuthService(
            AccountRepository accountRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService
    ) {
        this.accountRepository = accountRepository;
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

        return new LoginResponse(
                jwtService.generateToken(account),
                "Bearer",
                jwtService.getExpirationSeconds(),
                AccountResponse.from(account)
        );
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
}
