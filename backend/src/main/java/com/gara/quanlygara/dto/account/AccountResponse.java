package com.gara.quanlygara.dto.account;

import com.gara.quanlygara.entity.Account;

public record AccountResponse(
        Integer id,
        String username,
        String role,
        boolean active,
        Integer customerId,
        Integer employeeId
) {
    public static AccountResponse from(Account account) {
        return new AccountResponse(
                account.getId(),
                account.getUsername(),
                account.getRole().name(),
                account.isActive(),
                account.getCustomerId(),
                account.getEmployeeId()
        );
    }
}
