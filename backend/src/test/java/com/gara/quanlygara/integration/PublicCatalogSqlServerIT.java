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
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
@SpringBootTest(properties={"app.jwt.secret=verification-secret-with-more-than-32-characters","spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
class PublicCatalogSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;
    @Test void anonymousReadShowsOnlyActiveServicesAndActualPagedStockWithoutGrantingWrites()throws Exception {
        assertTrue(jdbc.queryForObject("SELECT DB_NAME()",String.class).startsWith("QuanLyGaraOTo_Verify_"));
        var services=json.readTree(mvc.perform(get("/api/public/services")).andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).path("data");
        assertEquals(jdbc.queryForObject("SELECT COUNT(*) FROM DichVu WHERE TrangThai=1",Integer.class),services.size());
        for(var service:services){
            assertTrue(service.path("active").asBoolean());
            BigDecimal price=jdbc.queryForObject("SELECT DonGia FROM DichVu WHERE MaDichVu=?",BigDecimal.class,service.path("id").asInt());
            assertEquals(0,price.compareTo(service.path("unitPrice").decimalValue()));
        }
        int total=jdbc.queryForObject("SELECT COUNT(*) FROM PhuTung",Integer.class),seen=0,page=0;
        while(true){
            var data=json.readTree(mvc.perform(get("/api/public/parts").param("page",String.valueOf(page)).param("size","10"))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).path("data");
            assertEquals(total,data.path("totalElements").asInt());
            for(var part:data.path("items")){
                seen++;assertFalse(part.has("warehouseId"));
                assertEquals(jdbc.queryForObject("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?",Integer.class,part.path("id").asInt()),part.path("stockQuantity").asInt());
                assertEquals(0,jdbc.queryForObject("SELECT DonGia FROM PhuTung WHERE MaPhuTung=?",BigDecimal.class,part.path("id").asInt()).compareTo(part.path("unitPrice").decimalValue()));
            }
            if(++page>=data.path("totalPages").asInt())break;
        }
        assertEquals(total,seen);
        mvc.perform(post("/api/services")).andExpect(status().isUnauthorized());
        mvc.perform(post("/api/spare-parts")).andExpect(status().isUnauthorized());
        mvc.perform(get("/api/employees")).andExpect(status().isUnauthorized());
    }
}
