package com.gara.quanlygara.controller;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Đối chiếu API báo cáo với các phép tổng hợp trực tiếp trên SQL Server thật. */
@SpringBootTest(properties = {"spring.jpa.hibernate.ddl-auto=none", "spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
@Transactional(readOnly = true)
class ReportSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;

    @Test
    void overviewMatchesActualDatabaseAggregates() throws Exception {
        LocalDate to = LocalDate.now();
        LocalDate from = to.minusYears(5);
        LocalDateTime start = from.atStartOfDay();
        LocalDateTime end = to.plusDays(1).atStartOfDay();

        BigDecimal collected = jdbc.queryForObject(
                "SELECT COALESCE(SUM(SoTien), 0) FROM ThanhToan WHERE NgayThanhToan >= ? AND NgayThanhToan < ?",
                BigDecimal.class, start, end);
        Integer opened = jdbc.queryForObject(
                "SELECT COUNT(*) FROM PhieuSuaChua WHERE NgayLap >= ? AND NgayLap < ?",
                Integer.class, start, end);
        Long imported = jdbc.queryForObject(
                "SELECT COALESCE(SUM(CAST(SoLuong AS BIGINT)), 0) FROM BienDongKho WHERE LoaiBienDong=N'NHAP' AND ThoiGian >= ? AND ThoiGian < ?",
                Long.class, start, end);
        Long exported = jdbc.queryForObject(
                "SELECT COALESCE(SUM(CAST(SoLuong AS BIGINT)), 0) FROM BienDongKho WHERE LoaiBienDong=N'XUAT' AND ThoiGian >= ? AND ThoiGian < ?",
                Long.class, start, end);
        Long stock = jdbc.queryForObject(
                "SELECT COALESCE(SUM(CAST(SoLuongTon AS BIGINT)), 0) FROM PhuTung",
                Long.class);

        mvc.perform(get("/api/reports/overview")
                        .param("from", from.toString()).param("to", to.toString())
                        .with(user("manager").roles("MANAGER")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.billing.collected").value(collected.doubleValue()))
                .andExpect(jsonPath("$.data.repairs.opened").value(opened))
                .andExpect(jsonPath("$.data.inventory.imported").value(imported))
                .andExpect(jsonPath("$.data.inventory.exported").value(exported))
                .andExpect(jsonPath("$.data.inventory.currentStock").value(stock));
    }

    @Test
    void reportsRequireManagerAndValidateDateRange() throws Exception {
        mvc.perform(get("/api/reports/overview")
                        .param("from", "2026-01-01").param("to", "2026-12-31")
                        .with(user("reception").roles("RECEPTIONIST")))
                .andExpect(status().isForbidden());

        mvc.perform(get("/api/reports/overview")
                        .param("from", "2026-12-31").param("to", "2026-01-01")
                        .with(user("manager").roles("MANAGER")))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.message").value("Ngày bắt đầu không được sau ngày kết thúc."));
    }
}
