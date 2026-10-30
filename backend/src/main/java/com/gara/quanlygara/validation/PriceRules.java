package com.gara.quanlygara.validation;

import com.gara.quanlygara.exception.BadRequestException;
import java.math.BigDecimal;

/** New service/part prices use whole thousands of VND; historical amounts are never rounded. */
public final class PriceRules {
    private static final BigDecimal INCREMENT = new BigDecimal("1000");
    private PriceRules() {}
    public static BigDecimal requireWholeThousand(BigDecimal price) {
        if (price == null || price.signum() < 0 || price.remainder(INCREMENT).signum() != 0)
            throw new BadRequestException("Đơn giá phải là số không âm và tròn nghìn đồng (bội số của 1.000đ).");
        return price.setScale(2);
    }
}
