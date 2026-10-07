// TV3-TUAN8
package com.gara.quanlygara.dto;

import com.gara.quanlygara.dto.warehouse.CheckActualRequest;
import com.gara.quanlygara.dto.warehouse.CheckCreateRequest;
import com.gara.quanlygara.dto.warehouse.ConfirmUsageRequest;
import com.gara.quanlygara.dto.warehouse.ImportRequest;
import com.gara.quanlygara.dto.warehouse.IssueRequest;
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.Arrays;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import static org.junit.jupiter.api.Assertions.assertTrue;

class WarehouseRequestValidationTest {

    private final Validator validator = Validation.buildDefaultValidatorFactory().getValidator();

    @Test
    void validImportHasNoViolations() {
        assertTrue(validator.validate(new ImportRequest("ABC", null, null,
                List.of(new ImportRequest.Item(1, 2, new BigDecimal("100"))))).isEmpty());
    }

    @Test
    void importRejectsBadQuantityPriceSupplierAndEmptyItems() {
        assertTrue(paths(new ImportRequest("ABC", null, null,
                List.of(new ImportRequest.Item(1, 0, BigDecimal.ONE)))).contains("items[0].quantity"));
        assertTrue(paths(new ImportRequest("ABC", null, null,
                List.of(new ImportRequest.Item(1, 1, new BigDecimal("-1"))))).contains("items[0].unitPrice"));
        assertTrue(paths(new ImportRequest("  ", null, null,
                List.of(new ImportRequest.Item(1, 1, BigDecimal.ONE)))).contains("supplier"));
        assertTrue(paths(new ImportRequest("ABC", null, null, List.of())).contains("items"));
        assertTrue(paths(new ImportRequest("ABC", null, null,
                List.of(new ImportRequest.Item(null, 1, BigDecimal.ONE)))).contains("items[0].partId"));
    }

    @Test
    void issueRejectsMissingOrderBadQuantityAndBlankReason() {
        assertTrue(paths(new IssueRequest(null, null, "Thay bugi",
                List.of(new IssueRequest.Item(1, 1)))).contains("repairOrderId"));
        assertTrue(paths(new IssueRequest(1, null, "Thay bugi",
                List.of(new IssueRequest.Item(1, 0)))).contains("items[0].quantity"));
        assertTrue(paths(new IssueRequest(1, null, " ", List.of(new IssueRequest.Item(1, 1)))).contains("reason"));
        assertTrue(paths(new IssueRequest(1, null, "Thay bugi", List.of())).contains("items"));
    }

    @Test
    void confirmUsageAllowsZeroButNotNegativeOrMissing() {
        assertTrue(validator.validate(new ConfirmUsageRequest(0, null)).isEmpty());
        assertTrue(paths(new ConfirmUsageRequest(-1, null)).contains("actualUsed"));
        assertTrue(paths(new ConfirmUsageRequest(null, null)).contains("actualUsed"));
    }

    @Test
    void checkRequestsValidateQuantitiesAndParts() {
        assertTrue(validator.validate(new CheckActualRequest(0, null)).isEmpty());
        assertTrue(paths(new CheckActualRequest(-1, null)).contains("actualQuantity"));
        assertTrue(paths(new CheckActualRequest(null, null)).contains("actualQuantity"));
        assertTrue(paths(new CheckCreateRequest(null, List.of())).contains("partIds"));
        assertTrue(validator.validate(new CheckCreateRequest("Ghi chú", List.of(1, 2))).isEmpty());
        assertTrue(!validator.validate(new CheckCreateRequest(null, Arrays.asList(1, null))).isEmpty());
    }

    private Set<String> paths(Object request) {
        return validator.validate(request).stream()
                .map(ConstraintViolation::getPropertyPath)
                .map(Object::toString)
                .collect(Collectors.toSet());
    }
}
