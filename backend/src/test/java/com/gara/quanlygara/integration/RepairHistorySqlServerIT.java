// TV3-TUAN9
package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;
import org.springframework.test.context.transaction.AfterTransaction;
import org.springframework.test.context.transaction.BeforeTransaction;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Integration test trên SQL Server THẬT cho API lịch sử: chạy native SQL và dbo.fn_TinhTongChiPhiSuaChua trên schema thật.
 *
 * Không chạy trong ".\mvnw.cmd test" (tên *IT không thuộc mẫu của surefire) và còn bị khóa bởi biến môi trường,
 * để test thường không phụ thuộc SQL Server. Chạy:
 *   $env:RUN_SQLSERVER_IT = "true"     # cùng DB_URL / DB_USERNAME / DB_PASSWORD như khi chạy backend (hoặc file backend/.env)
 *   .\mvnw.cmd -Dtest=RepairHistorySqlServerIT test
 *
 * Toàn bộ dữ liệu test nằm trong transaction của test và bị ROLLBACK; @AfterTransaction kiểm tra số dòng các bảng
 * không đổi. Dữ liệu dùng mã duy nhất theo thời gian, không phụ thuộc ID của dữ liệu mẫu.
 */
@EnabledIfEnvironmentVariable(named = "RUN_SQLSERVER_IT", matches = "true")
@SpringBootTest(properties = "app.jwt.secret=it-secret-that-is-at-least-32-characters-long")
@AutoConfigureMockMvc
@Transactional
class RepairHistorySqlServerIT {

    private static final List<String> TABLES = List.of(
            "KhachHang", "TaiKhoan", "Xe", "PhieuTiepNhan", "PhieuSuaChua", "DichVu", "ChiTietDichVu",
            "PhuTung", "ChiTietPhuTung");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbc;

    private Map<String, Long> countsBefore;

    @BeforeTransaction
    void rememberRowCounts() {
        countsBefore = counts();
    }

    @AfterTransaction
    void seedDataIsUnchangedAfterRollback() {
        assertEquals(countsBefore, counts(), "Dữ liệu test phải được rollback hoàn toàn");
    }

    private Map<String, Long> counts() {
        Map<String, Long> result = new LinkedHashMap<>();
        for (String table : TABLES) {
            result.put(table, jdbc.queryForObject("SELECT COUNT_BIG(*) FROM " + table, Long.class));
        }
        return result;
    }

    // ------------------------------------------------------------------ dữ liệu test

    private int insert(String table, String keyColumn, Map<String, Object> values) {
        Number key = new SimpleJdbcInsert(jdbc).withTableName(table)
                .usingGeneratedKeyColumns(keyColumn).usingColumns(values.keySet().toArray(new String[0]))
                .executeAndReturnKey(values);
        return key.intValue();
    }

    private int customer(String tag, String name) {
        return insert("KhachHang", "MaKhachHang", Map.of("HoTen", name, "SoDienThoai", "09" + tag));
    }

    private void account(String username, int customerId) {
        insert("TaiKhoan", "MaTaiKhoan", Map.of(
                "TenDangNhap", username, "MatKhauHash", "it-not-a-real-hash", "VaiTro", "CUSTOMER", "MaKhachHang", customerId));
    }

    private int vehicle(int customerId, String plate) {
        return insert("Xe", "MaXe", Map.of("MaKhachHang", customerId, "BienSo", plate, "HangXe", "Toyota", "DongXe", "Camry"));
    }

    private int service(String tag, String type, String price) {
        return insert("DichVu", "MaDichVu", Map.of(
                "TenDichVu", "IT dich vu " + tag, "LoaiDichVu", type, "DonGia", new BigDecimal(price)));
    }

    private int part(String tag, String price) {
        Integer warehouse = jdbc.queryForObject("SELECT TOP 1 MaKho FROM Kho ORDER BY MaKho", Integer.class);
        return insert("PhuTung", "MaPhuTung", Map.of(
                "MaKho", warehouse, "TenPhuTung", "IT phu tung " + tag, "DonGia", new BigDecimal(price),
                "MucTonToiThieu", 0));
    }

    /** Tạo phiếu tiếp nhận + phiếu sửa chữa; completedAt = null thì không có ngày hoàn thành. */
    private int repairOrder(int vehicleId, String status, String completedAt, String result) {
        int reception = insert("PhieuTiepNhan", "MaTiepNhan", Map.of(
                "MaXe", vehicleId, "NgayTiepNhan", Timestamp.valueOf("2026-03-01 08:00:00")));
        Map<String, Object> values = new HashMap<>();
        values.put("MaTiepNhan", reception);
        values.put("NgayLap", Timestamp.valueOf("2026-03-01 09:00:00"));
        values.put("NgayBatDau", Timestamp.valueOf("2026-03-02 08:00:00"));
        if (completedAt != null) values.put("NgayHoanThanh", Timestamp.valueOf(completedAt));
        values.put("TrangThai", status);
        if (result != null) values.put("KetQua", result);
        return insert("PhieuSuaChua", "MaPhieuSuaChua", values);
    }

