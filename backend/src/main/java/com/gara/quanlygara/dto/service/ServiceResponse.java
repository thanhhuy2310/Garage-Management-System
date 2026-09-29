package com.gara.quanlygara.dto.service;

import com.gara.quanlygara.entity.GarageService;

import java.math.BigDecimal;

public record ServiceResponse(
        Integer id,
        String name,
        String type,
        BigDecimal unitPrice,
        String description
) {
    public static ServiceResponse from(GarageService service) {
        return new ServiceResponse(service.getId(), service.getName(), service.getType(),
                service.getUnitPrice(), service.getDescription());
    }
}
