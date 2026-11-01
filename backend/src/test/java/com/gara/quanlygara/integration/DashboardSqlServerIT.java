package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import java.math.BigDecimal;
import java.time.LocalDate;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
@SpringBootTest(properties={"app.jwt.secret=verification-secret-with-more-than-32-characters","spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
class DashboardSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;
    @Test void totalsAndBothTimeSeriesMatchDatabaseAndRequireManager()throws Exception {
        assertTrue(jdbc.queryForObject("SELECT DB_NAME()",String.class).startsWith("QuanLyGaraOTo_Verify_"));
        mvc.perform(get("/api/reports/dashboard")).andExpect(status().isUnauthorized());
        for(String role:new String[]{"CUSTOMER","TECHNICIAN","RECEPTIONIST","WAREHOUSE","ADMIN"})
            mvc.perform(get("/api/reports/dashboard").with(user("user").roles(role))).andExpect(status().isForbidden());
        var data=json.readTree(mvc.perform(get("/api/reports/dashboard").with(user("manager").roles("MANAGER")))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).path("data");
        LocalDate today=LocalDate.parse(data.path("date").asText());
        long receptions=jdbc.queryForObject("SELECT COUNT_BIG(*) FROM PhieuTiepNhan WHERE NgayTiepNhan>=? AND NgayTiepNhan<?",Long.class,today.atStartOfDay(),today.plusDays(1).atStartOfDay());
        assertEquals(receptions,data.path("receivedToday").asLong());
        assertEquals(7,data.path("dailyRevenue").size());assertEquals(7,data.path("monthlyRevenue").size());
        for(var row:data.path("dailyRevenue")) {
            LocalDate day=LocalDate.parse(row.path("period").asText());
            assertEquals(0,total(day,day.plusDays(1)).compareTo(row.path("revenue").decimalValue()));
        }
        for(var row:data.path("monthlyRevenue")) {
            LocalDate start=LocalDate.parse(row.path("period").asText()+"-01");
            LocalDate end=start.plusMonths(1).isAfter(today)?today.plusDays(1):start.plusMonths(1);
            assertEquals(0,total(start,end).compareTo(row.path("revenue").decimalValue()));
        }
        assertEquals(0,total(today,today.plusDays(1)).compareTo(data.path("collectedToday").decimalValue()));
        for(var row:data.path("popularServices")) {
            long count=jdbc.queryForObject("SELECT COUNT_BIG(*) FROM ChiTietDichVu d JOIN PhieuSuaChua p ON p.MaPhieuSuaChua=d.MaPhieuSuaChua WHERE d.MaDichVu=? AND p.TrangThai=N'HOAN_TAT' AND p.NgayHoanThanh>=? AND p.NgayHoanThanh<?",Long.class,row.path("id").asInt(),today.withDayOfMonth(1).minusMonths(6).atStartOfDay(),today.plusDays(1).atStartOfDay());
            assertEquals(count,row.path("count").asLong());
        }
    }
    BigDecimal total(LocalDate start,LocalDate end){return jdbc.queryForObject("SELECT COALESCE(SUM(SoTien),0) FROM ThanhToan WHERE NgayThanhToan>=? AND NgayThanhToan<?",BigDecimal.class,start.atStartOfDay(),end.atStartOfDay());}
}
