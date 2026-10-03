// TV3-TUAN7
package com.gara.quanlygara.dto;

import com.gara.quanlygara.dto.sparepart.SparePartRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertTrue;

class SparePartRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validRequestHasNoViolations() {
        assertTrue(validator.validate(new SparePartRequest(1, "Bugi", "NGK", new BigDecimal("180000"), 5)).isEmpty());
    }

    @Test
    void optionalFieldsMayBeNull() {
        assertTrue(validator.validate(new SparePartRequest(1, "Bugi", null, BigDecimal.ZERO, null)).isEmpty());
    }

    @Test
    void rejectsNegativeUnitPrice() {
        assertTrue(fields(new SparePartRequest(1, "Bugi", null, new BigDecimal("-1"), 0)).contains("unitPrice"));
    }

    @Test
    void rejectsNegativeMinStockLevel() {
        assertTrue(fields(new SparePartRequest(1, "Bugi", null, BigDecimal.ONE, -1)).contains("minStockLevel"));
    }

    @Test
    void rejectsBlankOrTooLongName() {
        assertTrue(fields(new SparePartRequest(1, "  ", null, BigDecimal.ONE, 0)).contains("name"));
        assertTrue(fields(new SparePartRequest(1, "A".repeat(151), null, BigDecimal.ONE, 0)).contains("name"));
    }

    @Test
    void rejectsMissingPriceAndWarehouse() {
        Set<String> fields = fields(new SparePartRequest(null, "Bugi", null, null, 0));
        assertTrue(fields.contains("warehouseId"));
        assertTrue(fields.contains("unitPrice"));
    }

    @Test
    void rejectsMoreThanTwoDecimals() {
        assertTrue(fields(new SparePartRequest(1, "Bugi", null, new BigDecimal("1.234"), 0)).contains("unitPrice"));
    }

    private Set<String> fields(SparePartRequest request) {
        return validator.validate(request).stream()
                .map(ConstraintViolation::getPropertyPath)
                .map(Object::toString)
                .collect(Collectors.toSet());
    }
}
