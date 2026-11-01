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
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.http.MediaType.APPLICATION_JSON;

@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
@SpringBootTest(properties={"app.jwt.secret=verification-secret-with-more-than-32-characters","spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
class EmployeesSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    final List<Integer> employees = new ArrayList<>();
    Integer customer, vehicle, reception, order;
    String tag;
    @BeforeEach void prepare() {
        assertTrue(jdbc.queryForObject("SELECT DB_NAME()",String.class).matches("QuanLyGaraOTo_Verify_\\d{8}"));
        tag=UUID.randomUUID().toString().replace("-","").substring(0,10);
    }
    ResultActions call(MockHttpServletRequestBuilder request,String role,Object body)throws Exception {
        request.with(user("nhanvien_"+tag).roles(role));
        if(body!=null)request.contentType(APPLICATION_JSON).content(json.writeValueAsString(body));
        return mvc.perform(request);
    }
    JsonNode data(ResultActions result)throws Exception {return json.readTree(result.andReturn().getResponse().getContentAsString()).path("data");}
    Map<String,Object> input(boolean tech) {return Map.of("fullName","Nguyễn Minh Quang","phone","09"+tag.substring(0,8),"email","minhquang@example.com","position",tech?"Kỹ thuật viên":"Cố vấn dịch vụ","technician",tech);}
    int create(boolean tech)throws Exception {
        int id=data(call(post("/api/employees"),"MANAGER",input(tech)).andExpect(status().isCreated())).path("id").asInt();
        employees.add(id);return id;
    }
    int count(String sql,Object...args){return jdbc.queryForObject(sql,Integer.class,args);}
    int insert(String table,String key,Map<String,Object> values) {
        return new SimpleJdbcInsert(jdbc).withTableName(table).usingGeneratedKeyColumns(key)
            .usingColumns(values.keySet().toArray(String[]::new)).executeAndReturnKey(values).intValue();
    }
    @AfterEach void cleanup() {
        if(order!=null){jdbc.update("DELETE FROM PhanCongKyThuatVien WHERE MaPhieuSuaChua=?",order);jdbc.update("DELETE FROM PhieuSuaChua WHERE MaPhieuSuaChua=?",order);}
        if(reception!=null)jdbc.update("DELETE FROM PhieuTiepNhan WHERE MaTiepNhan=?",reception);
        if(vehicle!=null)jdbc.update("DELETE FROM Xe WHERE MaXe=?",vehicle);
        if(customer!=null)jdbc.update("DELETE FROM KhachHang WHERE MaKhachHang=?",customer);
        for(int id:employees){jdbc.update("DELETE FROM TaiKhoan WHERE MaNhanVien=?",id);jdbc.update("DELETE FROM KyThuatVien WHERE MaNhanVien=?",id);jdbc.update("DELETE FROM NhanVien WHERE MaNhanVien=?",id);}
    }
    @Test void persistsEmployeeAndTechnicianChangesAndReadsThemBack()throws Exception {
        int id=create(false);
        assertEquals("Nguyễn Minh Quang",jdbc.queryForObject("SELECT HoTen FROM NhanVien WHERE MaNhanVien=?",String.class,id));
        var saved=data(call(get("/api/employees/"+id),"MANAGER",null).andExpect(status().isOk()));
        assertFalse(saved.path("technician").asBoolean());assertTrue(saved.path("username").isNull());
        var update=new HashMap<String,Object>(input(true));update.put("fullName","Nguyễn Minh Quang Anh");
        call(put("/api/employees/"+id),"MANAGER",update).andExpect(status().isOk());
        assertEquals(1,count("SELECT COUNT(*) FROM KyThuatVien WHERE MaNhanVien=?",id));
        var all=data(call(get("/api/employees"),"MANAGER",null).andExpect(status().isOk()));
        var rows=new ArrayList<JsonNode>();all.forEach(rows::add);
        assertTrue(rows.stream().anyMatch(e->e.path("id").asInt()==id&&e.path("technician").asBoolean()&&e.path("fullName").asText().equals("Nguyễn Minh Quang Anh")));
        call(put("/api/employees/"+id),"MANAGER",input(false)).andExpect(status().isOk());
        assertEquals(0,count("SELECT COUNT(*) FROM KyThuatVien WHERE MaNhanVien=?",id));
    }
    @Test void validatesInputAndKeepsAccountAdministrationRestricted()throws Exception {
        for(String role:List.of("CUSTOMER","TECHNICIAN","RECEPTIONIST","WAREHOUSE")){
            call(get("/api/employees"),role,null).andExpect(status().isForbidden());
            call(post("/api/employees"),role,input(false)).andExpect(status().isForbidden());
        }
        var invalid=new HashMap<String,Object>(input(false));invalid.put("fullName"," ");
        call(post("/api/employees"),"MANAGER",invalid).andExpect(status().isBadRequest());
        int id=create(false);
        invalid=new HashMap<>(input(false));invalid.put("email","not-an-email");
        call(put("/api/employees/"+id),"MANAGER",invalid).andExpect(status().isBadRequest());
        assertEquals("minhquang@example.com",jdbc.queryForObject("SELECT Email FROM NhanVien WHERE MaNhanVien=?",String.class,id));
        call(get("/api/accounts"),"MANAGER",null).andExpect(status().isForbidden());
        call(get("/api/employees/2147483647"),"MANAGER",null).andExpect(status().isNotFound());
    }
    @Test void usesExistingAccountApiAndCannotRemoveTechnicianWithAccount()throws Exception {
        int id=create(true);
        var body=Map.of("username","minhquang_"+tag,"password","AccountVerification!42","role","TECHNICIAN","employeeId",id,"active",true);
        call(post("/api/accounts"),"MANAGER",body).andExpect(status().isForbidden());
        int account=data(call(post("/api/accounts"),"ADMIN",body).andExpect(status().isCreated())).path("id").asInt();
        assertTrue(account>0);
        assertEquals(id,count("SELECT MaNhanVien FROM TaiKhoan WHERE MaTaiKhoan=?",account));
        var saved=data(call(get("/api/employees/"+id),"MANAGER",null).andExpect(status().isOk()));
        assertEquals("TECHNICIAN",saved.path("accountRole").asText());assertTrue(saved.path("accountActive").asBoolean());
        call(put("/api/employees/"+id),"MANAGER",input(false)).andExpect(status().isConflict());
        assertEquals(1,count("SELECT COUNT(*) FROM KyThuatVien WHERE MaNhanVien=?",id));
        call(patch("/api/accounts/"+account+"/status"),"ADMIN",Map.of("active",false)).andExpect(status().isOk());
        var all=data(call(get("/api/employees"),"MANAGER",null).andExpect(status().isOk()));
        var rows=new ArrayList<JsonNode>();all.forEach(rows::add);
        assertTrue(rows.stream().anyMatch(e->e.path("id").asInt()==id&&e.path("accountRole").asText().equals("TECHNICIAN")&&!e.path("accountActive").asBoolean()));
    }
    @Test void allowsInitialInspectionAssignmentButRequiresApprovalToStartRepair()throws Exception {
        int id=create(true);
        customer=insert("KhachHang","MaKhachHang",Map.of("HoTen","Trần Thanh Hà","SoDienThoai",tag));
        vehicle=insert("Xe","MaXe",Map.of("MaKhachHang",customer,"BienSo","51A-"+tag,"HangXe","Toyota","DongXe","Vios"));
        reception=insert("PhieuTiepNhan","MaTiepNhan",Map.of("MaXe",vehicle,"NgayTiepNhan",java.sql.Timestamp.valueOf(java.time.LocalDateTime.now()),"TinhTrangBanDau","Xe có tiếng kêu"));
        order=insert("PhieuSuaChua","MaPhieuSuaChua",Map.of("MaTiepNhan",reception,"NgayLap",java.sql.Timestamp.valueOf(java.time.LocalDateTime.now()),"TrangThai","MOI_TAO"));
        var assignment=Map.of("technicianId",id,"notes","Kiểm tra trước khi lập báo giá");
        call(post("/api/repair-orders/"+order+"/technicians"),"MANAGER",assignment).andExpect(status().isCreated());
        assertEquals(1,count("SELECT COUNT(*) FROM PhanCongKyThuatVien WHERE MaPhieuSuaChua=? AND MaKyThuatVien=?",order,id));
        call(get("/api/repair-orders/"+order+"/technicians"),"MANAGER",null).andExpect(status().isOk()).andExpect(jsonPath("$.data[0].technician.id").value(id));
        call(post("/api/repair-orders/"+order+"/technicians"),"MANAGER",assignment).andExpect(status().isConflict());
        call(put("/api/employees/"+id),"MANAGER",input(false)).andExpect(status().isConflict());
        call(put("/api/repair-orders/"+order+"/progress"),"MANAGER",Map.of("status","DANG_SUA","expectedStatus","MOI_TAO","notes","Bắt đầu sửa chữa")).andExpect(status().isConflict());
        assertEquals("MOI_TAO",jdbc.queryForObject("SELECT TrangThai FROM PhieuSuaChua WHERE MaPhieuSuaChua=?",String.class,order));
    }
}
