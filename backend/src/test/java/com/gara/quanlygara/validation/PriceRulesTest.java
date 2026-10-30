package com.gara.quanlygara.validation;
import com.gara.quanlygara.exception.BadRequestException;
import java.math.BigDecimal;
import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;
class PriceRulesTest {
    @Test void acceptsWholeThousandsWithoutRounding() {
        for (String value : new String[]{"0", "1000", "350000.00"})
            assertEquals(new BigDecimal(value).setScale(2), PriceRules.requireWholeThousand(new BigDecimal(value)));
    }
    @Test void rejectsOddOrNegativePricesRatherThanRounding() {
        for (String value : new String[]{"350001", "350500", "350000.01", "-1000"})
            assertThrows(BadRequestException.class, () -> PriceRules.requireWholeThousand(new BigDecimal(value)));
        assertThrows(BadRequestException.class, () -> PriceRules.requireWholeThousand(null));
    }
}
