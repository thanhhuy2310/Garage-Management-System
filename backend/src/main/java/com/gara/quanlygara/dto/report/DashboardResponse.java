package com.gara.quanlygara.dto.report;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record DashboardResponse(LocalDate date, long receivedToday, BigDecimal collectedToday,
                                List<RevenuePoint> dailyRevenue, List<RevenuePoint> monthlyRevenue,
                                List<ServiceUsage> popularServices) {
    public record RevenuePoint(String period, BigDecimal revenue) { }
    public record ServiceUsage(Integer id, String name, long count) { }
}
