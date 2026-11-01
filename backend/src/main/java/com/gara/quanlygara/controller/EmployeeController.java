package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.employee.*;
import com.gara.quanlygara.service.EmployeeService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/employees")
@PreAuthorize("hasRole('MANAGER')")
public class EmployeeController {
    private final EmployeeService service;
    public EmployeeController(EmployeeService service) { this.service = service; }

    @GetMapping
    public ApiResponse<List<EmployeeResponse>> list() { return ApiResponse.success("Danh sách nhân viên.", service.list()); }
    @GetMapping("/{id}")
    public ApiResponse<EmployeeResponse> get(@PathVariable Integer id) { return ApiResponse.success("Thông tin nhân viên.", service.get(id)); }
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<EmployeeResponse> create(@Valid @RequestBody EmployeeRequest request) {
        return ApiResponse.success("Đã thêm nhân viên.", service.create(request));
    }
    @PutMapping("/{id}")
    public ApiResponse<EmployeeResponse> update(@PathVariable Integer id, @Valid @RequestBody EmployeeRequest request) {
        return ApiResponse.success("Đã cập nhật nhân viên.", service.update(id, request));
    }
}
