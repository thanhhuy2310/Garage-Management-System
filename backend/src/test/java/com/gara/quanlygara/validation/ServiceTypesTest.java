package com.gara.quanlygara.validation;

import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class ServiceTypesTest {
    @ParameterizedTest
    @ValueSource(strings={"BAO_DUONG", "bao_duong", "Bảo dưỡng", " BẢO  DƯỠNG ", "Bao duong"})
    void maintenanceAliasesHaveOneCanonicalCode(String value) {
        assertTrue(ServiceTypes.isMaintenance(value));
        assertEquals("BAO_DUONG",ServiceTypes.normalize(value));
    }
    @Test void otherCategoriesAndMissingValuesAreNotInvented() {
        assertFalse(ServiceTypes.isMaintenance(null));
        assertFalse(ServiceTypes.isMaintenance("Sửa chữa"));
        assertEquals("Sửa chữa",ServiceTypes.normalize(" Sửa chữa "));
        assertNull(ServiceTypes.normalize(" "));
    }
}
