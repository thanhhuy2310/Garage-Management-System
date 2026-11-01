package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gara.quanlygara.service.MaintenanceReminderDispatcher;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;
import org.springframework.test.web.servlet.MockMvc;
import java.util.*;
import java.time.LocalDate;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.http.MediaType.APPLICATION_JSON;

@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
@SpringBootTest(properties={"app.jwt.secret=verification-secret-with-more-than-32-characters","spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
class MaintenanceSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;
    @Autowired MaintenanceReminderDispatcher dispatcher;
    Integer employee, customer, vehicle, service, reminder;
    String manager, owner;
    int insert(String table,String key,Map<String,Object> values) {
        return new SimpleJdbcInsert(jdbc).withTableName(table).usingGeneratedKeyColumns(key)
            .usingColumns(values.keySet().toArray(String[]::new)).executeAndReturnKey(values).intValue();
    }
    @BeforeEach void prepare() {
        assertTrue(jdbc.queryForObject("SELECT DB_NAME()",String.class).matches("QuanLyGaraOTo_Verify_\\d{8}"));
        String tag=UUID.randomUUID().toString().replace("-","").substring(0,10);
        manager="minhhuy_"+tag;owner="thanhha_"+tag;
        employee=insert("NhanVien","MaNhanVien",Map.of("HoTen","Trần Minh Huy","ChucVu","Quản lý"));
        customer=insert("KhachHang","MaKhachHang",Map.of("HoTen","Nguyễn Thanh Hà","SoDienThoai",tag));
        insert("TaiKhoan","MaTaiKhoan",Map.of("TenDangNhap",manager,"MatKhauHash","unused-it-password","VaiTro","MANAGER","MaNhanVien",employee));
        insert("TaiKhoan","MaTaiKhoan",Map.of("TenDangNhap",owner,"MatKhauHash","unused-it-password","VaiTro","CUSTOMER","MaKhachHang",customer));
        vehicle=insert("Xe","MaXe",Map.of("MaKhachHang",customer,"BienSo","51A-"+tag,"SoKm",20000));
    }
    @AfterEach void cleanup() {
        if(customer!=null)jdbc.update("DELETE FROM ThongBao WHERE MaKhachHang=?",customer);
        if(reminder!=null)jdbc.update("DELETE FROM LichNhacBaoDuong WHERE MaLichNhac=?",reminder);
        if(service!=null)jdbc.update("DELETE FROM DichVu WHERE MaDichVu=?",service);
        if(vehicle!=null)jdbc.update("DELETE FROM Xe WHERE MaXe=?",vehicle);
        jdbc.update("DELETE FROM TaiKhoan WHERE TenDangNhap IN (?,?)",manager,owner);
        if(employee!=null)jdbc.update("DELETE FROM NhanVien WHERE MaNhanVien=?",employee);
        if(customer!=null)jdbc.update("DELETE FROM KhachHang WHERE MaKhachHang=?",customer);
    }
    @Test void canonicalPricesAndLegacyMaintenancePersistReminderAndOwnedNotification()throws Exception {
        String body=mvc.perform(post("/api/services").with(user(manager).roles("MANAGER"))
            .contentType(APPLICATION_JSON).content(json.writeValueAsString(Map.of("name","Bảo dưỡng định kỳ","type"," Bảo dưỡng ","unitPrice",200000))))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        service=json.readTree(body).path("data").path("id").asInt();
        assertEquals("BAO_DUONG",jdbc.queryForObject("SELECT LoaiDichVu FROM DichVu WHERE MaDichVu=?",String.class,service));
        // A legacy label must be readable without rewriting the old catalog row.
        jdbc.update("UPDATE DichVu SET LoaiDichVu=N'Bảo dưỡng' WHERE MaDichVu=?",service);
        mvc.perform(get("/api/services/"+service).with(user(manager).roles("MANAGER")))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.type").value("BAO_DUONG"));
        LocalDate due=LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(30);
        String request=json.writeValueAsString(Map.of("vehicleId",vehicle,"serviceId",service,"dueDate",due.toString(),"note","Bảo dưỡng theo lịch"));
        mvc.perform(post("/api/maintenance-reminders").with(user(owner).roles("CUSTOMER")).contentType(APPLICATION_JSON).content(request)).andExpect(status().isForbidden());
        body=mvc.perform(post("/api/maintenance-reminders").with(user(manager).roles("MANAGER")).contentType(APPLICATION_JSON).content(request))
            .andExpect(status().isCreated()).andReturn().getResponse().getContentAsString();
        reminder=json.readTree(body).path("data").path("id").asInt();
        assertEquals(service,jdbc.queryForObject("SELECT MaDichVu FROM LichNhacBaoDuong WHERE MaLichNhac=?",Integer.class,reminder));
        assertEquals("Bảo dưỡng",jdbc.queryForObject("SELECT LoaiDichVu FROM DichVu WHERE MaDichVu=?",String.class,service));
        var item=new MaintenanceReminderDispatcher.DueReminder(reminder,vehicle,customer,"51A",due,null,20000,"Bảo dưỡng theo lịch","Bảo dưỡng định kỳ");
        assertTrue(dispatcher.dispatch(item,due));assertFalse(dispatcher.dispatch(item,due));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM ThongBao WHERE MaLichNhac=? AND MaKhachHang=?",Integer.class,reminder,customer));
        int notification=jdbc.queryForObject("SELECT MaThongBao FROM ThongBao WHERE MaLichNhac=?",Integer.class,reminder);
        mvc.perform(get("/api/customers/me/notifications").with(user(owner).roles("CUSTOMER")))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.items[0].type").value("maintenance"));
        mvc.perform(patch("/api/customers/me/notifications/"+notification+"/read").with(user(owner).roles("CUSTOMER")))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.isRead").value(true));
        assertEquals(1,jdbc.queryForObject("SELECT DaDoc FROM ThongBao WHERE MaThongBao=?",Integer.class,notification));
        mvc.perform(get("/api/customers/me/notifications/unread-count").with(user(owner).roles("CUSTOMER")))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.count").value(0));
    }
}
