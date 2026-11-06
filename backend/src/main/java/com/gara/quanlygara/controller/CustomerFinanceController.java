package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.CustomerFinanceService;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/customers/me")
@PreAuthorize("hasRole('CUSTOMER')")
public class CustomerFinanceController {
    private final CustomerFinanceService finance;private final StaffContext context;
    public CustomerFinanceController(CustomerFinanceService finance,StaffContext context){this.finance=finance;this.context=context;}
    private int customer(Authentication auth){var id=context.account(auth).getCustomerId();if(id==null)throw new AccessDeniedException("Tài khoản chưa liên kết khách hàng.");return id;}
    @GetMapping("/invoices")
    public Object invoices(Authentication auth,@RequestParam(required=false) Integer vehicleId){return ApiResponse.success("Hóa đơn của tôi.",finance.invoices(customer(auth),vehicleId));}
    @GetMapping("/invoices/{id}")
    public Object invoice(Authentication auth,@PathVariable int id){return ApiResponse.success("Chi tiết hóa đơn.",finance.invoice(customer(auth),id));}
    @GetMapping("/statistics")
    public Object stats(Authentication auth,@RequestParam(required=false) Integer vehicleId,@RequestParam(required=false) Integer year){return ApiResponse.success("Thống kê xe của tôi.",finance.statistics(customer(auth),vehicleId,year));}
}
