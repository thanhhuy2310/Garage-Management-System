package com.gara.quanlygara.security;

import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.StockIssueItemRepository;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Component;

@Component("repairAccess")
public class RepairAccessPolicy {
    private final AccountRepository accounts;
    private final StockIssueItemRepository assignments;
    public RepairAccessPolicy(AccountRepository accounts, StockIssueItemRepository assignments) {
        this.accounts = accounts;
        this.assignments = assignments;
    }
    public boolean canRead(Authentication auth, Integer orderId) {
        if (auth == null) return false;
        if (auth.getAuthorities().stream().noneMatch(a -> a.getAuthority().equals("ROLE_TECHNICIAN"))) return true;
        return accounts.findByUsername(auth.getName()).map(account -> account.isActive()
                && (account.getRole() != AccountRole.TECHNICIAN
                    || (account.getEmployeeId() != null && assignments.countAssignment(orderId, account.getEmployeeId()) > 0)))
                .orElse(false);
    }
}
