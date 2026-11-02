package com.gara.quanlygara.dto.contact;

import com.gara.quanlygara.entity.ContactMessage;
import java.time.LocalDateTime;

public record ContactResponse(Integer id,String fullName,String phone,String plate,String message,LocalDateTime createdAt,boolean read) {
    public static ContactResponse from(ContactMessage value){return new ContactResponse(value.getId(),value.getFullName(),value.getPhone(),value.getPlate(),value.getMessage(),value.getCreatedAt(),value.isRead());}
}
