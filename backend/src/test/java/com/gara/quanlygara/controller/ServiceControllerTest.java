package com.gara.quanlygara.controller;

import com.gara.quanlygara.entity.GarageService;
import com.gara.quanlygara.repository.GarageServiceRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.test.context.support.WithMockUser;

import java.math.BigDecimal;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ServiceControllerTest extends ApiTestSupport {

    @Autowired
    private GarageServiceRepository serviceRepository;

    @ParameterizedTest
    @ValueSource(strings = {"ADMIN", "MANAGER", "RECEPTIONIST", "TECHNICIAN", "CUSTOMER", "WAREHOUSE"})
    void authenticatedRolesCanListAndReadServices(String role) throws Exception {
        GarageService service = saveService("Bảo dưỡng", "Định kỳ");
        mockMvc.perform(get("/api/services").with(user("reader").roles(role)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].id").value(service.getId()));
        mockMvc.perform(get("/api/services/{id}", service.getId()).with(user("reader").roles(role)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Bảo dưỡng"))
                .andExpect(jsonPath("$.data.unitPrice").value(150000));
    }

    @Test
    @WithMockUser
    void searchMatchesNameOrTypeAndTreatsWildcardsAsText() throws Exception {
        saveService("Thay dầu", "Định kỳ");
        saveService("Kiểm tra phanh", "An toàn");
        mockMvc.perform(get("/api/services").param("keyword", "  THAY DẦU  "))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].name").value("Thay dầu"));
        mockMvc.perform(get("/api/services").param("keyword", "an toàn"))
                .andExpect(jsonPath("$.data[0].name").value("Kiểm tra phanh"));
        mockMvc.perform(get("/api/services").param("keyword", "%"))
                .andExpect(jsonPath("$.data.length()").value(0));
        mockMvc.perform(get("/api/services").param("keyword", "  "))
                .andExpect(jsonPath("$.data.length()").value(2));
    }

    @ParameterizedTest
    @ValueSource(strings = {"ADMIN", "MANAGER"})
    void createAndUpdatePersistNormalizedFields(String role) throws Exception {
        var result = mockMvc.perform(post("/api/services").with(user("editor").roles(role))
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {"name":"  Bảo dưỡng  ","type":"  Định kỳ ",
                                 "unitPrice":250000.50,"description":"  Kiểm tra xe  "}
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.name").value("Bảo dưỡng"))
                .andExpect(jsonPath("$.data.type").value("Định kỳ"))
                .andExpect(jsonPath("$.data.description").value("Kiểm tra xe"))
                .andReturn();
        int id = objectMapper.readTree(result.getResponse().getContentAsString()).path("data").path("id").asInt();
        mockMvc.perform(put("/api/services/{id}", id).with(user("editor").roles(role))
                        .contentType(APPLICATION_JSON)
                        .content("{\"name\":\"Bảo dưỡng mới\",\"unitPrice\":0,\"type\":\" \"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(id))
                .andExpect(jsonPath("$.data.type").doesNotExist());
        GarageService saved = serviceRepository.findById(id).orElseThrow();
        assertEquals("Bảo dưỡng mới", saved.getName());
        assertEquals(0, saved.getUnitPrice().compareTo(BigDecimal.ZERO));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void duplicateNamesAreAllowedByCurrentSchema() throws Exception {
        saveService("Bảo dưỡng", "Định kỳ");
        mockMvc.perform(post("/api/services").contentType(APPLICATION_JSON)
                        .content("{\"name\":\"Bảo dưỡng\",\"unitPrice\":250000}"))
                .andExpect(status().isCreated());
        assertEquals(2, serviceRepository.count());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void missingServiceReturnsNotFoundForReadAndUpdate() throws Exception {
        mockMvc.perform(get("/api/services/2147483647"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.message").value("Không tìm thấy dịch vụ."));
        mockMvc.perform(put("/api/services/2147483647").contentType(APPLICATION_JSON)
                        .content("{\"name\":\"Thay dầu\",\"unitPrice\":100000}"))
                .andExpect(status().isNotFound());
    }

    @ParameterizedTest
    @WithMockUser(roles = "MANAGER")
    @ValueSource(strings = {
            "{}", "{\"name\":\" \u2003 \",\"unitPrice\":1}",
            "{\"name\":\"Thay dầu\"}", "{\"name\":\"Thay dầu\",\"unitPrice\":-1}",
            "{\"name\":\"Thay dầu\",\"unitPrice\":0.001}",
            "{\"name\":\"Thay dầu\",\"unitPrice\":10000000000000000}",
            "{\"name\":\"Thay dầu\",\"unitPrice\":\"abc\"}", "{invalid"
    })
    void invalidCreateDoesNotWriteData(String json) throws Exception {
        mockMvc.perform(post("/api/services").contentType(APPLICATION_JSON).content(json))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
        assertEquals(0, serviceRepository.count());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void rejectsLengthsAboveSqlLimitsAndInvalidUpdate() throws Exception {
        var json = objectMapper.writeValueAsString(Map.of("name", "a".repeat(151),
                "type", "a".repeat(101), "description", "a".repeat(501), "unitPrice", 10));
        mockMvc.perform(post("/api/services").contentType(APPLICATION_JSON).content(json))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.name").exists())
                .andExpect(jsonPath("$.data.type").exists())
                .andExpect(jsonPath("$.data.description").exists());
        GarageService saved = saveService("Thay dầu", null);
        mockMvc.perform(put("/api/services/{id}", saved.getId()).contentType(APPLICATION_JSON)
                        .content("{\"name\":\" \",\"unitPrice\":-1}"))
                .andExpect(status().isBadRequest());
        assertEquals("Thay dầu", serviceRepository.findById(saved.getId()).orElseThrow().getName());
    }

    @Test
    void anonymousRequestsAreUnauthorized() throws Exception {
        mockMvc.perform(get("/api/services")).andExpect(status().isUnauthorized());
        mockMvc.perform(get("/api/services/1")).andExpect(status().isUnauthorized());
        mockMvc.perform(post("/api/services").contentType(APPLICATION_JSON)
                        .content("{\"name\":\"Thay dầu\",\"unitPrice\":100000}"))
                .andExpect(status().isUnauthorized());
        mockMvc.perform(put("/api/services/1").contentType(APPLICATION_JSON)
                        .content("{\"name\":\"Thay dầu\",\"unitPrice\":100000}"))
                .andExpect(status().isUnauthorized());
    }

    @ParameterizedTest
    @ValueSource(strings = {"CUSTOMER", "TECHNICIAN", "RECEPTIONIST", "WAREHOUSE"})
    void nonManagersCannotWrite(String role) throws Exception {
        mockMvc.perform(post("/api/services").with(user("reader").roles(role))
                        .contentType(APPLICATION_JSON).content("{\"name\":\"Thay dầu\",\"unitPrice\":1}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(put("/api/services/1").with(user("reader").roles(role))
                        .contentType(APPLICATION_JSON).content("{\"name\":\"Thay dầu\",\"unitPrice\":1}"))
                .andExpect(status().isForbidden());
        assertEquals(0, serviceRepository.count());
    }

    private GarageService saveService(String name, String type) {
        GarageService service = new GarageService();
        service.setName(name);
        service.setType(type);
        service.setUnitPrice(new BigDecimal("150000.00"));
        return serviceRepository.saveAndFlush(service);
    }
}
