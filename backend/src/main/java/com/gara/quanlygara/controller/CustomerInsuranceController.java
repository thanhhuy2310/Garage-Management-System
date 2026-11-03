package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.InsuranceLedger;
import com.gara.quanlygara.service.QuotationService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/customers/me/quotations")
@PreAuthorize("hasRole('CUSTOMER')")
public class CustomerInsuranceController {
    private final QuotationService quotes;
    private final InsuranceLedger ledger;
    private final StaffContext staff;
    public CustomerInsuranceController(QuotationService quotes,InsuranceLedger ledger,StaffContext staff) {
        this.quotes=quotes;this.ledger=ledger;this.staff=staff;
    }
    @GetMapping("/{id}/insurance")
    public ApiResponse<InsuranceLedger.CustomerShare> get(@PathVariable int id,Authentication auth) {
        var quote=quotes.get(id,staff.account(auth));
        return ApiResponse.success("Phần chi phí theo hồ sơ của khách.",ledger.customerShare(quote));
    }
}
