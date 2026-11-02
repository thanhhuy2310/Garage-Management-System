package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.security.StaffContext;
import com.gara.quanlygara.service.ClaimCaseworkService;
import jakarta.validation.Valid;
import org.springframework.http.*;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.Map;

@RestController
@RequestMapping("/api/insurance/claims/{id}")
@PreAuthorize("hasAnyRole('MANAGER','RECEPTIONIST')")
public class ClaimCaseworkController {
    private final ClaimCaseworkService cases;
    private final StaffContext staff;
    public ClaimCaseworkController(ClaimCaseworkService cases,StaffContext staff) { this.cases=cases; this.staff=staff; }

    @GetMapping("/casework")
    public ApiResponse<Map<String,Object>> overview(@PathVariable int id) {
        return ApiResponse.success("Chi tiết xử lý.",cases.overview(id));
    }
    @PutMapping("/follow-up")
    public ApiResponse<Void> update(@PathVariable int id,@Valid @RequestBody ClaimCaseworkService.FollowUp input,Authentication auth) {
        cases.followUp(id,input,staff.employeeId(auth));
        return ApiResponse.success("Đã cập nhật hồ sơ.");
    }
    @PostMapping("/assessments")
    public ApiResponse<Void> assess(@PathVariable int id,@Valid @RequestBody ClaimCaseworkService.Assessment input,Authentication auth) {
        cases.assess(id,input,staff.employeeId(auth));
        return ApiResponse.success("Đã lưu kết quả giám định.");
    }
    @PostMapping(value="/documents",consumes=MediaType.MULTIPART_FORM_DATA_VALUE)
    public ApiResponse<Void> upload(@PathVariable int id,@RequestParam int version,@RequestParam String category,
                                    @RequestParam MultipartFile file,Authentication auth) throws IOException {
        cases.upload(id,version,category,file,staff.employeeId(auth));
        return ApiResponse.success("Đã lưu chứng từ.");
    }
    @GetMapping("/documents/{document}")
    public ResponseEntity<byte[]> download(@PathVariable int id,@PathVariable int document) {
        var file=cases.download(id,document);
        return ResponseEntity.ok().cacheControl(CacheControl.noStore())
                .header(HttpHeaders.CONTENT_DISPOSITION,ContentDisposition.attachment().filename(file.filename(),StandardCharsets.UTF_8).build().toString())
                .contentType(MediaType.parseMediaType(file.type())).body(file.bytes());
    }
}
