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
    @org.junit.jupiter.params.ParameterizedTest
    @org.junit.jupiter.params.provider.ValueSource(booleans={true,false})
    void actualInvoiceSeparatesCustomerAndInsurerUntilBothHavePaid(boolean direct)throws Exception {
        if(direct) inspect();
        int service=insert("DichVu","MaDichVu",Map.of("TenDichVu","Sửa cửa","DonGia",200000));
        var repair=call(post("/api/repair-orders"),Map.of("receptionId",reception,"services",List.of(Map.of("serviceId",service,"quantity",1))),201);
        int order=repair.path("order").path("id").asInt();
        var quote=call(post("/api/quotations"),Map.of("repairOrderId",order,
                "lines",List.of(Map.of("kind","SERVICE","itemId",service,"quantity",1))),201);
        int quoteId=quote.path("id").asInt(),line=quote.path("lines").get(0).path("id").asInt();
        var sent=call(post("/api/quotations/"+quoteId+"/send"),Map.of("version",0),200);
        var decision=mvc.perform(post("/api/quotations/"+quoteId+"/decision").with(user(owner).roles("CUSTOMER"))
            .contentType(APPLICATION_JSON).content(json.writeValueAsBytes(Map.of("version",sent.path("version").asInt(),"accepted",true)))).andReturn();
        assertEquals(200,decision.getResponse().getStatus());
        String finance=path+"/finance";
        var progress=Map.of("expectedStatus","MOI_TAO","status","DANG_SUA","notes","Bắt đầu");
        call(put("/api/repair-orders/"+order+"/progress"),progress,409);
        int proposal;
        if(direct){
        call(post(finance+"/proposals"),Map.of("version",version(),"quoteId",quoteId,"revision",1,"direct",direct,
                "lines",List.of(Map.of("lineId",line,"amount",180000))),200);
        proposal=call(get(finance),null,200).path("proposals").get(0).path("id").asInt();
        int evidence=upload("QUYET_DINH");
        var approval=Map.of("version",version(),"proposalId",proposal,"documentId",evidence,"reference","QD-01","reason","Trừ phần khách tự chịu",
                "lines",List.of(Map.of("lineId",line,"amount",150000)));
        call(post(finance+"/decisions"),approval,409);
        call(post("/api/insurance/policies/"+policy+"/verification"),Map.of("status","DA_XAC_MINH","note","Đã đối chiếu giấy chứng nhận"),200);
        call(post(finance+"/decisions"),approval,200);
        } else {
            int evidence=upload("QUYET_DINH");
            var allocation=Map.of("version",version(),"quoteId",quoteId,"revision",1,"direct",false,"lines",List.of(Map.of("lineId",line,"amount",150000)));
            var manual=Map.of("allocation",allocation,"documentId",evidence,"reference","QD-02","reason","Đã đối chiếu quyết định chi trả");
            call(post(finance+"/manual-decision"),manual,409);
            call(post("/api/insurance/policies/"+policy+"/verification"),Map.of("status","DA_XAC_MINH","note","Đã đối chiếu chủ xe"),200);
            call(post(finance+"/manual-decision"),manual,200);
            call(post(finance+"/manual-decision"),manual,409);
            proposal=call(get(finance),null,200).path("proposals").get(0).path("id").asInt();
        }
        db.update("INSERT INTO KyThuatVien(MaNhanVien) VALUES(?)",employee);
        call(post("/api/repair-orders/"+order+"/technicians"),Map.of("technicianId",employee),201);
        call(put("/api/repair-orders/"+order+"/progress"),progress,200);
        String servicePath="/api/repair-orders/"+order+"/services/"+service+"/progress";
        call(put(servicePath),Map.of("expectedStatus","CHO_SUA","status","DANG_SUA","notes","Sửa cửa"),200);
        call(put(servicePath),Map.of("expectedStatus","DANG_SUA","status","HOAN_TAT","notes","Đã kiểm tra"),200);
        call(put("/api/repair-orders/"+order+"/progress"),Map.of("expectedStatus","DANG_SUA","status","HOAN_TAT","notes","Nghiệm thu"),200);
        int invoice=call(post("/api/invoices"),Map.of("repairOrderId",order),201).path("invoice").path("id").asInt();
        String payments="/api/invoices/"+invoice+"/payments";
        int insurer=direct?150000:0,customerShare=200000-insurer;
        var customerPayment=Map.of("amount",customerShare,"method","TIEN_MAT","requestId",UUID.randomUUID().toString());
        call(post(payments),customerPayment,409);
        call(post(finance+"/settlements"),Map.of("version",version(),"invoiceId",invoice,"proposalId",proposal,
                "lines",List.of(Map.of("lineId",line,"amount",insurer))),200);
        call(post(payments),Map.of("amount",customerShare+1,"method","TIEN_MAT","requestId",UUID.randomUUID().toString()),409);
        call(post(payments),customerPayment,200);
        if(direct) {
            call(post(finance+"/close").param("version",""+version()),null,409);
            int bankDoc=upload("CHUYEN_TIEN");
            var receipt=Map.of("amount",insurer,"method","CHUYEN_KHOAN","requestId",UUID.randomUUID().toString(),
                    "payer","INSURER","documentId",bankDoc,"reference","BANK-01");
            call(post(payments),receipt,200);call(post(payments),receipt,200);
        }
        String summary="/api/customers/me/quotations/"+quoteId+"/insurance";
        var response=mvc.perform(get(summary).with(user(owner).roles("CUSTOMER"))).andReturn().getResponse();
        assertEquals(200,response.getStatus());
        var share=json.readTree(response.getContentAsByteArray()).path("data");
        assertEquals(customerShare,share.path("customerAmount").asInt());
        assertEquals(0,share.path("remaining").asInt());
        assertFalse(share.has("documents"));
        int other=insert("KhachHang","MaKhachHang",Map.of("HoTen","Lê Minh","SoDienThoai",owner));
        insert("TaiKhoan","MaTaiKhoan",Map.of("TenDangNhap",owner+"x","MatKhauHash","unused","VaiTro","CUSTOMER","MaKhachHang",other));
        assertEquals(404,mvc.perform(get(summary).with(user(owner+"x").roles("CUSTOMER"))).andReturn().getResponse().getStatus());
        var balance=call(get(finance),null,200).path("balance");
        assertEquals(insurer,balance.path("insurerPaid").asInt());
        assertEquals(customerShare,balance.path("customerPaid").asInt());
        assertEquals(200000,db.queryForObject("SELECT SUM(SoTien) FROM ThanhToan WHERE MaHoaDon=?",Integer.class,invoice));
        call(post(finance+"/close").param("version",""+version()),null,200);
        assertEquals("DA_DONG",call(get(path+"/casework"),null,200).path("status").asText());
    }
}
