package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.account.AccountResponse;
import com.gara.quanlygara.dto.account.AccountRoleRequest;
import com.gara.quanlygara.dto.account.AccountStatusRequest;
import com.gara.quanlygara.dto.account.CreateAccountRequest;
import com.gara.quanlygara.dto.account.EmployeeOptionResponse;
import com.gara.quanlygara.dto.account.UpdateAccountRequest;
import com.gara.quanlygara.service.AccountService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/accounts")
@PreAuthorize("hasRole('ADMIN')")
public class AccountController {

    private final AccountService accountService;

    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<AccountResponse>>> getAll() {
        return ResponseEntity.ok(ApiResponse.success("Lấy danh sách tài khoản thành công.", accountService.getAll()));
    }

    @GetMapping("/staff-options")
    public ResponseEntity<ApiResponse<List<EmployeeOptionResponse>>> getStaffOptions() {
        return ResponseEntity.ok(ApiResponse.success(
                "Lấy danh sách nhân viên thành công.",
                accountService.getEmployeeOptions()
        ));
    }

    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<AccountResponse>> getById(@PathVariable Integer id) {
        return ResponseEntity.ok(ApiResponse.success("Lấy tài khoản thành công.", accountService.getById(id)));
    }

    @PostMapping
    public ResponseEntity<ApiResponse<AccountResponse>> create(@Valid @RequestBody CreateAccountRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(ApiResponse.success("Tạo tài khoản thành công.", accountService.create(request)));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<AccountResponse>> update(
            @PathVariable Integer id,
            @Valid @RequestBody UpdateAccountRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success("Cập nhật tài khoản thành công.", accountService.update(id, request)));
    }

    @PatchMapping("/{id}/status")
    public ResponseEntity<ApiResponse<AccountResponse>> changeStatus(
            @PathVariable Integer id,
            @Valid @RequestBody AccountStatusRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                "Cập nhật trạng thái tài khoản thành công.",
                accountService.changeStatus(id, request.active())
        ));
    }

    @PatchMapping("/{id}/role")
    public ResponseEntity<ApiResponse<AccountResponse>> changeRole(
            @PathVariable Integer id,
            @Valid @RequestBody AccountRoleRequest request
    ) {
        return ResponseEntity.ok(ApiResponse.success(
                "Cập nhật vai trò tài khoản thành công.",
                accountService.changeRole(id, request.role())
        ));
    }
}
