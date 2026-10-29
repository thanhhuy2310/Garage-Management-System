package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.RequestPostProcessor;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.time.*;
import java.util.*;
import java.util.concurrent.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.http.MediaType.APPLICATION_JSON;

@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
@SpringBootTest(properties={"app.jwt.secret=verification-secret-with-more-than-32-characters","spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
class AppointmentsSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager transactionManager;
    final LocalDate date=LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")).plusDays(14);
    final String time="21:17:00";
    final List<Integer> customers=new ArrayList<>(),vehicles=new ArrayList<>(),accounts=new ArrayList<>();
    String username,otherUsername,manager;
    Integer employeeId;

    @BeforeEach void prepare() {
        String db=jdbc.queryForObject("SELECT DB_NAME()",String.class);
        assertTrue(db.startsWith("QuanLyGaraOTo_Verify_"),"Only an isolated verification database may run this test");
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM KhungGioTiepNhan WHERE Thu=? AND Gio=?",Integer.class,date.getDayOfWeek().getValue(),time),
            "Test slot must not overwrite existing configuration");
        String tag=UUID.randomUUID().toString().replace("-","").substring(0,8);
        username="minhanh_"+tag;otherUsername="hoangnam_"+tag;manager="quanghuy_"+tag;
        int a=customer("Nguyễn Minh Anh",tag+"1"), b=customer("Lê Hoàng Nam",tag+"2");
        employeeId=insert("NhanVien","MaNhanVien",Map.of("HoTen","Trần Quang Huy","ChucVu","Quản lý"));
        account(username,"CUSTOMER",a);account(otherUsername,"CUSTOMER",b);account(manager,"MANAGER",null);
        vehicle(a,"51A-"+tag);vehicle(b,"59B-"+tag);
        jdbc.update("INSERT INTO KhungGioTiepNhan(Thu,Gio,SucChua,MaTaiKhoanCapNhat) VALUES(?,?,?,?)",
            date.getDayOfWeek().getValue(),time,1,accounts.get(2));
    }
    int insert(String table,String key,Map<String,Object> values) {
        return new SimpleJdbcInsert(jdbc).withTableName(table).usingGeneratedKeyColumns(key)
            .usingColumns(values.keySet().toArray(String[]::new)).executeAndReturnKey(values).intValue();
    }
    int customer(String name,String phone) {
        int id=insert("KhachHang","MaKhachHang",Map.of("HoTen",name,"SoDienThoai",phone));customers.add(id);return id;
    }
    void account(String name,String role,Integer customer) {
        Map<String,Object> values=new HashMap<>(Map.of("TenDangNhap",name,"MatKhauHash","unused-api-test-password","VaiTro",role));
        if(customer!=null)values.put("MaKhachHang",customer);
        else values.put("MaNhanVien",employeeId);
        accounts.add(insert("TaiKhoan","MaTaiKhoan",values));
    }
    void vehicle(int customer,String plate) {
        vehicles.add(insert("Xe","MaXe",Map.of("MaKhachHang",customer,"BienSo",plate,"HangXe","Toyota","DongXe","Vios")));
    }
    RequestPostProcessor as(String name,String role) {return user(name).roles(role);}
    String body(Object value)throws Exception{return json.writeValueAsString(value);}
    Map<String,Object> booking(int index) {return Map.of("vehicleId",vehicles.get(index),"date",date.toString(),"time",time,"note","Kiểm tra phanh");}
    int create(int index,String name)throws Exception {
        var response=mvc.perform(post("/api/appointments").with(as(name,"CUSTOMER")).contentType(APPLICATION_JSON).content(body(booking(index))))
            .andDo(result -> { if(result.getResponse().getStatus()>=500) throw new AssertionError("Booking API failed",result.getResolvedException()); })
            .andExpect(status().isCreated()).andReturn().getResponse();
        return json.readTree(response.getContentAsString()).path("data").path("id").asInt();
    }
    @AfterEach void cleanup() {
        if(accounts.isEmpty())return;
        new TransactionTemplate(transactionManager).executeWithoutResult(tx->{
            for(int customer:customers) {
                jdbc.update("DELETE FROM LichSuLichHen WHERE MaLichHen IN(SELECT MaLichHen FROM LichHen WHERE MaKhachHang=?)",customer);
                jdbc.update("DELETE FROM ThongBao WHERE MaKhachHang=?",customer);
                jdbc.update("DELETE FROM LichHen WHERE MaKhachHang=?",customer);
            }
            for(int id:accounts) jdbc.update("DELETE FROM KhungGioTiepNhan WHERE MaTaiKhoanCapNhat=?",id);
            for(int id:accounts)jdbc.update("DELETE FROM TaiKhoan WHERE MaTaiKhoan=?",id);
            for(int id:vehicles)jdbc.update("DELETE FROM Xe WHERE MaXe=?",id);
            for(int id:customers)jdbc.update("DELETE FROM KhachHang WHERE MaKhachHang=?",id);
            if(employeeId!=null)jdbc.update("DELETE FROM NhanVien WHERE MaNhanVien=?",employeeId);
        });
    }
    @Test void persistenceOwnershipStatusHistoryAndNotifications()throws Exception {
        int id=create(0,username);
        assertEquals("CHO_XAC_NHAN",jdbc.queryForObject("SELECT TrangThai FROM LichHen WHERE MaLichHen=?",String.class,id));
        mvc.perform(get("/api/appointments/"+id).with(as(username,"CUSTOMER"))).andExpect(status().isOk()).andExpect(jsonPath("$.data.vehicleId").value(vehicles.get(0)));
        mvc.perform(get("/api/appointments/"+id).with(as(otherUsername,"CUSTOMER"))).andExpect(status().isNotFound());
        mvc.perform(post("/api/appointments").with(as(otherUsername,"CUSTOMER")).contentType(APPLICATION_JSON).content(body(booking(0)))).andExpect(status().isNotFound());
        mvc.perform(patch("/api/appointments/"+id+"/confirm").with(as(username,"CUSTOMER")).contentType(APPLICATION_JSON).content("{\"version\":0}")).andExpect(status().isForbidden());
        mvc.perform(patch("/api/appointments/"+id+"/confirm").with(as(manager,"MANAGER")).contentType(APPLICATION_JSON).content("{\"version\":0}")).andExpect(status().isOk());
        mvc.perform(patch("/api/appointments/"+id+"/reschedule").with(as(username,"CUSTOMER")).contentType(APPLICATION_JSON)
            .content(body(Map.of("version",0,"date",date.plusDays(7).toString(),"time",time)))).andExpect(status().isConflict());
        mvc.perform(patch("/api/appointments/"+id+"/reschedule").with(as(username,"CUSTOMER")).contentType(APPLICATION_JSON)
            .content(body(Map.of("version",1,"date",date.plusDays(7).toString(),"time",time)))).andExpect(status().isOk()).andExpect(jsonPath("$.data.status").value("CHO_XAC_NHAN"));
        mvc.perform(patch("/api/appointments/"+id+"/cancel").with(as(otherUsername,"CUSTOMER")).contentType(APPLICATION_JSON).content("{\"version\":2}")).andExpect(status().isNotFound());
        mvc.perform(patch("/api/appointments/"+id+"/cancel").with(as(username,"CUSTOMER")).contentType(APPLICATION_JSON).content("{\"version\":2}")).andExpect(status().isOk());
        mvc.perform(patch("/api/appointments/"+id+"/cancel").with(as(username,"CUSTOMER")).contentType(APPLICATION_JSON).content("{\"version\":2}")).andExpect(status().isOk());
        assertEquals("HUY",jdbc.queryForObject("SELECT TrangThai FROM LichHen WHERE MaLichHen=?",String.class,id));
        assertEquals(4,jdbc.queryForObject("SELECT COUNT(*) FROM LichSuLichHen WHERE MaLichHen=?",Integer.class,id));
        assertEquals(4,jdbc.queryForObject("SELECT COUNT(*) FROM ThongBao WHERE MaLichHen=?",Integer.class,id));
        mvc.perform(get("/api/appointments").with(as(otherUsername,"CUSTOMER"))).andExpect(status().isOk()).andExpect(jsonPath("$.data").isEmpty());
        mvc.perform(get("/api/appointments/"+id+"/history").with(as(username,"CUSTOMER"))).andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(4));
    }
    @Test void concurrentLastSlotAllowsExactlyOneBooking()throws Exception {
        var start=new CountDownLatch(1);
        try(var pool=Executors.newFixedThreadPool(2)) {
            List<Future<Integer>> results=new ArrayList<>();
            for(int i=0;i<2;i++) {
                int index=i;String name=i==0?username:otherUsername;
                results.add(pool.submit(()->{start.await();return mvc.perform(post("/api/appointments").with(as(name,"CUSTOMER"))
                    .contentType(APPLICATION_JSON).content(body(booking(index)))).andReturn().getResponse().getStatus();}));
            }
            start.countDown();
            List<Integer> statuses=List.of(results.get(0).get(20,TimeUnit.SECONDS),results.get(1).get(20,TimeUnit.SECONDS));
            assertTrue(statuses.contains(201),statuses.toString());assertTrue(statuses.contains(409),statuses.toString());
            assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM LichHen WHERE NgayHen=? AND GioHen=? AND MaKhachHang IN (?,?)",
                Integer.class,java.sql.Date.valueOf(date),time,customers.get(0),customers.get(1)));
        }
    }
    @Test void validationAndSchedulePermissions()throws Exception {
        mvc.perform(post("/api/appointments").with(as(username,"CUSTOMER")).contentType(APPLICATION_JSON)
            .content(body(Map.of("vehicleId",vehicles.get(0),"date",date.minusYears(1).toString(),"time",time)))).andExpect(status().isBadRequest());
        mvc.perform(post("/api/appointments").with(as(username,"CUSTOMER")).contentType(APPLICATION_JSON).content("{}")).andExpect(status().isBadRequest());
        mvc.perform(put("/api/appointments/schedule").with(as(username,"CUSTOMER")).contentType(APPLICATION_JSON)
            .content("{\"dayOfWeek\":1,\"time\":\"09:00\",\"capacity\":3}")).andExpect(status().isForbidden());
        mvc.perform(get("/api/appointments")).andExpect(status().isUnauthorized());
    }
}
