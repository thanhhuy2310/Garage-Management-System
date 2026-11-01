package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.report.DashboardResponse;
import com.gara.quanlygara.service.DashboardService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/reports/dashboard")
@PreAuthorize("hasRole('MANAGER')")
public class DashboardController {
    private final DashboardService service;
    public DashboardController(DashboardService service) { this.service=service; }
    @GetMapping
    public ApiResponse<DashboardResponse> get() { return ApiResponse.success("Số liệu tổng quan.",service.get()); }
}
