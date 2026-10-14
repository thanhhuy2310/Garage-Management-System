// TV3-TUAN8
package com.gara.quanlygara.security;

import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.repository.AccountRepository;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

/** Xác định nhân viên (MaNhanVien) và vai trò của tài khoản đang đăng nhập, từ JWT hiện có. */
@Component
public class StaffContext {

    private final AccountRepository accountRepository;

    public StaffContext(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    public Account account(Authentication authentication) {
        if (authentication == null) throw new AccessDeniedException("Chưa đăng nhập.");
        return accountRepository.findByUsername(authentication.getName())
                .orElseThrow(() -> new AccessDeniedException("Không xác định được tài khoản."));
    }

    public Integer employeeId(Authentication authentication) {
        Integer employeeId = account(authentication).getEmployeeId();
        if (employeeId == null) {
            throw new BadRequestException("Tài khoản chưa được liên kết với nhân viên.");
        }
        return employeeId;
    }

    public boolean isTechnician(Authentication authentication) {
        return account(authentication).getRole() == AccountRole.TECHNICIAN;
    }
}
