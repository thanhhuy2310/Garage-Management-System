package com.gara.quanlygara.integration;

import com.fasterxml.jackson.databind.*;
import org.junit.jupiter.api.*;
import org.junit.jupiter.api.condition.EnabledIfEnvironmentVariable;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.*;
import static org.junit.jupiter.api.Assertions.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;

@SpringBootTest(properties="spring.jpa.show-sql=false")
@AutoConfigureMockMvc
@EnabledIfEnvironmentVariable(named="RUN_SQLSERVER_IT",matches="true")
@Transactional
class CustomerFinanceSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired JdbcTemplate db;
    @Autowired ObjectMapper json;
    int customer,vehicle,repair,maintenance;
    String owner;
    int insert(String table,String key,Map<String,Object> values) {
        return new SimpleJdbcInsert(db).withTableName(table).usingGeneratedKeyColumns(key)
            .usingColumns(values.keySet().toArray(String[]::new)).executeAndReturnKey(values).intValue();
    }
    @BeforeEach void fixture() {
        assertTrue(db.queryForObject("SELECT DB_NAME()",String.class).startsWith("QuanLyGaraOTo_Verify_"));
        String tag=UUID.randomUUID().toString().substring(0,8);owner="ngoclan_"+tag;
        customer=insert("KhachHang","MaKhachHang",Map.of("HoTen","Nguyễn Ngọc Lan","SoDienThoai",tag));
        insert("TaiKhoan","MaTaiKhoan",Map.of("TenDangNhap",owner,"MatKhauHash","unused","VaiTro","CUSTOMER","MaKhachHang",customer));
        vehicle=insert("Xe","MaXe",Map.of("MaKhachHang",customer,"BienSo","51B-"+tag));
        repair=insert("DichVu","MaDichVu",Map.of("TenDichVu","Sửa phanh","LoaiDichVu","SUA_CHUA","DonGia",100000));
        maintenance=insert("DichVu","MaDichVu",Map.of("TenDichVu","Bảo dưỡng định kỳ","LoaiDichVu","BAO_DUONG","DonGia",50000));
    }
    int visit(int month,String status,boolean invoice) {
        var date=Timestamp.valueOf(LocalDateTime.of(2026,month,3,10,0));
        int reception=insert("PhieuTiepNhan","MaTiepNhan",Map.of("MaXe",vehicle,"MaKhachHangTiepNhan",customer,"NgayTiepNhan",date));
        int order=insert("PhieuSuaChua","MaPhieuSuaChua",Map.of("MaTiepNhan",reception,"NgayLap",date,"NgayHoanThanh",date,"TrangThai",status));
        db.update("INSERT INTO ChiTietDichVu(MaPhieuSuaChua,MaDichVu,SoLuong,DonGia,TrangThai) VALUES(?,?,2,100000,'HOAN_TAT'),(?,?,1,50000,'HOAN_TAT')",order,repair,order,maintenance);
        if(invoice) return insert("HoaDon","MaHoaDon",Map.of("MaPhieuSuaChua",order,"NgayLap",date,"TongTien",250000,"TrangThai","CHUA_THANH_TOAN"));
        return 0;
    }
    JsonNode read(String path,int status)throws Exception {
        var res=mvc.perform(get("/api/customers/me"+path).with(user(owner).roles("CUSTOMER"))).andReturn().getResponse();
        assertEquals(status,res.getStatus(),res.getContentAsString());
        return json.readTree(res.getContentAsByteArray()).path("data");
    }
    @Test void countsEachCompletedVisitOnceAndUsesRecordedPayments()throws Exception {
        int invoice=visit(1,"HOAN_TAT",true);visit(1,"HOAN_TAT",true);visit(2,"HOAN_TAT",true);visit(3,"HUY",false);visit(3,"DANG_SUA",false);
        db.update("INSERT INTO ThanhToan(MaHoaDon,NgayThanhToan,SoTien,PhuongThuc) VALUES(?,GETDATE(),100000,'TIEN_MAT')",invoice);
        var stats=read("/statistics",200);
        assertEquals(3,stats.path("completedVisits").asInt());
        assertEquals(3,stats.path("repairVisits").asInt());
        assertEquals(3,stats.path("maintenanceVisits").asInt());
        assertEquals(750000,stats.path("totalCost").asInt());
        assertEquals(750000,stats.path("customerCost").asInt());
        assertEquals(2,stats.path("months").size());
        assertEquals(500000,stats.at("/months/0/totalCost").asInt());
        assertEquals(3,read("/invoices",200).size());
        var detail=read("/invoices/"+invoice,200);
        assertEquals(100000,detail.path("customerPaid").asInt());
        assertEquals(150000,detail.path("remaining").asInt());
        assertEquals("THANH_TOAN_MOT_PHAN",detail.path("status").asText());
        assertEquals(2,detail.path("lines").size());
        assertEquals("TIEN_MAT",detail.at("/payments/0/method").asText());
        assertEquals(0,read("/statistics?year=2025",200).path("completedVisits").asInt());
        assertEquals(3,read("/statistics?year=2026&vehicleId="+vehicle,200).path("completedVisits").asInt());
        read("/statistics?year=1",400);
        assertEquals(403,mvc.perform(get("/api/customers/me/invoices").with(user(owner).roles("TECHNICIAN"))).andReturn().getResponse().getStatus());
    }
    @Test void emptyHistoryAndUninvoicedCostRemainExplicit()throws Exception {
        assertEquals(0,read("/invoices",200).size());
        assertEquals(0,read("/statistics",200).path("completedVisits").asInt());
        visit(4,"HOAN_TAT",false);
        var stats=read("/statistics",200);
        assertEquals(1,stats.path("completedVisits").asInt());
        assertEquals(250000,stats.path("totalCost").asInt());
        assertEquals(0,stats.path("customerCost").asInt());
        assertEquals(1,stats.path("awaitingInvoicesOrInsurance").asInt());
    }

    @Test void changingVehicleOwnerPreservesOriginalCustomersInvoicePrivacy()throws Exception {
        int invoice = visit(5, "HOAN_TAT", true);
        int buyer = insert("KhachHang", "MaKhachHang", Map.of("HoTen","Trần Minh Tú","SoDienThoai",owner));
        String buyerLogin = owner + "_tu";
        insert("TaiKhoan","MaTaiKhoan",Map.of("TenDangNhap",buyerLogin,"MatKhauHash","unused","VaiTro","CUSTOMER","MaKhachHang",buyer));
        db.update("UPDATE Xe SET MaKhachHang=? WHERE MaXe=?",buyer,vehicle);
        assertEquals(invoice,read("/invoices/"+invoice,200).path("id").intValue());
        var original = read("/statistics?vehicleId="+vehicle,200);
        assertEquals(1,original.path("completedVisits").intValue());
        assertEquals(0,original.path("vehicleCount").intValue());
        assertFalse(original.at("/vehicles/0/vehicle/currentlyOwned").booleanValue());
        owner = buyerLogin;
        read("/invoices/"+invoice,404);
        assertEquals(0,read("/invoices?vehicleId="+vehicle,200).size());
        assertEquals(0,read("/statistics?vehicleId="+vehicle,200).path("completedVisits").intValue());
    }
}
