package com.gara.quanlygara.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.repository.AccountRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;
import java.util.Map;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/** Explicit development-database test. Every inserted row, including trigger effects, rolls back. */
@SpringBootTest(properties = {"spring.jpa.hibernate.ddl-auto=none", "spring.jpa.show-sql=false"})
@AutoConfigureMockMvc
@Transactional
class RepairBillingSqlServerIT {
    @Autowired MockMvc mvc;
    @Autowired ObjectMapper json;
    @Autowired JdbcTemplate jdbc;
    @Autowired AccountRepository accounts;

    @Test
    void repairToInvoiceToPaymentAndCustomerTrackingUseActualSqlSchema() throws Exception {
        String unique = UUID.randomUUID().toString();
        int customer = id("INSERT INTO KhachHang (HoTen,SoDienThoai) OUTPUT INSERTED.MaKhachHang VALUES (?,?)",
                "Test rollback " + unique, unique.substring(0, 20));
        int vehicle = id("INSERT INTO Xe (MaKhachHang,BienSo) OUTPUT INSERTED.MaXe VALUES (?,?)", customer, unique.substring(0, 20));
        int reception = id("INSERT INTO PhieuTiepNhan (MaXe,NgayTiepNhan) OUTPUT INSERTED.MaTiepNhan VALUES (?,SYSDATETIME())", vehicle);
        int service = id("INSERT INTO DichVu (TenDichVu,DonGia) OUTPUT INSERTED.MaDichVu VALUES (?,125000.50)", "Test rollback " + unique);
        int tech = id("INSERT INTO NhanVien (HoTen,ChucVu) OUTPUT INSERTED.MaNhanVien VALUES (?,N'Kỹ thuật viên')", "Test rollback " + unique);
        jdbc.update("INSERT INTO KyThuatVien (MaNhanVien) VALUES (?)", tech);
        Account customerAccount = new Account();
        customerAccount.setUsername("sql-customer-" + unique);
        customerAccount.setPasswordHash("not-used"); customerAccount.setRole(AccountRole.CUSTOMER);
        customerAccount.setCustomerId(customer); accounts.saveAndFlush(customerAccount);
        var created = mvc.perform(post("/api/repair-orders").with(user("manager").roles("MANAGER"))
                .contentType(APPLICATION_JSON).content(json.writeValueAsString(Map.of("receptionId", reception,
                        "services", new Object[]{Map.of("serviceId", service, "quantity", 2)}))))
                .andExpect(status().isCreated()).andReturn();
        int order = json.readTree(created.getResponse().getContentAsString()).path("data").path("order").path("id").asInt();
        mvc.perform(post("/api/repair-orders/{id}/technicians", order).with(user("manager").roles("MANAGER"))
                .contentType(APPLICATION_JSON).content(json.writeValueAsString(Map.of("technicianId", tech))))
                .andExpect(status().isCreated());
        String orderUrl = "/api/repair-orders/" + order + "/progress";
        String serviceUrl = "/api/repair-orders/" + order + "/services/" + service + "/progress";
        change(orderUrl, "MOI_TAO", "DANG_SUA");
        change(serviceUrl, "CHO_SUA", "DANG_SUA"); change(serviceUrl, "DANG_SUA", "HOAN_TAT");
        change(orderUrl, "DANG_SUA", "HOAN_TAT");
        mvc.perform(get("/api/customer/repairs").with(user(customerAccount.getUsername()).roles("CUSTOMER")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].order.vehicleId").value(vehicle))
                .andExpect(jsonPath("$.data[0].order.customerId").value(customer))
                .andExpect(jsonPath("$.data[0].progress.length()").value(5));
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM ThongBao WHERE MaPhieuSuaChua = ? AND LoaiThongBao=N'HOAN_TAT_SUA_CHUA'", Integer.class, order));
        var invoiceResult = mvc.perform(post("/api/invoices").with(user("reception").roles("RECEPTIONIST"))
                .contentType(APPLICATION_JSON).content(json.writeValueAsString(Map.of("repairOrderId", order))))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.data.invoice.total").value(250001)).andReturn();
        int invoice = json.readTree(invoiceResult.getResponse().getContentAsString()).path("data").path("invoice").path("id").asInt();
        String payment = json.writeValueAsString(Map.of("amount", 250001, "method", "TIEN_MAT", "requestId", UUID.randomUUID().toString()));
        for (int attempt = 0; attempt < 2; attempt++) {
            mvc.perform(post("/api/invoices/{id}/payments", invoice).with(user("reception").roles("RECEPTIONIST"))
                    .contentType(APPLICATION_JSON).content(payment)).andExpect(status().isOk())
                    .andExpect(jsonPath("$.data.invoice.remaining").value(0))
                    .andExpect(jsonPath("$.data.payments.length()").value(1));
        }
        assertEquals(1, jdbc.queryForObject("SELECT COUNT(*) FROM ThanhToan WHERE MaHoaDon=?", Integer.class, invoice));
    }

    private int id(String sql, Object... args) { return jdbc.queryForObject(sql, Integer.class, args); }
    private void change(String path, String from, String to) throws Exception {
        mvc.perform(put(path).with(user("manager").roles("MANAGER")).contentType(APPLICATION_JSON)
                .content(json.writeValueAsString(Map.of("expectedStatus", from, "status", to, "notes", "Kiểm tra hoàn tất."))))
                .andExpect(status().isOk());
    }
}
