package com.gara.quanlygara.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class CustomerProfileControllerTest extends ApiTestSupport {

    @Autowired
    private JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        jdbc.update("""
                INSERT INTO KhachHang (MaKhachHang, HoTen, SoDienThoai, Email, DiaChi, TrangThai)
                VALUES (9001, N'Trần Minh Tuấn', '0900000002', 'tuan@example.test', N'TP. Hồ Chí Minh', 1),
                       (9002, N'Phạm Ngọc Lan', '0900000004', NULL, NULL, 1)
                """);
        jdbc.update("""
                INSERT INTO TaiKhoan (TenDangNhap, MatKhauHash, VaiTro, TrangThai, MaKhachHang)
                VALUES ('profile-tuan', 'unused', 'CUSTOMER', 1, 9001),
                       ('profile-lan', 'unused', 'CUSTOMER', 1, 9002),
                       ('profile-unlinked', 'unused', 'CUSTOMER', 1, NULL),
                       ('profile-locked', 'unused', 'CUSTOMER', 0, 9001)
                """);
    }

    @Test
    @WithMockUser(username = "profile-tuan", roles = "CUSTOMER")
    void profileUsesAuthenticatedAccountEvenWithAnotherCustomerId() throws Exception {
        mockMvc.perform(get("/api/customer/profile").param("customerId", "9002").param("id", "9002"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(9001))
                .andExpect(jsonPath("$.data.fullName").value("Trần Minh Tuấn"))
                .andExpect(jsonPath("$.data.phone").value("0900000002"))
                .andExpect(jsonPath("$.data.email").value("tuan@example.test"))
                .andExpect(jsonPath("$.data.address").value("TP. Hồ Chí Minh"))
                .andExpect(jsonPath("$.data.passwordHash").doesNotExist());
    }

    @Test
    @WithMockUser(username = "profile-lan", roles = "CUSTOMER")
    void anotherAccountGetsItsOwnNameAndLatestCustomerData() throws Exception {
        jdbc.update("UPDATE KhachHang SET HoTen=N'Phạm Thị Ngọc Lan' WHERE MaKhachHang=9002");
        mockMvc.perform(get("/api/customer/profile"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(9002))
                .andExpect(jsonPath("$.data.fullName").value("Phạm Thị Ngọc Lan"))
                .andExpect(jsonPath("$.data.email").isEmpty());
    }

    @ParameterizedTest
    @ValueSource(strings = {"ADMIN", "MANAGER", "RECEPTIONIST", "TECHNICIAN", "WAREHOUSE"})
    void staffCannotReadACustomerProfileThroughThisEndpoint(String role) throws Exception {
        mockMvc.perform(get("/api/customer/profile").with(user("staff").roles(role)))
                .andExpect(status().isForbidden());
    }

    @ParameterizedTest
    @ValueSource(strings = {"profile-unlinked", "profile-locked"})
    void unlinkedOrLockedAccountCannotBorrowAnotherProfile(String username) throws Exception {
        mockMvc.perform(get("/api/customer/profile").with(user(username).roles("CUSTOMER")))
                .andExpect(status().isForbidden());
    }

    @Test
    void anonymousRequestRequiresLogin() throws Exception {
        mockMvc.perform(get("/api/customer/profile")).andExpect(status().isUnauthorized());
    }
}
