package com.gara.quanlygara.dto;

import com.gara.quanlygara.dto.vehicle.VehicleRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertTrue;

class VehicleRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validRequestHasNoViolations() {
        assertTrue(validator.validate(new VehicleRequest(1, "51A-123.45", "Toyota", "Vios", (short) 2021, 0)).isEmpty());
    }

    @Test
    void optionalFieldsMayBeNull() {
        assertTrue(validator.validate(new VehicleRequest(1, "51A-123.45", null, null, null, null)).isEmpty());
    }

    @Test
    void rejectsNegativeMileage() {
        assertTrue(fields(new VehicleRequest(1, "51A-123.45", null, null, null, -1)).contains("mileage"));
    }

    @Test
    void rejectsInvalidYear() {
        assertTrue(fields(new VehicleRequest(1, "51A-123.45", null, null, (short) 1500, null)).contains("year"));
        assertTrue(fields(new VehicleRequest(1, "51A-123.45", null, null, (short) 3000, null)).contains("year"));
    }

    @Test
    void rejectsBlankOrTooLongLicensePlate() {
        assertTrue(fields(new VehicleRequest(1, "   ", null, null, null, null)).contains("licensePlate"));
        assertTrue(fields(new VehicleRequest(1, "A".repeat(21), null, null, null, null)).contains("licensePlate"));
    }

    @Test
    void rejectsMissingOrNonPositiveCustomerId() {
        assertTrue(fields(new VehicleRequest(null, "51A-123.45", null, null, null, null)).contains("customerId"));
        assertTrue(fields(new VehicleRequest(0, "51A-123.45", null, null, null, null)).contains("customerId"));
    }

    private Set<String> fields(VehicleRequest request) {
        return validator.validate(request).stream()
                .map(ConstraintViolation::getPropertyPath)
                .map(Object::toString)
                .collect(Collectors.toSet());
    }
}
