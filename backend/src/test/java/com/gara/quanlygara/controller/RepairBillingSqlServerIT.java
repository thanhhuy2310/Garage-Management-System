package com.gara.quanlygara.controller;

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
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.junit.jupiter.api.Assumptions.assumeTrue;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

/** Real application endpoints, real JWTs and SQL Server triggers. The verification transaction rolls back. */
@EnabledIfEnvironmentVariable(named = "RUN_SQLSERVER_IT", matches = "true")
@SpringBootTest(properties = {"spring.jpa.hibernate.ddl-auto=none", "spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
@Transactional
class RepairBillingSqlServerIT {
    @org.springframework.boot.test.context.TestConfiguration
    static class OpeningHours {
        @org.springframework.context.annotation.Bean @org.springframework.context.annotation.Primary
        com.gara.quanlygara.service.AppointmentService morningBookings(com.gara.quanlygara.repository.AppointmentRepository repo) {
            var zone=ZoneId.of("Asia/Ho_Chi_Minh");
            var opening=java.time.LocalDate.now(zone).atStartOfDay(zone);
            return new com.gara.quanlygara.service.AppointmentService(repo,java.time.Clock.fixed(opening.toInstant(),zone));
        }
    }
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired PasswordEncoder passwords;
    @Autowired MaintenanceReminderService reminders;

    private final String tag = UUID.randomUUID().toString().substring(0, 8);
    private final String password = UUID.randomUUID().toString();

    @Test
    void bookedRepairUsesApprovedPricesActualPartsAndOnePayment() throws Exception {
        assertTrue(jdbc.queryForObject("SELECT DB_NAME()", String.class).matches("QuanLyGaraOTo_Verify_\\d{8}"));
        String adminName = "nhatminh_" + tag;
        int adminId = employee("Đỗ Nhật Minh", "Quản trị viên");
        insert("TaiKhoan", "MaTaiKhoan", Map.of("TenDangNhap", adminName, "MatKhauHash", passwords.encode(password),
                "VaiTro", "ADMIN", "MaNhanVien", adminId));
        String admin = login(adminName);
        String manager = staffLogin(admin, employee("Nguyễn Quang Huy", "Quản lý"), "quanghuy_", "MANAGER");
        int mechanicId = send(post("/api/employees"), manager, Map.of("fullName", "Trần Quốc Bình",
                "position", "Kỹ thuật viên", "technician", true), 201).path("id").asInt();
        String mechanic = staffLogin(admin, mechanicId, "quocbinh_", "TECHNICIAN");
        String advisor = staffLogin(admin, employee("Lê Thanh Hà", "Cố vấn dịch vụ"), "thanhha_", "RECEPTIONIST");
        String username = "minhhanh_" + tag;
        String phone = "09" + String.format("%08d", Long.parseLong(tag, 16) % 100000000L);
        var registered = send(post("/api/auth/register"), null, Map.of("fullName", "Nguyễn Minh Hạnh", "phone", phone, "email",username+"@example.invalid",
                "username", username, "password", password), 201);
        int customerId = registered.path("account").path("customerId").asInt();
        String customer = login(username);
        int vehicle = send(post("/api/vehicles"), customer, Map.of("customerId", customerId,
                "licensePlate", "51A-" + tag, "brand", "Toyota", "model", "Vios", "mileage", 20000), 201).path("id").asInt();
        int service = send(post("/api/services"), manager, Map.of("name", "Bảo dưỡng phanh", "type", "Bảo dưỡng",
                "unitPrice", 125000), 201).path("id").asInt();
        int warehouse = insert("Kho", "MaKho", Map.of("TenKho", "Kho phụ tùng phía sau"));
        int part = insert("PhuTung", "MaPhuTung", Map.of("MaKho", warehouse, "TenPhuTung", "Lọc dầu",
                "DonGia", 50000, "SoLuongTon", 10));

        var now = LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        var slot = now.toLocalDate().atTime(9,0);
        send(put("/api/appointments/schedule"), manager, Map.of("dayOfWeek", slot.getDayOfWeek().getValue(),
                "time", slot.toLocalTime().toString(), "capacity", 5), 200);
        var booking = send(post("/api/appointments"), customer, Map.of("serviceId", service, "vehicleId", vehicle,
                "date", slot.toLocalDate().toString(), "time", slot.toLocalTime().toString()), 201);
        int bookingId = booking.path("id").asInt();
        String bookingPath = "/api/appointments/" + bookingId;
        assertEquals(customerId, send(get(bookingPath), advisor, null, 200).path("customerId").asInt());
        send(patch(bookingPath + "/confirm"), advisor, Map.of("version", booking.path("version").asInt()), 200);
        int reception = send(post("/api/receptions"), advisor, Map.of("appointmentId", bookingId, "customerId", customerId,
                "vehicleId", vehicle, "mileage", 20000, "initialCondition", "Phanh có tiếng kêu",
                "customerRequest", "Kiểm tra phanh và thay lọc dầu"), 201).path("id").asInt();
        assertEquals("DA_DEN", send(get(bookingPath), customer, null, 200).path("status").asText());
        var repair = send(post("/api/repair-orders"), advisor, Map.of("receptionId", reception,
                "services", List.of(Map.of("serviceId", service, "quantity", 2))), 201);
        int order = repair.path("order").path("id").asInt();
        String orderPath = "/api/repair-orders/" + order;
        send(post(orderPath + "/technicians"), manager, Map.of("technicianId", mechanicId), 201);
        progress(orderPath, mechanic, "MOI_TAO", "DANG_KIEM_TRA");

        var quote = send(post("/api/quotations"), advisor, Map.of("repairOrderId", order, "lines", List.of(
                Map.of("kind", "SERVICE", "itemId", service, "quantity", 2),
                Map.of("kind", "PART", "itemId", part, "quantity", 2))), 201);
        assertEquals(350000, quote.path("total").asInt());
        String quotePath = "/api/quotations/" + quote.path("id").asInt();
        var sent = send(post(quotePath + "/send"), advisor, Map.of("version", quote.path("version").asInt()), 200);
        send(post(quotePath + "/decision"), customer, Map.of("version", sent.path("version").asInt(), "accepted", true), 200);
        progress(orderPath, mechanic, "DANG_KIEM_TRA", "DANG_SUA");
        String linePath = orderPath + "/services/" + service;
        progress(linePath, mechanic, "CHO_SUA", "DANG_SUA");
        var issue = send(post("/api/warehouse/exports"), manager, Map.of("repairOrderId", order,
                "requestedTechnicianId", mechanicId, "reason", "Thay lọc dầu", "items", List.of(Map.of("partId", part, "quantity", 2))), 201);
        assertEquals(10, jdbc.queryForObject("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?", Integer.class, part));
        send(post("/api/warehouse/exports/" + issue.path("id").asInt() + "/items/" + part + "/confirm"),
                mechanic, Map.of("actualUsed", 1), 200);
        assertEquals(9, jdbc.queryForObject("SELECT SoLuongTon FROM PhuTung WHERE MaPhuTung=?", Integer.class, part));
        progress(linePath, mechanic, "DANG_SUA", "HOAN_TAT");
        progress(orderPath, mechanic, "DANG_SUA", "HOAN_TAT");
        var tracking = send(get("/api/customer/repairs"), customer, null, 200);
        assertEquals(vehicle, tracking.get(0).path("order").path("vehicleId").asInt());
        assertEquals("HOAN_TAT", tracking.get(0).path("order").path("status").asText());

        var bill = send(post("/api/invoices"), advisor, Map.of("repairOrderId", order), 201).path("invoice");
        int invoice = bill.path("id").asInt();
        assertEquals(300000, bill.path("total").asInt());
        var before = send(get("/api/reports/dashboard"), manager, null, 200).path("collectedToday").decimalValue();
        var payment = Map.of("amount", 300000, "method", "TIEN_MAT", "requestId", UUID.randomUUID().toString());
        for (int attempt = 0; attempt < 2; attempt++) {
            var paid = send(post("/api/invoices/" + invoice + "/payments"), advisor, payment, 200);
            assertEquals(0, paid.path("invoice").path("remaining").asInt());
            assertEquals(1, paid.path("payments").size());
        }
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaHoaDon=?", Integer.class, invoice));
        var after = send(get("/api/reports/dashboard"), manager, null, 200).path("collectedToday").decimalValue();
        assertEquals(0, after.subtract(before).compareTo(BigDecimal.valueOf(300000)));
        var history = send(get("/api/customers/me/history"), customer, null, 200).path("items").get(0);
        assertEquals(order, history.path("repairOrderId").asInt());
        assertEquals(300000, history.path("totalCost").asInt());
        var reminder = send(post("/api/maintenance-reminders"), advisor, Map.of("vehicleId", vehicle, "serviceId", service,
                "dueDate", slot.toLocalDate().toString()), 201);
        reminders.processDue(slot.toLocalDate());
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM ThongBao WHERE MaLichNhac=? AND MaKhachHang=?", Integer.class,
                reminder.path("id").asInt(), customerId));
        assertTrue(send(get("/api/customers/me/notifications/unread-count"), customer, null, 200).path("count").asInt() > 0);
    }

    @Test
    void loggingOutRevokesOnlyThePresentedToken() throws Exception {
        assertTrue(jdbc.queryForObject("SELECT DB_NAME()",String.class).startsWith("QuanLyGaraOTo_Verify_"));
        String username="minhan_"+tag;
        String phone="09"+String.format("%08d",Integer.toUnsignedLong(tag.hashCode())%100000000);
        send(post("/api/auth/register"),null,Map.of("fullName","Nguyễn Minh An","phone",phone,"email",username+"@example.invalid","username",username,"password",password),201);
        String first=login(username), second=login(username);
        assertNotEquals(first,second);
        send(post("/api/auth/logout"),first,null,200);
        send(get("/api/auth/me"),first,null,401);
        send(get("/api/auth/me"),second,null,200);
    }

    @Test
    void browserCookiesRestoreRememberedSessionsAndRejectReplay() throws Exception {
        assertTrue(jdbc.queryForObject("SELECT DB_NAME()",String.class).startsWith("QuanLyGaraOTo_Verify_"));
        String username="hanh_"+tag;
        String phone="09"+String.format("%08d",Integer.toUnsignedLong(tag.hashCode())%100000000);
        send(post("/api/auth/register"),null,Map.of("fullName","Nguyễn Hạnh","phone",phone,"email",username+"@example.invalid","username",username,"password",password),201);
        for(boolean remember:new boolean[]{false,true}) {
            var response=mvc.perform(post("/api/auth/login").secure(true).header("X-Garage-Client","web")
                    .param("remember",String.valueOf(remember)).contentType(APPLICATION_JSON)
                    .content(json.writeValueAsBytes(Map.of("username",username,"password",password)))).andReturn().getResponse();
            var cookie=response.getCookie("garage_session");
            assertNotNull(cookie);
            assertTrue(cookie.isHttpOnly() && cookie.getSecure());
            assertEquals(remember,cookie.getMaxAge()>0);
            assertTrue(json.readTree(response.getContentAsByteArray()).at("/data/accessToken").isNull());
            send(get("/api/auth/me").cookie(cookie),null,null,401);
            send(get("/api/auth/me").cookie(cookie).header("X-Garage-Client","web"),null,null,200);
            send(post("/api/auth/logout").cookie(cookie).header("X-Garage-Client","web"),null,null,200);
            send(get("/api/auth/me").cookie(cookie).header("X-Garage-Client","web"),null,null,401);
        }
    }

    private void progress(String path, String token, String from, String to) throws Exception {
        send(put(path + "/progress"), token, Map.of("expectedStatus", from, "status", to, "notes", "Đã kiểm tra tại xưởng."), 200);
    }

    private int employee(String name, String position) {
        return insert("NhanVien", "MaNhanVien", Map.of("HoTen", name, "ChucVu", position));
    }

    private int insert(String table, String key, Map<String, Object> values) {
        return new SimpleJdbcInsert(jdbc).withTableName(table).usingGeneratedKeyColumns(key)
                .usingColumns(values.keySet().toArray(String[]::new)).executeAndReturnKey(values).intValue();
    }

    private String staffLogin(String admin, int employee, String prefix, String role) throws Exception {
        String username = prefix + tag;
        send(post("/api/accounts"), admin, Map.of("employeeId", employee, "username", username,
                "password", password, "role", role), 201);
        return login(username);
    }

    private String login(String username) throws Exception {
        return send(post("/api/auth/login"), null, Map.of("username", username, "password", password), 200).path("accessToken").asText();
    }

    private JsonNode send(MockHttpServletRequestBuilder request, String token, Object body, int expected) throws Exception {
        if (token != null) request.header("Authorization", "Bearer " + token);
        if (body != null) request.contentType(APPLICATION_JSON).content(json.writeValueAsBytes(body));
        var result = mvc.perform(request).andReturn();
        var payload = json.readTree(result.getResponse().getContentAsByteArray());
        assertEquals(expected, result.getResponse().getStatus(), result.getRequest().getRequestURI() + " " + payload.path("message").asText());
        return payload.path("data");
    }
}
