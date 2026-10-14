package com.gara.quanlygara.controller;
import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.billing.BankAccountRequest;
import com.gara.quanlygara.entity.ReceivingBankAccount;
import com.gara.quanlygara.service.ReceivingBankAccountService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/bank-accounts")
public class ReceivingBankAccountController {
    private final ReceivingBankAccountService banks;
    public ReceivingBankAccountController(ReceivingBankAccountService banks) { this.banks = banks; }
    @GetMapping @PreAuthorize("hasAnyRole('ADMIN','MANAGER','RECEPTIONIST')")
    public ApiResponse<List<ReceivingBankAccount>> getAll() {
        return ApiResponse.success("Tài khoản nhận tiền của gara.", banks.getAll());
    }
    @PostMapping @ResponseStatus(HttpStatus.CREATED) @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    public ApiResponse<ReceivingBankAccount> create(@Valid @RequestBody BankAccountRequest request) {
        return ApiResponse.success("Đã thêm tài khoản ngân hàng.", banks.save(null, request));
    }
    @PutMapping("/{id}") @PreAuthorize("hasAnyRole('ADMIN','MANAGER')")
    public ApiResponse<ReceivingBankAccount> update(@PathVariable Integer id, @Valid @RequestBody BankAccountRequest request) {
        return ApiResponse.success("Đã cập nhật tài khoản ngân hàng.", banks.save(id, request));
    }
}
