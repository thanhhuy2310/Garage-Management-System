package com.gara.quanlygara.controller;
import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.reception.*;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.ReceptionService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/receptions")
@PreAuthorize("hasAnyRole('RECEPTIONIST','MANAGER')")
public class ReceptionController {
    private final ReceptionService service;
    private final StaffContext staff;
    public ReceptionController(ReceptionService service,StaffContext staff) { this.service=service; this.staff=staff; }
    @GetMapping
    public ApiResponse<List<ReceptionResponse>> list() { return ApiResponse.success("Danh sách tiếp nhận.",service.list()); }
    @GetMapping("/{id}")
    public ApiResponse<ReceptionResponse> get(@PathVariable int id) { return ApiResponse.success("Chi tiết tiếp nhận.",service.get(id)); }
    @PostMapping
    @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ReceptionResponse> create(@Valid @RequestBody ReceptionRequest input,Authentication auth) {
        return ApiResponse.success("Đã lưu phiếu tiếp nhận.",service.create(input,staff.account(auth)));
    }
    @PutMapping("/{id}")
    public ApiResponse<ReceptionResponse> update(@PathVariable int id,@Valid @RequestBody ReceptionUpdateRequest input,Authentication auth) {
        return ApiResponse.success("Đã cập nhật phiếu tiếp nhận.",service.update(id,input,staff.account(auth)));
    }
}
