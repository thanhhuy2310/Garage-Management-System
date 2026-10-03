package com.gara.quanlygara.mapper;

import com.gara.quanlygara.dto.repair.RepairOrderDetailResponse.ServiceLineResponse;
import com.gara.quanlygara.dto.repair.RepairOrderResponse;
import com.gara.quanlygara.repository.RepairOrderRepository;
import org.springframework.stereotype.Component;

@Component
public class RepairOrderMapper {

    public RepairOrderResponse toResponse(RepairOrderRepository.Overview order) {
        return new RepairOrderResponse(
                order.getId(), order.getReceptionId(), order.getCreatedAt(), order.getStartedAt(),
                order.getCompletedAt(), order.getStatus(), order.getResult(), order.getLicensePlate(),
                order.getBrand(), order.getModel(), order.getCustomerName(),
                order.getCustomerRequest(), order.getInitialCondition());
    }

    public ServiceLineResponse toServiceLine(RepairOrderRepository.ServiceLine line) {
        return new ServiceLineResponse(
                line.getId(), line.getName(), line.getQuantity(), line.getUnitPrice(), line.getStatus());
    }
}
