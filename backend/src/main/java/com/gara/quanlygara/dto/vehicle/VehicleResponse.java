package com.gara.quanlygara.dto.vehicle;

import com.gara.quanlygara.entity.Vehicle;

public record VehicleResponse(
        Integer id,
        Integer customerId,
        String licensePlate,
        String brand,
        String model,
        Short year,
        Integer mileage
) {
    public static VehicleResponse from(Vehicle vehicle) {
        return new VehicleResponse(
                vehicle.getId(),
                vehicle.getCustomerId(),
                vehicle.getLicensePlate(),
                vehicle.getBrand(),
                vehicle.getModel(),
                vehicle.getYear(),
                vehicle.getMileage()
        );
    }
}