    private void serviceLine(int orderId, int serviceId, int quantity, String price) {
        jdbc.update("INSERT INTO ChiTietDichVu (MaPhieuSuaChua, MaDichVu, SoLuong, DonGia) VALUES (?, ?, ?, ?)",
                orderId, serviceId, quantity, new BigDecimal(price));
    }

    private void partLine(int orderId, int partId, int quantity, String price) {
        jdbc.update("INSERT INTO ChiTietPhuTung (MaPhieuSuaChua, MaPhuTung, SoLuong, DonGia) VALUES (?, ?, ?, ?)",
                orderId, partId, quantity, new BigDecimal(price));
    }

    private RequestPostProcessor asCustomer(String username) {
        return user(username).roles("CUSTOMER");
    }

    // ------------------------------------------------------------------ test

    @Test
    void historyListDetailAndOwnershipRunAgainstTheRealSchema() throws Exception {
        String tag = Long.toString(System.nanoTime()).substring(8);
        int customerA = customer(tag + "1", "IT Khach A " + tag);
        int customerB = customer(tag + "2", "IT Khach B " + tag);
        String usernameA = "it_hist_a_" + tag;
        account(usernameA, customerA);
        account("it_hist_b_" + tag, customerB);

        int vehicleA1 = vehicle(customerA, "IT" + tag + "A1");
        int vehicleA2 = vehicle(customerA, "IT" + tag + "A2");
        int vehicleA3 = vehicle(customerA, "IT" + tag + "A3");
        int vehicleB1 = vehicle(customerB, "IT" + tag + "B1");

        int maintenance = service(tag + "m", "BAO_DUONG", "300000");
        int repair = service(tag + "r", "SUA_CHUA", "500000");
        int partX = part(tag + "x", "90000");

        // A1: bảo dưỡng 2 x 300000 + phụ tùng 3 x 90000 = 870000, hoàn tất mới nhất.
        int doneNewest = repairOrder(vehicleA1, "HOAN_TAT", "2026-09-20 10:00:00", "Hoàn tất tốt");
        serviceLine(doneNewest, maintenance, 2, "300000");
        partLine(doneNewest, partX, 3, "90000");
        // A2: sửa chữa 1 x 500000, hoàn tất cũ hơn, KetQua NULL.
        int doneOlder = repairOrder(vehicleA2, "HOAN_TAT", "2026-06-01 09:00:00", null);
        serviceLine(doneOlder, repair, 1, "500000");
        // A3: chưa hoàn tất => KHÔNG được xuất hiện trong lịch sử.
        int inProgress = repairOrder(vehicleA3, "DANG_SUA", null, null);
        serviceLine(inProgress, repair, 1, "500000");
        // B1: của khách hàng khác.
        int otherCustomers = repairOrder(vehicleB1, "HOAN_TAT", "2026-09-25 10:00:00", "Của khách B");
        serviceLine(otherCustomers, repair, 1, "777000");

        // 1) Danh sách: đúng 2 lượt hoàn tất của A, mới nhất trước, tổng chi phí từ dbo.fn_TinhTongChiPhiSuaChua.
        mockMvc.perform(get("/api/customers/me/history").with(asCustomer(usernameA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(2))
                .andExpect(jsonPath("$.data.items.length()").value(2))
                .andExpect(jsonPath("$.data.items[0].repairOrderId").value(doneNewest))
                .andExpect(jsonPath("$.data.items[0].vehicleId").value(vehicleA1))
                .andExpect(jsonPath("$.data.items[0].category").value("BAO_DUONG"))
                .andExpect(jsonPath("$.data.items[0].serviceCount").value(1))
                .andExpect(jsonPath("$.data.items[0].partCount").value(1))
                .andExpect(jsonPath("$.data.items[0].totalCost").value(870000.0))
                .andExpect(jsonPath("$.data.items[1].repairOrderId").value(doneOlder))
                .andExpect(jsonPath("$.data.items[1].category").value("SUA_CHUA"))
                .andExpect(jsonPath("$.data.items[1].totalCost").value(500000.0))
                .andExpect(jsonPath("$.data.items[1].result").value(""));

        // 2) Chi tiết: dịch vụ, phụ tùng và tổng khớp nhau và khớp function SQL.
        mockMvc.perform(get("/api/customers/me/history/" + doneNewest).with(asCustomer(usernameA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.item.totalCost").value(870000.0))
                .andExpect(jsonPath("$.data.services.length()").value(1))
                .andExpect(jsonPath("$.data.services[0].lineTotal").value(600000.0))
                .andExpect(jsonPath("$.data.parts.length()").value(1))
                .andExpect(jsonPath("$.data.parts[0].quantity").value(3))
                .andExpect(jsonPath("$.data.parts[0].lineTotal").value(270000.0))
                .andExpect(jsonPath("$.data.serviceTotal").value(600000.0))
                .andExpect(jsonPath("$.data.partsTotal").value(270000.0));

        // 3) Phiếu chưa hoàn tất và phiếu của khách hàng khác: 404 như nhau.
        mockMvc.perform(get("/api/customers/me/history/" + inProgress).with(asCustomer(usernameA)))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/customers/me/history/" + otherCustomers).with(asCustomer(usernameA)))
                .andExpect(status().isNotFound());

        // 4) Lọc theo xe: xe của mình OK, xe của khách khác 404.
        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", String.valueOf(vehicleA2)).with(asCustomer(usernameA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.items[0].repairOrderId").value(doneOlder));
        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", String.valueOf(vehicleB1)).with(asCustomer(usernameA)))
                .andExpect(status().isNotFound());

        // 5) Danh sách xe để lọc: chỉ xe của A có lịch sử hoàn tất (không có A3, không có B1).
        mockMvc.perform(get("/api/customers/me/history/vehicles").with(asCustomer(usernameA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(2))
                .andExpect(jsonPath("$.data[?(@.vehicleId == " + vehicleA3 + ")]").isEmpty())
                .andExpect(jsonPath("$.data[?(@.vehicleId == " + vehicleB1 + ")]").isEmpty());

        // 6) Truyền customerId của người khác không đổi được dữ liệu.
        mockMvc.perform(get("/api/customers/me/history").param("customerId", String.valueOf(customerB)).with(asCustomer(usernameA)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.totalElements").value(2));
    }

    @Test
    void longHistoryIsPagedWithoutTruncationAtTwoHundred() throws Exception {
        String tag = Long.toString(System.nanoTime()).substring(8);
        int customerId = customer(tag + "3", "IT Khach Dai " + tag);
        String username = "it_hist_long_" + tag;
        account(username, customerId);
        int vehicleId = vehicle(customerId, "IT" + tag + "L");

        // 205 lượt hoàn tất, ngày hoàn thành tăng dần theo từng lượt để kiểm tra thứ tự mới nhất trước.
        jdbc.update("""
                INSERT INTO PhieuTiepNhan (MaXe, NgayTiepNhan)
                SELECT TOP (205) ?, DATEADD(MINUTE, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)), '2025-01-01')
                FROM sys.all_objects
                """, vehicleId);
        jdbc.update("""
                INSERT INTO PhieuSuaChua (MaTiepNhan, NgayLap, NgayBatDau, NgayHoanThanh, TrangThai)
                SELECT MaTiepNhan, NgayTiepNhan, NgayTiepNhan, NgayTiepNhan, N'HOAN_TAT'
                FROM PhieuTiepNhan WHERE MaXe = ?
                """, vehicleId);
        Integer newestId = jdbc.queryForObject("""
                SELECT TOP 1 ps.MaPhieuSuaChua FROM PhieuSuaChua ps
                JOIN PhieuTiepNhan tn ON tn.MaTiepNhan = ps.MaTiepNhan
                WHERE tn.MaXe = ? ORDER BY ps.NgayHoanThanh DESC, ps.MaPhieuSuaChua DESC
                """, Integer.class, vehicleId);

        Set<Integer> seen = new HashSet<>();
        for (int page = 0; page < 5; page++) {
            String body = mockMvc.perform(get("/api/customers/me/history").param("page", String.valueOf(page)).param("size", "50")
                            .with(asCustomer(username)))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.totalElements").value(205))
                    .andExpect(jsonPath("$.data.totalPages").value(5))
                    .andReturn().getResponse().getContentAsString();
            JsonNode items = new ObjectMapper().readTree(body).path("data").path("items");
            assertEquals(page == 4 ? 5 : 50, items.size(), "Số dòng của trang " + page);
            if (page == 0) assertEquals(newestId.intValue(), items.get(0).path("repairOrderId").asInt());
            items.forEach(item -> assertTrue(seen.add(item.path("repairOrderId").asInt()), "Không trùng lượt giữa các trang"));
        }
        assertEquals(205, seen.size(), "Phải đọc đủ 205 lượt, không bị cắt ở 200");
    }
}
