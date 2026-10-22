// TV3-TUAN10
package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.gara.quanlygara.service.MaintenanceReminderService;
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
import java.sql.Date;
import java.sql.Timestamp;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Integration test trên SQL Server THẬT cho thông báo: trigger LichHen/PhieuSuaChua (V004), chỉ mục duy nhất,
 * scheduler/MaintenanceReminderService.processDue và API đọc/đánh dấu đã đọc.
 * Không chạy trong ".\mvnw.cmd test" (tên *IT) và bị khóa bởi biến môi trường RUN_SQLSERVER_IT.
 *   $env:RUN_SQLSERVER_IT = "true"     # cùng DB_URL / DB_USERNAME / DB_PASSWORD như khi chạy backend
 *   .\mvnw.cmd -Dtest=NotificationsSqlServerIT test
 * Yêu cầu đã chạy V004. Dữ liệu test nằm trong transaction và bị ROLLBACK; @AfterTransaction kiểm tra số dòng không đổi.
 */
@EnabledIfEnvironmentVariable(named = "RUN_SQLSERVER_IT", matches = "true")
@SpringBootTest(properties = "app.jwt.secret=it-secret-that-is-at-least-32-characters-long")
@AutoConfigureMockMvc
@Transactional
class NotificationsSqlServerIT {

    private static final List<String> TABLES = List.of(
            "KhachHang", "TaiKhoan", "Xe", "LichHen", "PhieuTiepNhan", "PhieuSuaChua", "ThongBao", "LichNhacBaoDuong");

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private JdbcTemplate jdbc;

    @Autowired
    private MaintenanceReminderService reminderService;

    private Map<String, Long> countsBefore;
    private Long stockBefore;

    @BeforeTransaction
    void remember() {
        countsBefore = counts();
        stockBefore = jdbc.queryForObject("SELECT COALESCE(SUM(CAST(SoLuongTon AS BIGINT)), 0) FROM PhuTung", Long.class);
    }

    @AfterTransaction
    void everythingIsRolledBack() {
        assertEquals(countsBefore, counts(), "Dữ liệu test phải được rollback hoàn toàn");
        assertEquals(stockBefore, jdbc.queryForObject("SELECT COALESCE(SUM(CAST(SoLuongTon AS BIGINT)), 0) FROM PhuTung", Long.class));
    }

    private Map<String, Long> counts() {
        Map<String, Long> result = new LinkedHashMap<>();
        for (String table : TABLES) result.put(table, jdbc.queryForObject("SELECT COUNT_BIG(*) FROM " + table, Long.class));
        return result;
    }

    private int insert(String table, String keyColumn, Map<String, Object> values) {
        return new SimpleJdbcInsert(jdbc).withTableName(table).usingGeneratedKeyColumns(keyColumn)
                .usingColumns(values.keySet().toArray(new String[0])).executeAndReturnKey(values).intValue();
    }

    private int customer(String tag, String name) {
        return insert("KhachHang", "MaKhachHang", Map.of("HoTen", name, "SoDienThoai", "09" + tag));
    }

    private void account(String username, int customerId) {
        insert("TaiKhoan", "MaTaiKhoan", Map.of(
                "TenDangNhap", username, "MatKhauHash", "it-not-a-real-hash", "VaiTro", "CUSTOMER", "MaKhachHang", customerId));
    }

    private int vehicle(int customerId, String plate, Integer km) {
        Map<String, Object> values = new HashMap<>();
        values.put("MaKhachHang", customerId);
        values.put("BienSo", plate);
        values.put("HangXe", "Toyota");
        values.put("DongXe", "Camry");
        if (km != null) values.put("SoKm", km);
        return insert("Xe", "MaXe", values);
    }

    private int appointment(int customerId, int vehicleId, String date, String time, String status) {
        return insert("LichHen", "MaLichHen", Map.of(
                "MaKhachHang", customerId, "MaXe", vehicleId, "NgayHen", Date.valueOf(date),
                "GioHen", java.sql.Time.valueOf(time), "TrangThai", status));
    }

    private int reminder(int vehicleId, String dueDate, Integer dueKm, String status) {
        Map<String, Object> values = new HashMap<>();
        values.put("MaXe", vehicleId);
        if (dueDate != null) values.put("NgayDenHan", Date.valueOf(dueDate));
        if (dueKm != null) values.put("SoKmDenHan", dueKm);
        values.put("TrangThai", status);
        if ("DA_NHAC".equals(status)) values.put("NgayNhac", Timestamp.valueOf("2026-01-01 08:00:00"));
        return insert("LichNhacBaoDuong", "MaLichNhac", values);
    }

