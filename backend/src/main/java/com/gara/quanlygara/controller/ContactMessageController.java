package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.contact.ContactResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.service.ContactMessageService;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import java.util.Map;

@RestController
@RequestMapping("/api/contact-messages")
@PreAuthorize("hasAnyRole('MANAGER','RECEPTIONIST')")
public class ContactMessageController {
    private final ContactMessageService service;
    public ContactMessageController(ContactMessageService service){this.service=service;}
    @GetMapping public ApiResponse<PageResponse<ContactResponse>> list(@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="100") int size) {
        return ApiResponse.success("Lời nhắn khách hàng.",service.list(page,size));
    }
    @PatchMapping("/{id}/read") public ApiResponse<ContactResponse> read(@PathVariable Integer id){return ApiResponse.success("Đã đọc lời nhắn.",service.markRead(id));}
    @PatchMapping("/read-all") public ApiResponse<Map<String,Integer>> readAll(){return ApiResponse.success("Đã đọc các lời nhắn.",Map.of("updated",service.markAllRead()));}
}
