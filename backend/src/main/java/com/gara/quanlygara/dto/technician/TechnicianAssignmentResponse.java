package com.gara.quanlygara.dto.technician;

import java.time.LocalDateTime;

public record TechnicianAssignmentResponse(
        Integer repairOrderId,
        TechnicianResponse technician,
        LocalDateTime assignedAt,
        String notes
) {
    public TechnicianAssignmentResponse(Integer repairOrderId, Integer technicianId, String fullName,
                                        LocalDateTime assignedAt, String notes) {
        this(repairOrderId, new TechnicianResponse(technicianId, fullName), assignedAt, notes);
    }
}
