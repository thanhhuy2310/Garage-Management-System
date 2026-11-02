package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;
import static org.springframework.http.MediaType.APPLICATION_JSON;

@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
@SpringBootTest(properties={"app.jwt.secret=verification-secret-with-more-than-32-characters","spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
class ContactMessagesSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate jdbc;
    @Autowired ObjectMapper json;
    String requestId;
    @BeforeEach void prepare(){assertTrue(jdbc.queryForObject("SELECT DB_NAME()",String.class).startsWith("QuanLyGaraOTo_Verify_"));requestId=UUID.randomUUID().toString();}
    @AfterEach void cleanup(){jdbc.update("DELETE FROM LienHeKhachHang WHERE MaYeuCau=?",requestId);}
    Map<String,Object> input(){return new HashMap<>(Map.of("requestId",requestId,"fullName","Nguyễn Hoàng Nam","phone","0901234567","plate","51A-12345","message","Cần kiểm tra hệ thống phanh"));}
    @Test void anonymousMessagePersistsOnceAndOnlyStaffCanReadAndMarkIt()throws Exception {
        String content=json.writeValueAsString(input());
        var response=mvc.perform(post("/api/public/contact-messages").contentType(APPLICATION_JSON).content(content))
            .andExpect(status().isCreated()).andReturn().getResponse();
        var receipt=json.readTree(response.getContentAsString()).path("data");int id=receipt.path("id").asInt();
        assertTrue(id>0);assertFalse(receipt.has("phone"));
        assertEquals("Nguyễn Hoàng Nam",jdbc.queryForObject("SELECT HoTen FROM LienHeKhachHang WHERE MaLienHe=?",String.class,id));
        mvc.perform(post("/api/public/contact-messages").contentType(APPLICATION_JSON).content(content))
            .andExpect(status().isCreated()).andExpect(jsonPath("$.data.id").value(id));
        assertEquals(1,jdbc.queryForObject("SELECT COUNT(*) FROM LienHeKhachHang WHERE MaYeuCau=?",Integer.class,requestId));
        mvc.perform(get("/api/contact-messages")).andExpect(status().isUnauthorized());
        for(String role:List.of("CUSTOMER","TECHNICIAN","WAREHOUSE","ADMIN")){
            mvc.perform(get("/api/contact-messages").with(user("account").roles(role))).andExpect(status().isForbidden());
            mvc.perform(patch("/api/contact-messages/"+id+"/read").with(user("account").roles(role))).andExpect(status().isForbidden());
            mvc.perform(patch("/api/contact-messages/read-all").with(user("account").roles(role))).andExpect(status().isForbidden());
        }
        assertEquals(0,jdbc.queryForObject("SELECT DaDoc FROM LienHeKhachHang WHERE MaLienHe=?",Integer.class,id));
        var messages=json.readTree(mvc.perform(get("/api/contact-messages").with(user("staff").roles("RECEPTIONIST")))
            .andExpect(status().isOk()).andReturn().getResponse().getContentAsString()).path("data").path("items");
        boolean found=false;for(var message:messages)if(message.path("id").asInt()==id){found=true;assertEquals("0901234567",message.path("phone").asText());}
        assertTrue(found);
        for(int i=0;i<2;i++)mvc.perform(patch("/api/contact-messages/"+id+"/read").with(user("manager").roles("MANAGER")))
            .andExpect(status().isOk()).andExpect(jsonPath("$.data.read").value(true));
        assertEquals(1,jdbc.queryForObject("SELECT DaDoc FROM LienHeKhachHang WHERE MaLienHe=?",Integer.class,id));
        var changed=input();changed.put("message","Nội dung khác");
        mvc.perform(post("/api/public/contact-messages").contentType(APPLICATION_JSON).content(json.writeValueAsString(changed))).andExpect(status().isConflict());
        assertEquals("Cần kiểm tra hệ thống phanh",jdbc.queryForObject("SELECT NoiDung FROM LienHeKhachHang WHERE MaLienHe=?",String.class,id));
    }
    @Test void rejectsInvalidInputWithoutSavingAndMissingMessageIs404()throws Exception {
        for(String field:List.of("fullName","phone","message")){
            var invalid=input();invalid.put(field," ");
            mvc.perform(post("/api/public/contact-messages").contentType(APPLICATION_JSON).content(json.writeValueAsString(invalid))).andExpect(status().isBadRequest());
        }
        var invalid=input();invalid.put("requestId","invalid");
        mvc.perform(post("/api/public/contact-messages").contentType(APPLICATION_JSON).content(json.writeValueAsString(invalid))).andExpect(status().isBadRequest());
        assertEquals(0,jdbc.queryForObject("SELECT COUNT(*) FROM LienHeKhachHang WHERE MaYeuCau=?",Integer.class,requestId));
        mvc.perform(patch("/api/contact-messages/2147483647/read").with(user("manager").roles("MANAGER"))).andExpect(status().isNotFound());
    }
}
