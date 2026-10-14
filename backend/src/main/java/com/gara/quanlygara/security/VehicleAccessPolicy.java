package com.gara.quanlygara.security;

import com.gara.quanlygara.repository.AccountRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

/**
 * Dùng trong @PreAuthorize: tài khoản CUSTOMER chỉ được thao tác trên xe của chính mình.
 */
@Component("vehicleAccess")
public class VehicleAccessPolicy {

    private final AccountRepository accountRepository;

    public VehicleAccessPolicy(AccountRepository accountRepository) {
        this.accountRepository = accountRepository;
    }

    public boolean ownsCustomer(Authentication authentication, Integer customerId) {
        if (authentication == null || customerId == null) return false;
        return accountRepository.findByUsername(authentication.getName())
                .map(account -> customerId.equals(account.getCustomerId()))
                .orElse(false);
    }
}
