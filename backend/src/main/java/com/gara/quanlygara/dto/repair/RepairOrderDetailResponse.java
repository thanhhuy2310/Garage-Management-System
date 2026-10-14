package com.gara.quanlygara.dto.repair;

import com.gara.quanlygara.dto.technician.TechnicianAssignmentResponse;

import java.math.BigDecimal;
import java.util.List;
import com.gara.quanlygara.entity.RepairProgress;

public record RepairOrderDetailResponse(
        RepairOrderResponse order,
        List<ServiceLineResponse> services,
        List<TechnicianAssignmentResponse> assignments,
        List<RepairProgress> progress
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
