package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;
import org.springframework.mock.web.MockMultipartFile;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.request.MockHttpServletRequestBuilder;
import org.springframework.transaction.annotation.Transactional;
import java.time.*;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.http.MediaType.APPLICATION_JSON;

@SpringBootTest(properties="spring.jpa.show-sql=false")
@AutoConfigureMockMvc
@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
@Transactional
class InsuranceWorkflowSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate db;
    @Autowired ObjectMapper json;
    String manager,owner,path;
    int customer,vehicle,employee,policy,claim,reception;
    LocalDate day=LocalDate.now();
    int insert(String table,String key,Map<String,Object> values) {
        return new SimpleJdbcInsert(db).withTableName(table).usingGeneratedKeyColumns(key)
            .usingColumns(values.keySet().toArray(String[]::new)).executeAndReturnKey(values).intValue();
    }
    JsonNode call(MockHttpServletRequestBuilder req,Object body,int expected)throws Exception {
        req.with(user(manager).roles("MANAGER"));
        if(body!=null)req.contentType(APPLICATION_JSON).content(json.writeValueAsBytes(body));
        var result=mvc.perform(req).andReturn();
        var data=json.readTree(result.getResponse().getContentAsByteArray());
        assertEquals(expected,result.getResponse().getStatus(),result.getRequest().getRequestURI()+" "+data.path("message"));
        return data.path("data");
    }
    @BeforeEach void openClaim()throws Exception {
        assertTrue(db.queryForObject("SELECT DB_NAME()",String.class).startsWith("QuanLyGaraOTo_Verify_"));
        String tag=UUID.randomUUID().toString().substring(0,8);
        manager="quanghuy_"+tag;owner="minhhanh_"+tag;
        employee=insert("NhanVien","MaNhanVien",Map.of("HoTen","Trần Quang Huy","ChucVu","Quản lý"));
        customer=insert("KhachHang","MaKhachHang",Map.of("HoTen","Nguyễn Minh Hạnh","SoDienThoai",tag));
        insert("TaiKhoan","MaTaiKhoan",Map.of("TenDangNhap",manager,"MatKhauHash","unused","VaiTro","MANAGER","MaNhanVien",employee));
        insert("TaiKhoan","MaTaiKhoan",Map.of("TenDangNhap",owner,"MatKhauHash","unused","VaiTro","CUSTOMER","MaKhachHang",customer));
        vehicle=insert("Xe","MaXe",Map.of("MaKhachHang",customer,"BienSo","51A-"+tag));
        reception=insert("PhieuTiepNhan","MaTiepNhan",Map.of("MaXe",vehicle,"NgayTiepNhan",java.sql.Timestamp.valueOf(day.atStartOfDay())));
        int company=insert("CongTyBaoHiem","MaCongTyBaoHiem",Map.of("MaCongTy",tag,"TenCongTy","An Phát"));
        policy=call(post("/api/insurance/policies"),Map.of("companyId",company,"vehicleId",vehicle,"policyholderCustomerId",customer,
            "policyNumber",tag,"insuranceType","VAT_CHAT_XE","startDate",day.minusDays(30),"endDate",day.plusDays(30),
            "registeredOwnerName","Nguyễn Minh Hạnh","certificateOwnerName","Nguyễn Minh Hạnh"),201).path("id").asInt();
        claim=call(post("/api/insurance/claims"),Map.of("policyId",policy,"receptionId",reception,"incidentAt",day.minusDays(1).atTime(10,0),
                "incidentLocation","Quận 1","causeDescription","Va chạm","damageDescription","Móp cửa"),201).path("id").asInt();
        path="/api/insurance/claims/"+claim;
    }
    int version()throws Exception {return call(get(path+"/casework"),null,200).path("version").asInt();}
    int upload(String category)throws Exception {
        var file=new MockMultipartFile("file","bien-ban.pdf","application/pdf","%PDF-1.7\n%%EOF".getBytes());
        call(multipart(path+"/documents").file(file).param("version",String.valueOf(version())).param("category",category),null,200);
        return call(get(path+"/casework"),null,200).path("documents").get(0).path("id").asInt();
    }
    void follow(String status)throws Exception {
        call(put(path+"/follow-up"),Map.of("version",version(),"status",status,"assessor","Lê Minh","note","Đối chiếu hồ sơ"),200);
    }
    int inspect()throws Exception {
        follow("DA_THONG_BAO");follow("CHO_GIAM_DINH");int doc=upload("GIAM_DINH");
        call(post(path+"/assessments"),Map.of("version",version(),"documentId",doc,"damage","Cửa trước","finding","Cần sửa"),200);
        return doc;
    }
    @Test void privateDocumentsAndPriorInspectionRevisionsArePreserved()throws Exception {
        int doc=inspect();
        var first=call(get(path+"/casework"),null,200).path("assessments").get(0);
        var changed=Map.of("version",version(),"documentId",doc,"item",first.path("item").asText(),"damage","Cửa trước","finding","Bổ sung nẹp cửa");
        call(post(path+"/assessments"),changed,200);
        call(post(path+"/assessments"),changed,409);
        var result=call(get(path+"/casework"),null,200);
        assertEquals(2,result.path("assessments").size());
        assertEquals("Cần sửa",result.path("assessments").get(1).path("finding").asText());
        assertEquals(403,mvc.perform(get(path+"/documents/"+doc).with(user(owner).roles("CUSTOMER"))).andReturn().getResponse().getStatus());
        var file=mvc.perform(get(path+"/documents/"+doc).with(user(manager).roles("MANAGER"))).andReturn().getResponse();
        assertEquals(200,file.getStatus());assertEquals("%PDF-1.7\n%%EOF",file.getContentAsString());
        assertTrue(file.getHeader("Content-Disposition").startsWith("attachment"));
    }
}
