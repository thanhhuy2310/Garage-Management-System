package com.gara.quanlygara.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/** Run explicitly with -Dtest=SqlServerApiIT against the configured development database. */
@SpringBootTest(properties = {"spring.jpa.hibernate.ddl-auto=none", "spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
@Transactional
class SqlServerApiIT {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Test
    @WithMockUser(roles = "MANAGER")
    void serviceApiReadsAndWritesExistingSqlServerSchema() throws Exception {
        String name = "Kiểm thử dịch vụ " + UUID.randomUUID();
        String request = objectMapper.writeValueAsString(Map.of(
                "name", name, "type", "Bảo dưỡng", "unitPrice", new BigDecimal("250000.50")));
        var result = mockMvc.perform(post("/api/services").contentType(APPLICATION_JSON).content(request))
                .andExpect(status().isCreated()).andReturn();
        int id = objectMapper.readTree(result.getResponse().getContentAsString()).path("data").path("id").asInt();
        assertEquals(name, jdbcTemplate.queryForObject(
                "SELECT TenDichVu FROM DichVu WHERE MaDichVu = ?", String.class, id));
        mockMvc.perform(get("/api/services").param("keyword", name))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1));
        mockMvc.perform(put("/api/services/{id}", id).contentType(APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("name", name, "unitPrice", 500000))))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/services/{id}", id))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.unitPrice").value(500000));
    }
}
