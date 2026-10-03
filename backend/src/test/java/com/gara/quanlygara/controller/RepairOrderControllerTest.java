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

class RepairOrderControllerTest extends ApiTestSupport {

    @Autowired
    private JdbcTemplate jdbc;

    @BeforeEach
    void setUp() {
        // Only the test database needs these read-only tables; production uses the existing SQL schema.
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS Xe (MaXe INT PRIMARY KEY, MaKhachHang INT,
                    BienSo VARCHAR(20), HangXe NVARCHAR(100), DongXe NVARCHAR(100))
                """);
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS PhieuTiepNhan (MaTiepNhan INT PRIMARY KEY, MaXe INT,
                    YeuCauKhachHang NVARCHAR(1000), TinhTrangBanDau NVARCHAR(1000))
                """);
        jdbc.execute("""
                CREATE TABLE IF NOT EXISTS ChiTietDichVu (MaPhieuSuaChua INT, MaDichVu INT,
                    SoLuong INT, DonGia DECIMAL(18,2), TrangThai NVARCHAR(50))
                """);
        jdbc.update("INSERT INTO KhachHang (MaKhachHang, HoTen, SoDienThoai, TrangThai) VALUES (9001, N'Khách A', '0900000001', 1)");
        jdbc.update("INSERT INTO Xe VALUES (9001, 9001, '51A-12345', 'Toyota', 'Vios')");
        jdbc.update("INSERT INTO PhieuTiepNhan VALUES (9001, 9001, N'Kiểm tra phanh', N'Phanh kêu')");
        jdbc.update("INSERT INTO PhieuTiepNhan VALUES (9002, 9001, NULL, NULL)");
        jdbc.update("""
                INSERT INTO PhieuSuaChua (MaPhieuSuaChua, MaTiepNhan, NgayLap, TrangThai)
                VALUES (9001, 9001, '2026-10-01 08:00:00', 'DANG_SUA'),
                       (9002, 9002, '2026-10-02 09:00:00', 'HOAN_TAT')
                """);
        jdbc.update("INSERT INTO DichVu (MaDichVu, TenDichVu, DonGia) VALUES (9001, N'Kiểm tra phanh', 250000)");
        jdbc.update("INSERT INTO ChiTietDichVu VALUES (9001, 9001, 2, 200000, 'DANG_SUA')");
        jdbc.update("INSERT INTO NhanVien (MaNhanVien, HoTen, ChucVu) VALUES (9001, N'KTV A', N'Kỹ thuật viên'), (9002, N'KTV B', N'Kỹ thuật viên')");
        jdbc.update("INSERT INTO KyThuatVien (MaNhanVien) VALUES (9001), (9002)");
        jdbc.update("""
                INSERT INTO TaiKhoan (TenDangNhap, MatKhauHash, VaiTro, TrangThai, MaNhanVien)
                VALUES ('repair-tech-a', 'unused', 'TECHNICIAN', 1, 9001),
                       ('repair-tech-b', 'unused', 'TECHNICIAN', 1, 9002),
                       ('repair-tech-unlinked', 'unused', 'TECHNICIAN', 1, NULL)
                """);
        jdbc.update("""
                INSERT INTO PhanCongKyThuatVien (MaPhieuSuaChua, MaKyThuatVien, NgayPhanCong, GhiChu)
                VALUES (9001, 9001, '2026-10-01 08:30:00', N'Kiểm tra trước khi sửa')
                """);
    }

    @ParameterizedTest
    @ValueSource(strings = {"ADMIN", "MANAGER", "RECEPTIONIST"})
    void staffCanReadRealVehicleAndServiceData(String role) throws Exception {
        mockMvc.perform(get("/api/repair-orders").with(user("staff").roles(role)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[0].id").value(9002));
        mockMvc.perform(get("/api/repair-orders/9001").with(user("staff").roles(role)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.order.licensePlate").value("51A-12345"))
                .andExpect(jsonPath("$.data.order.customerName").value("Khách A"))
                .andExpect(jsonPath("$.data.services[0].unitPrice").value(200000))
                .andExpect(jsonPath("$.data.services[0].quantity").value(2))
                .andExpect(jsonPath("$.data.assignments[0].technician.fullName").value("KTV A"));
    }

    @Test
    @WithMockUser(username = "repair-tech-a", roles = "TECHNICIAN")
    void technicianCanOnlySeeOwnOrdersEvenWithForgedQueryParameters() throws Exception {
        mockMvc.perform(get("/api/repair-orders").param("technicianId", "0"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].id").value(9001));
        mockMvc.perform(get("/api/repair-orders/9001"))
                .andExpect(status().isOk());
        mockMvc.perform(get("/api/repair-orders/9002"))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(username = "repair-tech-b", roles = "TECHNICIAN")
    void unassignedTechnicianGetsAnEmptyList() throws Exception {
        mockMvc.perform(get("/api/repair-orders"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data").isEmpty());
    }

    @Test
    @WithMockUser(username = "repair-tech-unlinked", roles = "TECHNICIAN")
    void unlinkedTechnicianCannotReadAllOrders() throws Exception {
        mockMvc.perform(get("/api/repair-orders")).andExpect(status().isForbidden());
    }

    @ParameterizedTest
    @ValueSource(strings = {"CUSTOMER", "WAREHOUSE"})
    void otherRolesCannotReadRepairOrders(String role) throws Exception {
        mockMvc.perform(get("/api/repair-orders").with(user("other").roles(role)))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/repair-orders/9001").with(user("other").roles(role)))
                .andExpect(status().isForbidden());
    }

    @Test
    void anonymousRequestRequiresLogin() throws Exception {
        mockMvc.perform(get("/api/repair-orders")).andExpect(status().isUnauthorized());
    }

    @ParameterizedTest
    @ValueSource(ints = {0, -1, 2147483647})
    @WithMockUser(roles = "MANAGER")
    void missingOrInvalidIdDoesNotReturnAllOrders(int id) throws Exception {
        mockMvc.perform(get("/api/repair-orders/{id}", id)).andExpect(status().isNotFound());
    }
}
