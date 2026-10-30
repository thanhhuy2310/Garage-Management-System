package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.quotation.QuotationDtos.*;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.QuotationService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/quotations")
@PreAuthorize("hasAnyRole('CUSTOMER','RECEPTIONIST','MANAGER')")
public class QuotationController {
    private final QuotationService service;private final StaffContext context;
    public QuotationController(QuotationService service,StaffContext context) {this.service=service;this.context=context;}
    @GetMapping
    public ApiResponse<List<View>> list(Authentication auth) {return ApiResponse.success("Danh sách báo giá.",service.list(context.account(auth)));}
    @GetMapping("/{id}")
    public ApiResponse<View> get(@PathVariable int id,Authentication auth) {return ApiResponse.success("Chi tiết báo giá.",service.get(id,context.account(auth)));}
    @GetMapping("/{id}/history")
    public ApiResponse<List<Audit>> history(@PathVariable int id,Authentication auth) {return ApiResponse.success("Lịch sử báo giá.",service.history(id,context.account(auth)));}
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    @PreAuthorize("hasAnyRole('RECEPTIONIST','MANAGER')")
    public ApiResponse<View> create(@Valid @RequestBody Create input,Authentication auth) {return ApiResponse.success("Đã lưu bản nháp.",service.create(input,context.account(auth)));}
    @PutMapping("/{id}")
    @PreAuthorize("hasAnyRole('RECEPTIONIST','MANAGER')")
    public ApiResponse<View> edit(@PathVariable int id,@Valid @RequestBody Edit input,Authentication auth) {return ApiResponse.success("Đã cập nhật bản nháp.",service.edit(id,input,context.account(auth)));}
    @PostMapping("/{id}/send")
    @PreAuthorize("hasAnyRole('RECEPTIONIST','MANAGER')")
    public ApiResponse<View> send(@PathVariable int id,@Valid @RequestBody Change input,Authentication auth) {return ApiResponse.success("Đã gửi khách xác nhận.",service.send(id,input,context.account(auth)));}
    @PostMapping("/{id}/revise")
    @PreAuthorize("hasAnyRole('RECEPTIONIST','MANAGER')")
    public ApiResponse<View> revise(@PathVariable int id,@Valid @RequestBody Change input,Authentication auth) {return ApiResponse.success("Đã tạo lần điều chỉnh. Nội dung trước được giữ trong lịch sử.",service.revise(id,input,context.account(auth)));}
    @PostMapping("/{id}/decision")
    @PreAuthorize("hasRole('CUSTOMER')")
    public ApiResponse<View> decide(@PathVariable int id,@Valid @RequestBody Decision input,Authentication auth) {return ApiResponse.success("Đã ghi nhận quyết định.",service.decide(id,input,context.account(auth)));}
}
