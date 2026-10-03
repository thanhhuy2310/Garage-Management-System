package com.gara.quanlygara.dto.repair;

import com.gara.quanlygara.dto.technician.TechnicianAssignmentResponse;

import java.math.BigDecimal;
import java.util.List;

public record RepairOrderDetailResponse(
        RepairOrderResponse order,
        List<ServiceLineResponse> services,
        List<TechnicianAssignmentResponse> assignments
) {
    public record ServiceLineResponse(
            Integer id,
            String name,
            Integer quantity,
            BigDecimal unitPrice,
            String status
    ) {
    }
}
