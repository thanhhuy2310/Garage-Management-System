package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.contact.ContactRequest;
import com.gara.quanlygara.service.ContactMessageService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/public/contact-messages")
public class PublicContactController {
    private final ContactMessageService service;
    public PublicContactController(ContactMessageService service){this.service=service;}
    @PostMapping @ResponseStatus(HttpStatus.CREATED)
    public ApiResponse<ContactMessageService.Receipt> create(@Valid @RequestBody ContactRequest input) {
        return ApiResponse.success("Đã nhận lời nhắn.",service.create(input));
    }
}
