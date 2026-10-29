package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.appointment.AppointmentDtos.*;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.AppointmentService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.http.HttpStatus;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/appointments")
@PreAuthorize("hasAnyRole('CUSTOMER','RECEPTIONIST','MANAGER')")
public class AppointmentController {
    private final AppointmentService service;
    private final StaffContext context;
    public AppointmentController(AppointmentService service, StaffContext context) { this.service=service; this.context=context; }
    @GetMapping
    public ApiResponse<List<View>> list(Authentication auth) { return ApiResponse.success("Danh sách lịch hẹn.",service.list(context.account(auth))); }
    @GetMapping("/availability")
    public ApiResponse<Availability> availability(@RequestParam LocalDate date) { return ApiResponse.success("Khung giờ tiếp nhận.",service.availability(date)); }
    @GetMapping("/schedule")
    @PreAuthorize("hasRole('MANAGER')")
    public ApiResponse<List<Schedule>> schedule() { return ApiResponse.success("Cấu hình khung giờ.",service.schedule()); }
    @PutMapping("/schedule")
    @PreAuthorize("hasRole('MANAGER')")
    public ApiResponse<List<Schedule>> schedule(@Valid @RequestBody Schedule input, Authentication auth) {
        return ApiResponse.success("Đã lưu khung giờ.",service.configure(input,context.account(auth)));
    }
    @GetMapping("/{id}")
    public ApiResponse<View> get(@PathVariable int id, Authentication auth) { return ApiResponse.success("Chi tiết lịch hẹn.",service.get(id,context.account(auth))); }
    @GetMapping("/{id}/history")
    public ApiResponse<List<Audit>> history(@PathVariable int id, Authentication auth) { return ApiResponse.success("Lịch sử thay đổi.",service.history(id,context.account(auth))); }
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<View> create(@Valid @RequestBody Create input, Authentication auth) { return ApiResponse.success("Đã đặt lịch.",service.create(input,context.account(auth))); }
    @PatchMapping("/{id}/reschedule")
    public ApiResponse<View> move(@PathVariable int id,@Valid @RequestBody Move input,Authentication auth) { return ApiResponse.success("Đã dời lịch, chờ gara xác nhận.",service.move(id,input,context.account(auth))); }
    @PatchMapping("/{id}/cancel")
    public ApiResponse<View> cancel(@PathVariable int id,@Valid @RequestBody Change input,Authentication auth) { return ApiResponse.success("Đã hủy lịch.",service.cancel(id,input,context.account(auth))); }
    @PatchMapping("/{id}/confirm")
    @PreAuthorize("hasAnyRole('RECEPTIONIST','MANAGER')")
    public ApiResponse<View> confirm(@PathVariable int id,@Valid @RequestBody Change input,Authentication auth) { return ApiResponse.success("Đã xác nhận lịch.",service.confirm(id,input,context.account(auth))); }
}
