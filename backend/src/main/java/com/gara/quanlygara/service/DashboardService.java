package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.report.DashboardResponse;
import com.gara.quanlygara.repository.DashboardRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.math.BigDecimal;
import java.time.*;
import java.util.*;

@Service
public class DashboardService {
    private final DashboardRepository repository;
    private final Clock clock;
    @Autowired
    public DashboardService(DashboardRepository repository) {
        this(repository, Clock.system(ZoneId.of("Asia/Ho_Chi_Minh")));
    }
    DashboardService(DashboardRepository repository, Clock clock) {
        this.repository=repository; this.clock=clock;
    }

    @Transactional(readOnly=true)
    public DashboardResponse get() {
        LocalDate today=LocalDate.now(clock);
        YearMonth firstMonth=YearMonth.from(today).minusMonths(6);
        LocalDateTime start=firstMonth.atDay(1).atStartOfDay(), end=today.plusDays(1).atStartOfDay();
        Map<LocalDate,BigDecimal> payments=new HashMap<>();
        for (Object[] row:repository.paymentsByDay(start,end)) {
            payments.put(LocalDate.parse(row[0].toString()),new BigDecimal(row[1].toString()));
        }
        List<DashboardResponse.RevenuePoint> days=new ArrayList<>(), months=new ArrayList<>();
        for(int i=6;i>=0;i--) {
            LocalDate day=today.minusDays(i);
            days.add(new DashboardResponse.RevenuePoint(day.toString(),payments.getOrDefault(day,BigDecimal.ZERO)));
        }
        for(int i=0;i<7;i++) {
            YearMonth month=firstMonth.plusMonths(i);
            BigDecimal total=payments.entrySet().stream().filter(e->YearMonth.from(e.getKey()).equals(month))
                    .map(Map.Entry::getValue).reduce(BigDecimal.ZERO,BigDecimal::add);
            months.add(new DashboardResponse.RevenuePoint(month.toString(),total));
        }
        var popular=repository.popularServices(start,end).stream().map(row->new DashboardResponse.ServiceUsage(
                ((Number)row[0]).intValue(),row[1].toString(),((Number)row[2]).longValue())).toList();
        return new DashboardResponse(today,repository.countReceptions(today.atStartOfDay(),end),
                payments.getOrDefault(today,BigDecimal.ZERO),days,months,popular);
    }
}
