package com.gara.quanlygara.dto.vehicle;

import com.gara.quanlygara.entity.Vehicle;
import org.springframework.data.domain.Page;

import java.util.List;

/** Trang dữ liệu xe. page bắt đầu từ 0, giống Spring Data. */
public record VehiclePageResponse(
        List<VehicleResponse> items,
        int page,
        int size,
        long totalElements,
        int totalPages
) {
    public static VehiclePageResponse from(Page<Vehicle> result) {
        return new VehiclePageResponse(
                result.getContent().stream().map(VehicleResponse::from).toList(),
                result.getNumber(),
                result.getSize(),
                result.getTotalElements(),
                result.getTotalPages()
        );
    }
}
