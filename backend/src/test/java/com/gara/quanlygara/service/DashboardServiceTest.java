package com.gara.quanlygara.service;

import com.gara.quanlygara.repository.DashboardRepository;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.*;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.mockito.ArgumentMatchers.any;

class DashboardServiceTest {
    @Test void groupsActualPaymentsAcrossMonthsAndFillsOnlyMissingDatesWithZero() {
        var repo=mock(DashboardRepository.class);
        when(repo.paymentsByDay(any(),any())).thenReturn(List.<Object[]>of(
            new Object[]{java.sql.Date.valueOf("2026-10-31"),new BigDecimal("100000.25")},
            new Object[]{java.sql.Date.valueOf("2026-11-01"),new BigDecimal("200000.00")}));
        when(repo.popularServices(any(),any())).thenReturn(List.<Object[]>of(new Object[]{4,"Thay dầu",2L}));
        when(repo.countReceptions(any(),any())).thenReturn(3L);
        var service=new DashboardService(repo,Clock.fixed(Instant.parse("2026-10-31T18:00:00Z"),ZoneId.of("Asia/Ho_Chi_Minh")));
        var result=service.get();
        assertEquals(LocalDate.of(2026,11,1),result.date());
        assertEquals(new BigDecimal("200000.00"),result.collectedToday());
        assertEquals(3,result.receivedToday());
        assertEquals(7,result.dailyRevenue().size());assertEquals(7,result.monthlyRevenue().size());
        assertEquals(BigDecimal.ZERO,result.dailyRevenue().getFirst().revenue());
        assertEquals("2026-05",result.monthlyRevenue().getFirst().period());
        assertEquals(new BigDecimal("100000.25"),result.monthlyRevenue().get(5).revenue());
        assertEquals(new BigDecimal("200000.00"),result.monthlyRevenue().get(6).revenue());
        assertEquals(2,result.popularServices().getFirst().count());
    }
}
