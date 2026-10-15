package com.gara.quanlygara.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

// Run explicitly after Seed_Customer_Accounts.sql against the local development database.
@SpringBootTest(properties = {"spring.jpa.hibernate.ddl-auto=none", "spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
@Transactional(readOnly = true)
class CustomerAccountSqlServerIT {
    @Autowired private MockMvc mvc;
    @Autowired private ObjectMapper json;
    @Autowired private JdbcTemplate jdbc;

    @ParameterizedTest
    @ValueSource(strings = {"tranminhtuan", "lehoangnam", "phamngoclan"})
    void seededAccountCanLoginAndReadItsLinkedSqlProfile(String username) throws Exception {
        assertEquals("QuanLyGaraOTo", jdbc.queryForObject("SELECT DB_NAME()", String.class));
        var customer = jdbc.queryForMap("""
                SELECT k.MaKhachHang, k.HoTen FROM TaiKhoan a
                JOIN KhachHang k ON k.MaKhachHang=a.MaKhachHang WHERE a.TenDangNhap=?
                """, username);
        var login = mvc.perform(post("/api/auth/login").contentType(APPLICATION_JSON)
                        .content(json.writeValueAsString(Map.of("username", username, "password", "Gara@123456"))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.account.role").value("CUSTOMER"))
                .andExpect(jsonPath("$.data.account.customerId").value(customer.get("MaKhachHang")))
                .andReturn();
        String token = json.readTree(login.getResponse().getContentAsString()).path("data").path("accessToken").asText();
        mvc.perform(get("/api/customer/profile").header("Authorization", "Bearer " + token))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.fullName").value(customer.get("HoTen")))
                .andExpect(jsonPath("$.data.id").value(customer.get("MaKhachHang")));
    }
}
