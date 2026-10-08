package com.gara.quanlygara.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Explicit SQL Server test; isolated QA names and all writes roll back. Never a production seed. */
@SpringBootTest(properties = {"spring.jpa.hibernate.ddl-auto=none", "spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
@Transactional
class SeedDataSqlServerIT {
    @Autowired JdbcTemplate jdbc;
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;

    @Test
    void seedCreatesLinkedScenariosAndRerunsWithoutResettingUserWork() throws Exception {
        assertEquals("QuanLyGaraOTo", jdbc.queryForObject("SELECT DB_NAME()", String.class));
        assertEquals(0, count("SELECT COUNT(*) FROM PhieuTiepNhan WHERE GhiChu LIKE 'HUY-SEED-QA-%'"),
                "The reserved QA namespace must be empty before this rollback-only test.");
        int originalReceptions = count("SELECT COUNT(*) FROM PhieuTiepNhan");
        int originalOrders = count("SELECT COUNT(*) FROM PhieuSuaChua");
        int originalPayments = count("SELECT COUNT(*) FROM ThanhToan");
        int originalBanks = count("SELECT COUNT(*) FROM TaiKhoanNganHangGara");
        runSeed();
        assertEquals(originalReceptions + 24, count("SELECT COUNT(*) FROM PhieuTiepNhan"));
        assertEquals(originalOrders + 16, count("SELECT COUNT(*) FROM PhieuSuaChua"));
        assertEquals(originalPayments + 4, count("SELECT COUNT(*) FROM ThanhToan"));
        assertEquals(originalBanks, count("SELECT COUNT(*) FROM TaiKhoanNganHangGara"));
        assertEquals(8, count("SELECT COUNT(*) FROM KhachHang WHERE Email LIKE '%huy-seed-qa@example.test'"));
        assertEquals(12, count("SELECT COUNT(*) FROM TaiKhoan WHERE TenDangNhap LIKE 'qa[_]huy[_]seed[_]%'"));
        assertEquals(8, count("""
                SELECT COUNT(*) FROM PhieuTiepNhan t WHERE t.GhiChu LIKE 'HUY-SEED-QA-%'
                AND NOT EXISTS (SELECT 1 FROM PhieuSuaChua p WHERE p.MaTiepNhan=t.MaTiepNhan)
                """));
        int logs = count("SELECT COUNT(*) FROM NhatKySuaChua");
        runSeed();
        assertEquals(originalReceptions + 24, count("SELECT COUNT(*) FROM PhieuTiepNhan"));
        assertEquals(originalOrders + 16, count("SELECT COUNT(*) FROM PhieuSuaChua"));
        assertEquals(originalPayments + 4, count("SELECT COUNT(*) FROM ThanhToan"));
        assertEquals(logs, count("SELECT COUNT(*) FROM NhatKySuaChua"));

        // Authenticate with the actual seeded BCrypt hash and check the customer scope used by Flutter.
        String customerToken = login("qa_huy_seed_khach05");
        String technicianToken = login("qa_huy_seed_ktv01");
        login("qa_huy_seed_manager");
        String receptionistToken = login("qa_huy_seed_tiepnhan");
        assertEquals(Set.of("51H-991.01", "51H-991.02", "51H-991.03", "51H-991.04",
                "51H-991.05", "51H-991.06", "51H-991.07", "51H-991.08"),
                availableQaReceptions(receptionistToken));
        var customer = mvc.perform(get("/api/customer/repairs").header("Authorization", "Bearer " + customerToken))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(2)).andReturn();
        var repairs = json.readTree(customer.getResponse().getContentAsString()).path("data");
        for (var repair : repairs) {
            assertTrue(repair.path("progress").size() > 0);
            assertTrue(repair.path("order").path("licensePlate").asText().matches("51H-991\\.(13|21)"));
        }
        int otherOrder = order(14);
        mvc.perform(get("/api/repair-orders/{id}", otherOrder).header("Authorization", "Bearer " + technicianToken))
                .andExpect(status().isNotFound());
        mvc.perform(get("/api/repair-orders/{id}", order(15)).header("Authorization", "Bearer " + technicianToken))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.assignments.length()").value(2));

        // Consume one waiting reception through the real endpoint.
        int reception = jdbc.queryForObject("SELECT MaTiepNhan FROM PhieuTiepNhan WHERE GhiChu='HUY-SEED-QA-01'", Integer.class);
        int service = jdbc.queryForObject("SELECT MaDichVu FROM DichVu WHERE TenDichVu=N'[TEST HUY QA] Kiểm tra tổng quát'", Integer.class);
        mvc.perform(post("/api/repair-orders").with(user("qa_huy_seed_tiepnhan").roles("RECEPTIONIST"))
                .contentType(APPLICATION_JSON).content(json.writeValueAsString(Map.of("receptionId", reception,
                        "services", new Object[]{Map.of("serviceId", service, "quantity", 1)}))))
                .andExpect(status().isCreated());
        Set<String> remainingReceptions = availableQaReceptions(receptionistToken);
        assertEquals(7, remainingReceptions.size());
        assertFalse(remainingReceptions.contains("51H-991.01"));

        int workingOrder = order(13);
        int workingService = jdbc.queryForObject("SELECT MaDichVu FROM ChiTietDichVu WHERE MaPhieuSuaChua=? AND TrangThai='DANG_SUA'", Integer.class, workingOrder);
        mvc.perform(put("/api/repair-orders/{id}/services/{serviceId}/progress", workingOrder, workingService)
                .header("Authorization", "Bearer " + technicianToken).contentType(APPLICATION_JSON)
                .content("{\"expectedStatus\":\"DANG_SUA\",\"status\":\"HOAN_TAT\",\"notes\":\"Đã kiểm tra xong.\"}"))
                .andExpect(status().isOk());

        int partialInvoice = jdbc.queryForObject("SELECT MaHoaDon FROM HoaDon WHERE MaPhieuSuaChua=?", Integer.class, order(21));
        mvc.perform(post("/api/invoices/{id}/payments", partialInvoice).with(user("qa_huy_seed_tiepnhan").roles("RECEPTIONIST"))
                .contentType(APPLICATION_JSON).content(json.writeValueAsString(Map.of("amount", 10000,
                        "method", "TIEN_MAT", "requestId", UUID.randomUUID().toString()))))
                .andExpect(status().isOk());
        for (int caseNumber : new int[]{18, 19}) {
            var result = mvc.perform(post("/api/invoices").with(user("qa_huy_seed_manager").roles("MANAGER"))
                    .contentType(APPLICATION_JSON).content(json.writeValueAsString(Map.of("repairOrderId", order(caseNumber)))))
                    .andExpect(status().isCreated());
            if (caseNumber == 19) result.andExpect(jsonPath("$.data.invoice.total").value(0))
                    .andExpect(jsonPath("$.data.invoice.status").value("DA_THANH_TOAN"));
        }
        int paymentsAfterWork = count("SELECT COUNT(*) FROM ThanhToan");
        int logsAfterWork = count("SELECT COUNT(*) FROM NhatKySuaChua");
        int invoicesAfterWork = count("SELECT COUNT(*) FROM HoaDon");
        runSeed();
        assertEquals(originalOrders + 17, count("SELECT COUNT(*) FROM PhieuSuaChua"));
        assertEquals(paymentsAfterWork, count("SELECT COUNT(*) FROM ThanhToan"));
        assertEquals(logsAfterWork, count("SELECT COUNT(*) FROM NhatKySuaChua"));
        assertEquals(invoicesAfterWork, count("SELECT COUNT(*) FROM HoaDon"));
        assertEquals("HOAN_TAT", jdbc.queryForObject("SELECT TrangThai FROM ChiTietDichVu WHERE MaPhieuSuaChua=? AND MaDichVu=?",
                String.class, workingOrder, workingService));
    }

    private void runSeed() throws Exception {
        String sql = Files.readString(Path.of("database/seeds/Seed_Huy_Repair_Billing.sql"), StandardCharsets.UTF_8)
                .replace("[TEST HUY]", "[TEST HUY QA]").replace("099970", "099971")
                .replace("huy-test@", "huy-seed-qa@").replace("test_huy_", "qa_huy_seed_")
                .replace("51H-990.", "51H-991.").replace("HUY-TEST-V1-", "HUY-SEED-QA-");
        for (String batch : sql.split("(?im)^GO\\s*$")) {
            if (!batch.isBlank()) jdbc.execute(batch);
        }
    }

    private String login(String username) throws Exception {
        var result = mvc.perform(post("/api/auth/login").contentType(APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("username", username, "password", "demo123"))))
                .andExpect(status().isOk()).andReturn();
        return json.readTree(result.getResponse().getContentAsString()).path("data").path("accessToken").asText();
    }

    private int order(int caseNumber) {
        return jdbc.queryForObject("""
                SELECT p.MaPhieuSuaChua FROM PhieuSuaChua p JOIN PhieuTiepNhan t ON t.MaTiepNhan=p.MaTiepNhan
                WHERE t.GhiChu=?
                """, Integer.class, "HUY-SEED-QA-" + String.format("%02d", caseNumber));
    }

    private Set<String> availableQaReceptions(String token) throws Exception {
        var result = mvc.perform(get("/api/repair-orders/receptions")
                .header("Authorization", "Bearer " + token)).andExpect(status().isOk()).andReturn();
        Set<String> plates = new HashSet<>();
        for (var reception : json.readTree(result.getResponse().getContentAsString()).path("data")) {
            String plate = reception.path("licensePlate").asText();
            if (plate.startsWith("51H-991.")) plates.add(plate);
        }
        return plates;
    }

    private int count(String sql) { return jdbc.queryForObject(sql, Integer.class); }
}
