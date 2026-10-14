// TV3-TUAN7
package com.gara.quanlygara.dto;

import com.gara.quanlygara.dto.repairdetail.RepairDetailCreateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailType;
import com.gara.quanlygara.dto.repairdetail.RepairDetailUpdateRequest;
import com.gara.quanlygara.exception.BadRequestException;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

class RepairDetailRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validCreateRequestHasNoViolations() {
        assertTrue(validator.validate(
                new RepairDetailCreateRequest(RepairDetailType.SPARE_PART, 1, 2, new BigDecimal("1000"))).isEmpty());
        assertTrue(validator.validate(
                new RepairDetailCreateRequest(RepairDetailType.SERVICE, 1, 1, null)).isEmpty());
    }

    @Test
    void rejectsZeroOrNegativeQuantity() {
        assertTrue(createFields(new RepairDetailCreateRequest(RepairDetailType.SERVICE, 1, 0, null)).contains("quantity"));
        assertTrue(createFields(new RepairDetailCreateRequest(RepairDetailType.SERVICE, 1, -3, null)).contains("quantity"));
        assertTrue(validator.validate(new RepairDetailUpdateRequest(0, null)).stream()
                .anyMatch(v -> v.getPropertyPath().toString().equals("quantity")));
    }

    @Test
    void rejectsNegativeUnitPrice() {
        assertTrue(createFields(new RepairDetailCreateRequest(
                RepairDetailType.SERVICE, 1, 1, new BigDecimal("-0.01"))).contains("unitPrice"));
    }

    @Test
    void rejectsMissingTypeAndItem() {
        Set<String> fields = createFields(new RepairDetailCreateRequest(null, null, 1, null));
        assertTrue(fields.contains("type"));
        assertTrue(fields.contains("itemId"));
    }

    @Test
    void pathTypeIsParsedOrRejected() {
        assertEquals(RepairDetailType.SERVICE, RepairDetailType.fromPath("service"));
        assertEquals(RepairDetailType.SPARE_PART, RepairDetailType.fromPath("spare-part"));
        assertThrows(BadRequestException.class, () -> RepairDetailType.fromPath("labor"));
    }

    private Set<String> createFields(RepairDetailCreateRequest request) {
        return validator.validate(request).stream()
                .map(ConstraintViolation::getPropertyPath)
                .map(Object::toString)
                .collect(Collectors.toSet());
    }
}
