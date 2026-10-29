package com.gara.quanlygara.dto.insurance;

import com.gara.quanlygara.entity.InsuranceClaimEvent;
import java.time.LocalDateTime;

public record InsuranceClaimEventResponse(Long id, Integer employeeId, String action,
                                          String previousStatus, String nextStatus, String note,
                                          LocalDateTime occurredAt) {
    public static InsuranceClaimEventResponse from(InsuranceClaimEvent event) {
        return new InsuranceClaimEventResponse(event.getId(), event.getEmployeeId(), event.getAction(),
                event.getPreviousStatus(), event.getNextStatus(), event.getNote(), event.getOccurredAt());
    }
}
