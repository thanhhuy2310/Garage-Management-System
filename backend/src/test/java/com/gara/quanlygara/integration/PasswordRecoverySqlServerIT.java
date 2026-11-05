package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.*;
import com.gara.quanlygara.service.ResetMail;
import java.util.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.mockito.ArgumentCaptor;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;

@SpringBootTest(properties="spring.jpa.show-sql=false")
@AutoConfigureMockMvc @Transactional
@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
class PasswordRecoverySqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate db;
    @Autowired ObjectMapper json;
    @MockitoBean ResetMail delivery;
    final String tag=UUID.randomUUID().toString().substring(0,8);
    final String email="recovery-"+tag+"@example.invalid", username="hanh_"+tag;
    final String password=UUID.randomUUID().toString(), replacement=UUID.randomUUID().toString();
    String original;
    @BeforeEach void setup()throws Exception{
        assertTrue(db.queryForObject("SELECT DB_NAME()",String.class).startsWith("QuanLyGaraOTo_Verify_"));
        original=postJson("register",Map.of("username",username,"fullName","Nguyễn Hạnh","phone","09"+String.format("%08d",Integer.toUnsignedLong(tag.hashCode())%100000000),"email",email,"password",password),201).asText();
        original=postJson("login",Map.of("username",username,"password",password),200).path("accessToken").asText();
        when(delivery.configured()).thenReturn(true);
    }
    JsonNode postJson(String path,Object body,int status)throws Exception {
        var result=mvc.perform(post("/api/auth/"+path).contentType("application/json").content(json.writeValueAsBytes(body))).andReturn().getResponse();
        assertEquals(status,result.getStatus(),path);return json.readTree(result.getContentAsByteArray()).path("data");
    }
    String requestCode()throws Exception {
        postJson("recovery/request",Map.of("email",email),202);
        // Drive the after-commit delivery hook in a rollback-only SQL test.
        TransactionSynchronizationManager.getSynchronizations().forEach(s->s.afterCommit());
        var code=ArgumentCaptor.forClass(String.class);
        verify(delivery,timeout(3000)).send(eq(email),code.capture());return code.getValue();
    }
    @Test void consumesCodeAndTicketAndInvalidatesOldCredentials()throws Exception {
        String code=requestCode();
        postJson("recovery/request",Map.of("email",email),429);
        String ticket=postJson("recovery/verify",Map.of("email",email,"code",code),200).asText();
        postJson("recovery/verify",Map.of("email",email,"code",code),400);
        var change=Map.of("email",email,"ticket",ticket,"password",replacement,"confirmation",replacement);
        postJson("recovery/complete",change,200);postJson("recovery/complete",change,400);
        postJson("login",Map.of("username",username,"password",password),401);
        postJson("login",Map.of("username",username,"password",replacement),200);
        assertEquals(401,mvc.perform(get("/api/auth/me").header("Authorization","Bearer "+original)).andReturn().getResponse().getStatus());
    }
    @Test void limitsAttemptsAndRejectsExpiredProof()throws Exception {
        String code=requestCode();String wrong=code.equals("000000")?"111111":"000000";
        for(int i=0;i<5;i++)postJson("recovery/verify",Map.of("email",email,"code",wrong),400);
        postJson("recovery/verify",Map.of("email",email,"code",code),400);
        db.update("UPDATE PasswordRecovery SET Attempts=0,ExpiresAt=0 WHERE AccountId=(SELECT MaTaiKhoan FROM TaiKhoan WHERE TenDangNhap=?)",username);
        postJson("recovery/verify",Map.of("email",email,"code",code),400);
    }
    @Test void legacyCustomerCanLoginAndVerifyANewMailbox() throws Exception {
        db.update("UPDATE KhachHang SET Email=NULL WHERE Email=?",email);
        postJson("login",Map.of("username",username,"password",password),200);
        postJson("register",Map.of("username",username+"x","password",password,"fullName","Trần An","phone","0901234567"),400);
        String address=tag+"@example.invalid";
        var path="/api/auth/contact-email/";
        mvc.perform(post(path+"request").header("Authorization","Bearer "+original).contentType("application/json")
                .content(json.writeValueAsBytes(Map.of("email",address,"password",password)))).andExpect(org.springframework.test.web.servlet.result.MockMvcResultMatchers.status().isAccepted());
        TransactionSynchronizationManager.getSynchronizations().forEach(s->s.afterCommit());
        var code=ArgumentCaptor.forClass(String.class); verify(delivery,timeout(3000)).send(eq(address),code.capture());
        var confirmation=Map.of("email",address,"code",code.getValue());
        for(int expected:new int[]{200,400}){
            assertEquals(expected,mvc.perform(post(path+"verify").header("Authorization","Bearer "+original).contentType("application/json")
                    .content(json.writeValueAsBytes(confirmation))).andReturn().getResponse().getStatus());
        }
        assertEquals(1,db.queryForObject("SELECT COUNT(*) FROM KhachHang WHERE Email=?",Integer.class,address));
    }
    @Test void missingMailConfigurationIsExplicitForAnyAddress()throws Exception {
        when(delivery.configured()).thenReturn(false);
        postJson("recovery/request",Map.of("email",email),503);
        postJson("recovery/request",Map.of("email","absent@example.invalid"),503);
        when(delivery.configured()).thenReturn(true);
        postJson("recovery/request",Map.of("email","absent@example.invalid"),202);
    }
}
