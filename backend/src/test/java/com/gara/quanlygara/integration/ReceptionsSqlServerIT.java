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
import org.springframework.test.web.servlet.ResultActions;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.PlatformTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import java.math.BigDecimal;
import java.sql.Date;
import java.time.LocalDate;
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
class ReceptionsSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired PlatformTransactionManager transactions;
    Integer customer,otherCustomer,employee,vehicle,serviceId,appointment,managerAccount,ownerAccount;
    String manager,owner;
    @BeforeEach void prepare() {
        assertTrue(jdbc.queryForObject("SELECT DB_NAME()",String.class).matches("QuanLyGaraOTo_Verify_\\d{8}"));
        String tag=UUID.randomUUID().toString().replace("-","").substring(0,10);
        manager="quanghuy_"+tag;owner="thanhha_"+tag;
        new TransactionTemplate(transactions).executeWithoutResult(tx->{
            customer=insert("KhachHang","MaKhachHang",Map.of("HoTen","Nguyễn Thanh Hà","SoDienThoai",tag+"1"));
            otherCustomer=insert("KhachHang","MaKhachHang",Map.of("HoTen","Trần Minh Đức","SoDienThoai",tag+"2"));
            employee=insert("NhanVien","MaNhanVien",Map.of("HoTen","Trần Quang Huy","ChucVu","Quản lý"));
            managerAccount=insert("TaiKhoan","MaTaiKhoan",Map.of("TenDangNhap",manager,"MatKhauHash","unused-it-password","VaiTro","MANAGER","MaNhanVien",employee));
            ownerAccount=insert("TaiKhoan","MaTaiKhoan",Map.of("TenDangNhap",owner,"MatKhauHash","unused-it-password","VaiTro","CUSTOMER","MaKhachHang",customer));
            vehicle=insert("Xe","MaXe",Map.of("MaKhachHang",customer,"BienSo","51A-"+tag,"HangXe","Toyota","DongXe","Vios","SoKm",20000));
            serviceId=insert("DichVu","MaDichVu",Map.of("TenDichVu","Kiểm tra phanh","LoaiDichVu","KIEM_TRA","DonGia",new BigDecimal("100000")));
            appointment=insert("LichHen","MaLichHen",Map.of("MaKhachHang",customer,"MaXe",vehicle,"MaDichVu",serviceId,
                "NgayHen",Date.valueOf(LocalDate.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"))),"GioHen","09:30","TrangThai","DA_XAC_NHAN"));
        });
    }
    int insert(String table,String key,Map<String,Object> values) {
        return new SimpleJdbcInsert(jdbc).withTableName(table).usingGeneratedKeyColumns(key)
            .usingColumns(values.keySet().toArray(String[]::new)).executeAndReturnKey(values).intValue();
    }
    ResultActions call(MockHttpServletRequestBuilder request,String name,String role,Object body)throws Exception {
        request.with(user(name).roles(role));if(body!=null)request.contentType(APPLICATION_JSON).content(json.writeValueAsString(body));
        return mvc.perform(request).andDo(result->{if(result.getResponse().getStatus()>=500)throw new AssertionError("Reception endpoint failed",result.getResolvedException());});
    }
    Map<String,Object> input(boolean booked) {
        var result=new HashMap<String,Object>(Map.of("customerId",customer,"vehicleId",vehicle,"mileage",20100,
            "initialCondition","Phanh có tiếng kêu; kính và đèn nguyên vẹn","customerRequest","Kiểm tra hệ thống phanh","notes","Khách gửi chìa khóa"));
        if(booked)result.put("appointmentId",appointment);return result;
    }
    Map<String,Object> update(int version,int mileage) {return Map.of("version",version,"mileage",mileage,"initialCondition","Đã kiểm tra ngoại thất","customerRequest","Kiểm tra hệ thống phanh","notes","Ghi nhận cùng khách");}
    JsonNode data(ResultActions result)throws Exception {return json.readTree(result.andReturn().getResponse().getContentAsString()).path("data");}
    int count(String sql,Object...args){return jdbc.queryForObject(sql,Integer.class,args);}
    @AfterEach void cleanup(){
        if(vehicle==null)return;
        new TransactionTemplate(transactions).executeWithoutResult(tx->{
            String orders="SELECT p.MaPhieuSuaChua FROM PhieuSuaChua p JOIN PhieuTiepNhan t ON t.MaTiepNhan=p.MaTiepNhan WHERE t.MaXe=?";
            jdbc.update("DELETE FROM NhatKySuaChua WHERE MaPhieuSuaChua IN ("+orders+")",vehicle);
            jdbc.update("DELETE FROM ChiTietDichVu WHERE MaPhieuSuaChua IN ("+orders+")",vehicle);
            jdbc.update("DELETE FROM ThongBao WHERE MaKhachHang=?",customer);
            jdbc.update("DELETE FROM PhieuSuaChua WHERE MaTiepNhan IN(SELECT MaTiepNhan FROM PhieuTiepNhan WHERE MaXe=?)",vehicle);
            jdbc.update("DELETE FROM PhieuTiepNhan WHERE MaXe=?",vehicle);
            jdbc.update("DELETE FROM LichSuLichHen WHERE MaLichHen=?",appointment);
            jdbc.update("DELETE FROM LichHen WHERE MaLichHen=?",appointment);
            jdbc.update("DELETE FROM Xe WHERE MaXe=?",vehicle);
            jdbc.update("DELETE FROM DichVu WHERE MaDichVu=?",serviceId);
            jdbc.update("DELETE FROM TaiKhoan WHERE MaTaiKhoan IN (?,?)",managerAccount,ownerAccount);
            jdbc.update("DELETE FROM NhanVien WHERE MaNhanVien=?",employee);
            jdbc.update("DELETE FROM KhachHang WHERE MaKhachHang IN (?,?)",customer,otherCustomer);
        });
    }
    @Test void walkInPersistsReloadsUpdatesAndCreatesRepair()throws Exception {
        int id=data(call(post("/api/receptions"),manager,"MANAGER",input(false)).andExpect(status().isCreated())).path("id").asInt();
        var read=data(call(get("/api/receptions/"+id),manager,"MANAGER",null).andExpect(status().isOk()));
        assertEquals(20100,read.path("mileage").asInt());assertEquals(0,read.path("version").asInt());
        assertEquals(employee.intValue(),read.path("receivedBy").asInt());assertTrue(read.path("appointmentId").isNull());
        assertEquals(20100,count("SELECT SoKm FROM Xe WHERE MaXe=?",vehicle));
        call(put("/api/receptions/"+id),manager,"MANAGER",update(0,20200)).andExpect(status().isOk());
        assertEquals(20200,count("SELECT SoKmTiepNhan FROM PhieuTiepNhan WHERE MaTiepNhan=?",id));
        call(put("/api/receptions/"+id),manager,"MANAGER",update(0,20300)).andExpect(status().isConflict());
        var repair=Map.of("receptionId",id,"services",List.of(Map.of("serviceId",serviceId,"quantity",1)));
        int repairId=data(call(post("/api/repair-orders"),manager,"MANAGER",repair).andExpect(status().isCreated())).path("order").path("id").asInt();
        assertTrue(repairId>0);
        assertEquals(repairId,data(call(get("/api/receptions/"+id),manager,"MANAGER",null).andExpect(status().isOk())).path("repairOrderId").asInt());
        call(put("/api/receptions/"+id),manager,"MANAGER",update(1,20300)).andExpect(status().isConflict());
        call(post("/api/repair-orders"),manager,"MANAGER",repair).andExpect(status().isConflict());
        call(post("/api/receptions"),manager,"MANAGER",input(false)).andExpect(status().isConflict());
        assertEquals(20200,count("SELECT SoKm FROM Xe WHERE MaXe=?",vehicle));
    }
    @Test void bookedReceptionLinksOnceAndFreezesAppointmentChanges()throws Exception {
        int id=data(call(post("/api/receptions"),manager,"MANAGER",input(true)).andExpect(status().isCreated())).path("id").asInt();
        assertEquals(appointment.intValue(),count("SELECT MaLichHen FROM PhieuTiepNhan WHERE MaTiepNhan=?",id));
        assertEquals("DA_DEN",jdbc.queryForObject("SELECT TrangThai FROM LichHen WHERE MaLichHen=?",String.class,appointment));
        assertEquals(1,count("SELECT PhienBan FROM LichHen WHERE MaLichHen=?",appointment));
        assertEquals(1,count("SELECT COUNT(*) FROM LichSuLichHen WHERE MaLichHen=?",appointment));
        call(patch("/api/appointments/"+appointment+"/cancel"),owner,"CUSTOMER",Map.of("version",1)).andExpect(status().isConflict());
        call(post("/api/receptions"),manager,"MANAGER",input(true)).andExpect(status().isConflict());
        call(get("/api/receptions/"+id),owner,"CUSTOMER",null).andExpect(status().isForbidden());
        assertEquals(1,count("SELECT COUNT(*) FROM PhieuTiepNhan WHERE MaXe=?",vehicle));
    }
    @Test void rejectsWrongOwnerMileageUnconfirmedFutureAndUnauthorizedWithoutWriting()throws Exception {
        var wrong=input(false);wrong.put("customerId",otherCustomer);
        call(post("/api/receptions"),manager,"MANAGER",wrong).andExpect(status().isBadRequest());
        var low=input(false);low.put("mileage",19000);
        call(post("/api/receptions"),manager,"MANAGER",low).andExpect(status().isBadRequest());
        call(post("/api/receptions"),owner,"CUSTOMER",input(false)).andExpect(status().isForbidden());
        jdbc.update("UPDATE LichHen SET TrangThai=N'CHO_XAC_NHAN' WHERE MaLichHen=?",appointment);
        call(post("/api/receptions"),manager,"MANAGER",input(true)).andExpect(status().isConflict());
        jdbc.update("UPDATE LichHen SET TrangThai=N'DA_XAC_NHAN',NgayHen=DATEADD(day,1,CONVERT(date,SYSDATETIME())) WHERE MaLichHen=?",appointment);
        call(post("/api/receptions"),manager,"MANAGER",input(true)).andExpect(status().isBadRequest());
        assertEquals(0,count("SELECT COUNT(*) FROM PhieuTiepNhan WHERE MaXe=?",vehicle));
        assertEquals(20000,count("SELECT SoKm FROM Xe WHERE MaXe=?",vehicle));
    }
    @Test void concurrentReceptionRequestsCreateExactlyOneRecord()throws Exception {
        var gate=new CountDownLatch(1);var pool=Executors.newFixedThreadPool(2);
        try{
            Callable<Integer> action=()->{gate.await();return call(post("/api/receptions"),manager,"MANAGER",input(true)).andReturn().getResponse().getStatus();};
            var first=pool.submit(action);var second=pool.submit(action);gate.countDown();
            var statuses=new ArrayList<>(List.of(first.get(20,TimeUnit.SECONDS),second.get(20,TimeUnit.SECONDS)));Collections.sort(statuses);
            assertEquals(List.of(201,409),statuses);
            assertEquals(1,count("SELECT COUNT(*) FROM PhieuTiepNhan WHERE MaXe=?",vehicle));
            assertEquals(1,count("SELECT COUNT(*) FROM LichSuLichHen WHERE MaLichHen=?",appointment));
        }finally{pool.shutdownNow();}
    }
}
