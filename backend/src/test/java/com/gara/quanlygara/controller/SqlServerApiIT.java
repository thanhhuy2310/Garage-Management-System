package com.gara.quanlygara.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.security.JwtService;
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
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
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

    @Autowired
    private AccountRepository accountRepository;

    @Autowired
    private JwtService jwtService;

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

    @Test
    void assignmentApiUsesSqlKeysAndTheCurrentTechnicianAccount() throws Exception {
        String unique = UUID.randomUUID().toString();
        int customerId = insertId("""
                INSERT INTO KhachHang (HoTen, SoDienThoai) OUTPUT INSERTED.MaKhachHang
                VALUES (?, ?)
                """, "Khách kiểm thử " + unique, unique.substring(0, 20));
        int vehicleId = insertId("""
                INSERT INTO Xe (MaKhachHang, BienSo) OUTPUT INSERTED.MaXe VALUES (?, ?)
                """, customerId, unique.substring(0, 20));
        int receptionId = insertId("""
                INSERT INTO PhieuTiepNhan (MaXe, NgayTiepNhan) OUTPUT INSERTED.MaTiepNhan
                VALUES (?, SYSDATETIME())
                """, vehicleId);
        int orderId = insertId("""
                SET NOCOUNT ON;
                DECLARE @NewOrder TABLE (Id INT);
                INSERT INTO PhieuSuaChua (MaTiepNhan, NgayLap, TrangThai)
                OUTPUT INSERTED.MaPhieuSuaChua INTO @NewOrder
                VALUES (?, SYSDATETIME(), N'DANG_SUA');
                SELECT Id FROM @NewOrder;
                """, receptionId);
        int technicianId = insertId("""
                INSERT INTO NhanVien (HoTen, ChucVu) OUTPUT INSERTED.MaNhanVien VALUES (?, N'Kỹ thuật viên')
                """, "KTV kiểm thử " + unique);
        jdbcTemplate.update("INSERT INTO KyThuatVien (MaNhanVien) VALUES (?)", technicianId);
        Account account = new Account();
        account.setUsername("sql-test-" + unique);
        account.setPasswordHash("unused-in-jwt-test");
        account.setEmployeeId(technicianId);
        account.setRole(AccountRole.TECHNICIAN);
        account = accountRepository.saveAndFlush(account);
        int serviceId = insertId("""
                INSERT INTO DichVu (TenDichVu, DonGia) OUTPUT INSERTED.MaDichVu VALUES (?, 250000)
                """, "Dịch vụ kiểm thử " + unique);
        jdbcTemplate.update("""
                INSERT INTO ChiTietDichVu (MaPhieuSuaChua, MaDichVu, SoLuong, DonGia)
                VALUES (?, ?, 2, 200000)
                """, orderId, serviceId);

        mockMvc.perform(get("/api/repair-orders/{id}", orderId).with(user("manager").roles("MANAGER")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.order.licensePlate").value(unique.substring(0, 20)))
                .andExpect(jsonPath("$.data.order.customerName").value("Khách kiểm thử " + unique))
                .andExpect(jsonPath("$.data.services[0].id").value(serviceId))
                .andExpect(jsonPath("$.data.services[0].unitPrice").value(200000))
                .andExpect(jsonPath("$.data.services[0].quantity").value(2));
        mockMvc.perform(get("/api/repair-orders/{id}", orderId)
                        .header("Authorization", "Bearer " + jwtService.generateToken(account)))
                .andExpect(status().isNotFound());

        String url = "/api/repair-orders/" + orderId + "/technicians";
        String request = objectMapper.writeValueAsString(Map.of("technicianId", technicianId,
                "notes", "Kiểm tra phanh"));
        mockMvc.perform(get("/api/technicians").with(user("manager").roles("MANAGER")))
                .andExpect(status().isOk());
        mockMvc.perform(post(url).with(user("manager").roles("MANAGER"))
                        .contentType(APPLICATION_JSON).content(request))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.technician.id").value(technicianId));
        assertEquals(1, jdbcTemplate.queryForObject("""
                SELECT COUNT(*) FROM PhanCongKyThuatVien WHERE MaPhieuSuaChua = ? AND MaKyThuatVien = ?
                """, Integer.class, orderId, technicianId));
        mockMvc.perform(get(url).with(user("manager").roles("MANAGER")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].notes").value("Kiểm tra phanh"));
        mockMvc.perform(get("/api/technicians/me/repair-orders")
                        .header("Authorization", "Bearer " + jwtService.generateToken(account)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].repairOrderId").value(orderId))
                .andExpect(jsonPath("$.data[0].receptionId").value(receptionId));
        mockMvc.perform(get("/api/repair-orders")
                        .header("Authorization", "Bearer " + jwtService.generateToken(account)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].id").value(orderId));
        mockMvc.perform(get("/api/repair-orders/{id}", orderId)
                        .header("Authorization", "Bearer " + jwtService.generateToken(account)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.assignments[0].technician.id").value(technicianId));
    }

    private int insertId(String sql, Object... parameters) {
        return jdbcTemplate.queryForObject(sql, Integer.class, parameters);
    }
}
