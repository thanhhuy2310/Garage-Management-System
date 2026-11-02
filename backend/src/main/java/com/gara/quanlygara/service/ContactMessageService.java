package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.contact.*;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.entity.ContactMessage;
import com.gara.quanlygara.exception.*;
import com.gara.quanlygara.repository.ContactMessageRepository;
import org.springframework.data.domain.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.Objects;

@Service
public class ContactMessageService {
    private final ContactMessageRepository repository;
    public ContactMessageService(ContactMessageRepository repository){this.repository=repository;}
    public record Receipt(Integer id,LocalDateTime createdAt) { }
    @Transactional
    public Receipt create(ContactRequest input) {
        var existing=repository.findByRequestId(input.requestId().toString());
        if(existing.isPresent()) {
            var saved=existing.get();
            if(!saved.getFullName().equals(input.fullName())||!saved.getPhone().equals(input.phone())
                    ||!Objects.equals(saved.getPlate(),input.plate())||!saved.getMessage().equals(input.message()))
                throw new ConflictException("Mã gửi lời nhắn đã được sử dụng cho nội dung khác.");
            return new Receipt(saved.getId(),saved.getCreatedAt());
        }
        var saved=repository.saveAndFlush(new ContactMessage(input.requestId().toString(),input.fullName(),input.phone(),input.plate(),input.message(),LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).withNano(0)));
        return new Receipt(saved.getId(),saved.getCreatedAt());
    }
    @Transactional(readOnly=true)
    public PageResponse<ContactResponse> list(int page,int size) {
        return PageResponse.of(repository.findAll(PageRequest.of(Math.max(0,page),Math.min(100,Math.max(1,size)),Sort.by(Sort.Direction.DESC,"createdAt","id"))),ContactResponse::from);
    }
    @Transactional
    public ContactResponse markRead(Integer id) {
        if(!repository.existsById(id))throw new ResourceNotFoundException("Không tìm thấy lời nhắn.");
        repository.markRead(id);
        return ContactResponse.from(repository.findById(id).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy lời nhắn.")));
    }
    @Transactional
    public int markAllRead(){return repository.markAllRead();}
}