    private RequestPostProcessor asCustomer(String username) {
        return user(username).roles("CUSTOMER");
    }

    private JsonNode list(String username) throws Exception {
        String body = mockMvc.perform(get("/api/customers/me/notifications").with(asCustomer(username)))
                .andExpect(status().isOk()).andReturn().getResponse().getContentAsString();
        return new ObjectMapper().readTree(body).path("data");
    }

    @Test
    void appointmentAndRepairTriggersCreateExactlyTheRightNotificationsForTheRightCustomer() throws Exception {
        String tag = Long.toString(System.nanoTime()).substring(8);
        int customerA = customer(tag + "1", "IT Khach A " + tag);
        int customerB = customer(tag + "2", "IT Khach B " + tag);
        String usernameA = "it_noti_a_" + tag;
        account(usernameA, customerA);
        int vehicleA = vehicle(customerA, "IT" + tag + "A", 9000);
        int vehicleB = vehicle(customerB, "IT" + tag + "B", null);

        int appointmentA = appointment(customerA, vehicleA, "2030-01-10", "09:00:00", "CHO_XAC_NHAN");
        appointment(customerB, vehicleB, "2030-01-10", "10:00:00", "CHO_XAC_NHAN");
        assertEquals(1, list(usernameA).path("totalElements").asInt(), "Lịch hẹn mới sinh đúng 1 thông báo cho khách A");

        jdbc.update("UPDATE LichHen SET TrangThai = 'CHO_XAC_NHAN', NgayHen = '2030-01-10' WHERE MaLichHen = ?", appointmentA);
        assertEquals(1, list(usernameA).path("totalElements").asInt(), "Cập nhật không đổi gì không sinh thông báo");

        jdbc.update("UPDATE LichHen SET TrangThai = 'DA_XAC_NHAN' WHERE MaLichHen = ?", appointmentA);
        jdbc.update("UPDATE LichHen SET NgayHen = '2030-01-12' WHERE MaLichHen = ?", appointmentA);
        jdbc.update("UPDATE LichHen SET TrangThai = 'DA_HUY' WHERE MaLichHen = ?", appointmentA);
        assertEquals(4, list(usernameA).path("totalElements").asInt(), "Xác nhận, đổi ngày và hủy: mỗi sự kiện một thông báo");

        // Phiếu sửa chữa của khách A: tiến độ rồi hoàn tất.
        int reception = insert("PhieuTiepNhan", "MaTiepNhan", Map.of("MaXe", vehicleA, "NgayTiepNhan", Timestamp.valueOf("2026-10-01 08:00:00")));
        Map<String, Object> order = new HashMap<>();
        order.put("MaTiepNhan", reception);
        order.put("NgayLap", Timestamp.valueOf("2026-10-01 09:00:00"));
        order.put("NgayBatDau", Timestamp.valueOf("2026-10-02 08:00:00"));
        order.put("TrangThai", "DANG_SUA");
        int repairOrder = insert("PhieuSuaChua", "MaPhieuSuaChua", order);
        jdbc.update("UPDATE PhieuSuaChua SET TrangThai = 'CHO_PHU_TUNG' WHERE MaPhieuSuaChua = ?", repairOrder);
        jdbc.update("UPDATE PhieuSuaChua SET TrangThai = 'CHO_PHU_TUNG' WHERE MaPhieuSuaChua = ?", repairOrder);
        jdbc.update("UPDATE PhieuSuaChua SET TrangThai = 'HOAN_TAT', NgayHoanThanh = SYSDATETIME() WHERE MaPhieuSuaChua = ?", repairOrder);
        jdbc.update("UPDATE PhieuSuaChua SET TrangThai = 'DANG_SUA' WHERE MaPhieuSuaChua = ?", repairOrder);
        jdbc.update("UPDATE PhieuSuaChua SET TrangThai = 'HOAN_TAT' WHERE MaPhieuSuaChua = ?", repairOrder);

        assertEquals(1, jdbc.queryForObject(
                "SELECT COUNT(*) FROM ThongBao WHERE MaPhieuSuaChua = ? AND LoaiThongBao = 'HOAN_TAT_SUA_CHUA'", Integer.class, repairOrder),
                "Hoàn tất chỉ có đúng một thông báo (trigger gốc chống trùng giữ nguyên)");
        assertEquals(2, jdbc.queryForObject(
                "SELECT COUNT(*) FROM ThongBao WHERE MaPhieuSuaChua = ? AND LoaiThongBao = 'TIEN_DO_SUA_CHUA'", Integer.class, repairOrder));

        // API: danh sách của khách A (mới nhất trước), chưa đọc, đánh dấu đã đọc và quyền sở hữu.
        JsonNode data = list(usernameA);
        assertEquals(4 + 3, data.path("totalElements").asInt());
        long newestId = data.path("items").get(0).path("id").asLong();
        long customerBsNotification = jdbc.queryForObject(
                "SELECT TOP 1 MaThongBao FROM ThongBao WHERE MaKhachHang = ? ORDER BY MaThongBao", Long.class, customerB);

        mockMvc.perform(get("/api/customers/me/notifications/unread-count").with(asCustomer(usernameA)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.count").value(7));
        mockMvc.perform(patch("/api/customers/me/notifications/" + newestId + "/read").with(asCustomer(usernameA)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.isRead").value(true));
        mockMvc.perform(get("/api/customers/me/notifications/unread-count").with(asCustomer(usernameA)))
                .andExpect(jsonPath("$.data.count").value(6));
        mockMvc.perform(patch("/api/customers/me/notifications/" + customerBsNotification + "/read").with(asCustomer(usernameA)))
                .andExpect(status().isNotFound());
        assertEquals(0, jdbc.queryForObject("SELECT DaDoc FROM ThongBao WHERE MaThongBao = ?", Integer.class, customerBsNotification),
                "Thông báo của khách B không bị đổi");
        mockMvc.perform(patch("/api/customers/me/notifications/read-all").with(asCustomer(usernameA)))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.updatedCount").value(6)).andExpect(jsonPath("$.data.unreadCount").value(0));
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM ThongBao WHERE MaKhachHang = ? AND DaDoc = 0", Integer.class, customerB),
                "Đánh dấu tất cả đã đọc của A không đụng tới thông báo của B");
    }

    @Test
    void dueMaintenanceRemindersCreateOneNotificationEachEvenWhenTheJobRunsRepeatedly() throws Exception {
        String tag = Long.toString(System.nanoTime()).substring(8);
        int customerA = customer(tag + "3", "IT Khach A " + tag);
        int customerB = customer(tag + "4", "IT Khach B " + tag);
        String usernameA = "it_noti_m_" + tag;
        account(usernameA, customerA);
        int vehicleA = vehicle(customerA, "IT" + tag + "M", 9000);
        int vehicleB = vehicle(customerB, "IT" + tag + "N", 100);
        LocalDate today = LocalDate.of(2026, 10, 20);

        int dueByDate = reminder(vehicleA, "2026-10-20", null, "CHO_NHAC");
        int notDueByDate = reminder(vehicleA, "2026-10-21", null, "CHO_NHAC");
        int dueByKm = reminder(vehicleA, null, 9000, "CHO_NHAC");
        int notDueByKm = reminder(vehicleA, null, 9001, "CHO_NHAC");
        int cancelled = reminder(vehicleA, "2020-01-01", null, "DA_HUY");
        int alreadyReminded = reminder(vehicleA, "2020-01-01", null, "DA_NHAC");
        int otherCustomersDue = reminder(vehicleB, "2020-01-01", null, "CHO_NHAC");

        assertEquals(3, reminderService.processDue(today), "Chỉ 3 lịch đến hạn: ngày, km của khách A và lịch của khách B");
        assertEquals(0, reminderService.processDue(today), "Chạy lại không tạo thêm");
        assertEquals(0, reminderService.processDue(today.plusDays(1)), "Ngày khác: lịch đã nhắc không bị nhắc lại");

        assertEquals(3, jdbc.queryForObject("SELECT COUNT(*) FROM ThongBao WHERE MaLichNhac IS NOT NULL AND MaLichNhac IN (?,?,?,?,?,?,?)",
                Integer.class, dueByDate, notDueByDate, dueByKm, notDueByKm, cancelled, alreadyReminded, otherCustomersDue));
        assertEquals("DA_NHAC", jdbc.queryForObject("SELECT TrangThai FROM LichNhacBaoDuong WHERE MaLichNhac = ?", String.class, dueByDate));
        assertEquals("CHO_NHAC", jdbc.queryForObject("SELECT TrangThai FROM LichNhacBaoDuong WHERE MaLichNhac = ?", String.class, notDueByKm));
        assertEquals("DA_HUY", jdbc.queryForObject("SELECT TrangThai FROM LichNhacBaoDuong WHERE MaLichNhac = ?", String.class, cancelled));

        JsonNode data = list(usernameA);
        assertEquals(2, data.path("totalElements").asInt(), "Khách A chỉ thấy 2 thông báo nhắc của mình");
        data.path("items").forEach(item -> assertEquals("maintenance", item.path("type").asText()));
    }
}
