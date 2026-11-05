package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.InsuranceLedger;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/insurance/claims/{id}/finance")
@PreAuthorize("hasAnyRole('MANAGER','RECEPTIONIST')")
public class InsuranceFinanceController {
    private final InsuranceLedger ledger;
    private final StaffContext staff;
    public InsuranceFinanceController(InsuranceLedger ledger,StaffContext staff) {this.ledger=ledger;this.staff=staff;}
    @GetMapping
    public ApiResponse<Map<String,Object>> view(@PathVariable int id) {
        return ApiResponse.success("Đối chiếu hồ sơ.",ledger.details(id));
    }
    @PostMapping("/proposals")
    public ApiResponse<Void> propose(@PathVariable int id,@Valid @RequestBody InsuranceLedger.Allocation input,Authentication auth) {
        ledger.propose(id,input,staff.employeeId(auth));
        return ApiResponse.success("Đã lưu đề nghị.");
    }
    @PostMapping("/manual-decision")
    public ApiResponse<Void> manualDecision(@PathVariable int id,@Valid @RequestBody InsuranceLedger.ManualDecision input,Authentication auth) {
        ledger.manualDecision(id,input,staff.employeeId(auth));
        return ApiResponse.success("Đã lưu quyết định và tính phần khách thanh toán.");
    }
    @PostMapping("/decisions")
    public ApiResponse<Void> decide(@PathVariable int id,@Valid @RequestBody InsuranceLedger.Decision input,Authentication auth) {
        ledger.decide(id,input,staff.employeeId(auth));
        return ApiResponse.success("Đã ghi nhận quyết định theo chứng từ.");
    }
    @PostMapping("/settlements")
    public ApiResponse<Void> settle(@PathVariable int id,@Valid @RequestBody InsuranceLedger.Settlement input,Authentication auth) {
        ledger.settle(id,input,staff.employeeId(auth));
        return ApiResponse.success("Đã phân bổ công nợ.");
    }
    @PostMapping("/close")
    public ApiResponse<Void> close(@PathVariable int id,@RequestParam int version,Authentication auth) {
        ledger.close(id,version,staff.employeeId(auth));
        return ApiResponse.success("Đã đóng hồ sơ.");
    }
}
