package com.gara.quanlygara.controller;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.ValueSource;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.test.context.support.WithMockUser;
import java.util.Map;
import java.util.UUID;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

class RepairBillingWorkflowTest extends ApiTestSupport {
    @Autowired JdbcTemplate jdbc;

    @BeforeEach
    void prepare() {
        jdbc.execute("CREATE TABLE IF NOT EXISTS Xe (MaXe INT PRIMARY KEY, MaKhachHang INT, BienSo VARCHAR(20), HangXe NVARCHAR(100), DongXe NVARCHAR(100))");
        jdbc.execute("CREATE TABLE IF NOT EXISTS PhieuTiepNhan (MaTiepNhan INT PRIMARY KEY, MaXe INT, YeuCauKhachHang NVARCHAR(1000), TinhTrangBanDau NVARCHAR(1000))");
        jdbc.execute("CREATE TABLE IF NOT EXISTS ChiTietDichVu (MaPhieuSuaChua INT, MaDichVu INT, SoLuong INT, DonGia DECIMAL(18,2), TrangThai NVARCHAR(50))");
        jdbc.execute("CREATE TABLE IF NOT EXISTS PhuTung (MaPhuTung INT PRIMARY KEY, TenPhuTung NVARCHAR(150))");
        jdbc.execute("CREATE TABLE IF NOT EXISTS ChiTietPhuTung (MaPhieuSuaChua INT, MaPhuTung INT, SoLuong INT, DonGia DECIMAL(18,2))");
        jdbc.update("INSERT INTO KhachHang (MaKhachHang,HoTen,SoDienThoai,TrangThai) VALUES (9201,'Khach A','0920000001',1),(9202,'Khach B','0920000002',1)");
        jdbc.update("INSERT INTO Xe VALUES (9201,9201,'51A-92001','Toyota','Vios'),(9202,9202,'51A-92002','Honda','City')");
        jdbc.update("INSERT INTO PhieuTiepNhan VALUES (9201,9201,'Kiem tra phanh','Phanh keu'),(9202,9202,NULL,NULL),(9203,9201,NULL,NULL)");
        jdbc.update("INSERT INTO PhieuSuaChua (MaPhieuSuaChua,MaTiepNhan,NgayLap,TrangThai) VALUES (9201,9201,'2026-10-06 08:00:00','MOI_TAO'),(9202,9202,'2026-10-06 08:00:00','HOAN_TAT')");
        jdbc.update("INSERT INTO DichVu (MaDichVu,TenDichVu,DonGia) VALUES (9201,'Phanh',999999),(9202,'Dau',100000)");
        jdbc.update("INSERT INTO ChiTietDichVu VALUES (9201,9201,2,200000,'CHO_SUA'),(9202,9201,1,100000,'HOAN_TAT')");
        jdbc.update("INSERT INTO PhuTung VALUES (9201,'Ma phanh')");
        jdbc.update("INSERT INTO ChiTietPhuTung VALUES (9202,9201,2,50000)");
        jdbc.update("INSERT INTO NhanVien (MaNhanVien,HoTen,ChucVu) VALUES (9201,'Tech A','KTV'),(9202,'Tech B','KTV')");
        jdbc.update("INSERT INTO KyThuatVien VALUES (9201),(9202)");
        jdbc.update("INSERT INTO TaiKhoan (TenDangNhap,MatKhauHash,VaiTro,TrangThai,MaNhanVien) VALUES ('flow-tech','unused','TECHNICIAN',1,9201),('flow-other','unused','TECHNICIAN',1,9202)");
        jdbc.update("INSERT INTO TaiKhoan (TenDangNhap,MatKhauHash,VaiTro,TrangThai,MaKhachHang) VALUES ('flow-customer','unused','CUSTOMER',1,9201),('flow-customer-b','unused','CUSTOMER',1,9202)");
        jdbc.update("INSERT INTO PhanCongKyThuatVien VALUES (9201,9201,'2026-10-06 08:00:00','Kiem tra')");
    }

    @Test @WithMockUser(username = "flow-tech", roles = "TECHNICIAN")
    void assignedTechnicianUpdatesServicesThenCompletesAndCustomerSeesActualHistory() throws Exception {
        change("/api/repair-orders/9201/progress", "MOI_TAO", "DANG_SUA").andExpect(status().isOk());
        change("/api/repair-orders/9201/progress", "DANG_SUA", "HOAN_TAT").andExpect(status().isConflict());
        change("/api/repair-orders/9201/services/9201/progress", "CHO_SUA", "DANG_SUA").andExpect(status().isOk());
        change("/api/repair-orders/9201/services/9201/progress", "DANG_SUA", "HOAN_TAT").andExpect(status().isOk());
        change("/api/repair-orders/9201/progress", "DANG_SUA", "HOAN_TAT")
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.order.completedAt").isString())
                .andExpect(jsonPath("$.data.progress.length()").value(4));
        change("/api/repair-orders/9201/progress", "HOAN_TAT", "DANG_SUA").andExpect(status().isConflict());
        mockMvc.perform(get("/api/customer/repairs").with(user("flow-customer").roles("CUSTOMER"))
                        .param("customerId", "9202"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].order.id").value(9201))
                .andExpect(jsonPath("$.data[0].progress.length()").value(4));
    }

    @Test @WithMockUser(username = "flow-other", roles = "TECHNICIAN")
    void unassignedTechnicianCannotUpdateOtherPeoplesWork() throws Exception {
        change("/api/repair-orders/9201/progress", "MOI_TAO", "DANG_SUA").andExpect(status().isNotFound());
        assertEquals(0, jdbc.queryForObject("SELECT COUNT(*) FROM NhatKySuaChua", Integer.class));
    }

    @Test @WithMockUser(roles = "MANAGER")
    void staleStatusAndInvalidTransitionsAreRejected() throws Exception {
        change("/api/repair-orders/9201/progress", "DANG_SUA", "CHO_PHU_TUNG").andExpect(status().isConflict());
        change("/api/repair-orders/9201/progress", "MOI_TAO", "HOAN_TAT").andExpect(status().isConflict());
        mockMvc.perform(put("/api/repair-orders/9201/progress").contentType(APPLICATION_JSON)
                        .content("{\"status\":\"DANG_SUA\",\"expectedStatus\":\"MOI_TAO\",\"notes\":\"  \"}"))
                .andExpect(status().isBadRequest());
    }

    @Test @WithMockUser(roles = "MANAGER")
    void cannotProgressWithoutTechnicianOrAssignAfterCompletion() throws Exception {
        jdbc.update("DELETE FROM PhanCongKyThuatVien WHERE MaPhieuSuaChua=9201");
        change("/api/repair-orders/9201/progress", "MOI_TAO", "DANG_SUA").andExpect(status().isConflict());
        mockMvc.perform(post("/api/repair-orders/9202/technicians").contentType(APPLICATION_JSON)
                        .content("{\"technicianId\":9201}"))
                .andExpect(status().isConflict());
    }

    @Test @WithMockUser(roles = "RECEPTIONIST")
    void createOrderUsesSqlCatalogPricesAndRejectsDuplicateReception() throws Exception {
        var request = "{\"receptionId\":9203,\"services\":[{\"serviceId\":9202,\"quantity\":2}]}";
        mockMvc.perform(post("/api/repair-orders").contentType(APPLICATION_JSON).content(request))
                .andExpect(status().isCreated()).andExpect(jsonPath("$.data.services[0].unitPrice").value(100000))
                .andExpect(jsonPath("$.data.progress.length()").value(1));
        mockMvc.perform(post("/api/repair-orders").contentType(APPLICATION_JSON).content(request))
                .andExpect(status().isConflict());
        change("/api/repair-orders/9201/progress", "MOI_TAO", "DANG_SUA").andExpect(status().isForbidden());
    }

    @Test @WithMockUser(roles = "MANAGER")
    void invoiceUsesStoredLaborAndPartsPricesNotCurrentCatalogPrice() throws Exception {
        createInvoice().andExpect(status().isCreated()).andExpect(jsonPath("$.data.invoice.total").value(200000))
                .andExpect(jsonPath("$.data.lines.length()").value(2));
        createInvoice().andExpect(status().isConflict());
        mockMvc.perform(post("/api/invoices").contentType(APPLICATION_JSON).content("{\"repairOrderId\":9201}"))
                .andExpect(status().isConflict());
    }

    @Test @WithMockUser(roles = "RECEPTIONIST")
    void partialPaymentsRetryAndOverpaymentAreHandledWithoutDoubleCollection() throws Exception {
        int id = objectMapper.readTree(createInvoice().andReturn().getResponse().getContentAsString())
                .path("data").path("invoice").path("id").asInt();
        String key = UUID.randomUUID().toString();
        pay(id, 50000, key).andExpect(status().isOk()).andExpect(jsonPath("$.data.invoice.remaining").value(150000));
        pay(id, 50000, key).andExpect(status().isOk()).andExpect(jsonPath("$.data.payments.length()").value(1));
        pay(id, 70000, key).andExpect(status().isConflict());
        pay(id, 150001, UUID.randomUUID().toString()).andExpect(status().isConflict());
        pay(id, 150000, UUID.randomUUID().toString()).andExpect(status().isOk())
                .andExpect(jsonPath("$.data.invoice.status").value("DA_THANH_TOAN"))
                .andExpect(jsonPath("$.data.invoice.remaining").value(0));
        pay(id, 1, UUID.randomUUID().toString()).andExpect(status().isConflict());
    }

    @ParameterizedTest @ValueSource(ints = {-1, 0}) @WithMockUser(roles = "MANAGER")
    void invalidPaymentAmountsRejected(int amount) throws Exception {
        pay(1, amount, UUID.randomUUID().toString()).andExpect(status().isBadRequest());
    }

    @ParameterizedTest @ValueSource(strings = {"TECHNICIAN", "CUSTOMER", "WAREHOUSE"})
    void unrelatedRolesCannotCollectMoney(String role) throws Exception {
        mockMvc.perform(post("/api/invoices/1/payments").with(user("test").roles(role))
                        .contentType(APPLICATION_JSON).content(objectMapper.writeValueAsString(Map.of(
                                "amount", 100, "method", "TIEN_MAT", "requestId", UUID.randomUUID().toString()))))
                .andExpect(status().isForbidden());
        mockMvc.perform(get("/api/invoices").with(user("test").roles(role))).andExpect(status().isForbidden());
    }

    @Test @WithMockUser(username = "flow-customer-b", roles = "CUSTOMER")
    void customerOnlySeesOwnVehicleAndCannotUpdateRepair() throws Exception {
        mockMvc.perform(get("/api/customer/repairs").param("customerId", "9201"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].order.id").value(9202));
        change("/api/repair-orders/9201/progress", "MOI_TAO", "DANG_SUA").andExpect(status().isForbidden());
    }

    @Test @WithMockUser(roles = "MANAGER")
    void receivingBanksAreStoredAndInactiveAccountsCannotReceiveNewPayments() throws Exception {
        String request = "{\"name\":\"MB Bank\",\"bin\":\"970422\",\"account\":\"1234567890\",\"accountName\":\"GARA TEST\",\"active\":true}";
        var bankResult = mockMvc.perform(post("/api/bank-accounts").contentType(APPLICATION_JSON).content(request))
                .andExpect(status().isCreated()).andReturn();
        int bankId = objectMapper.readTree(bankResult.getResponse().getContentAsString()).path("data").path("id").asInt();
        mockMvc.perform(get("/api/bank-accounts").with(user("reception").roles("RECEPTIONIST")))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data[0].account").value("1234567890"));
        mockMvc.perform(post("/api/bank-accounts").with(user("reception").roles("RECEPTIONIST"))
                        .contentType(APPLICATION_JSON).content(request)).andExpect(status().isForbidden());
        int id = objectMapper.readTree(createInvoice().andReturn().getResponse().getContentAsString())
                .path("data").path("invoice").path("id").asInt();
        String payment = objectMapper.writeValueAsString(Map.of("amount", 50000, "method", "CHUYEN_KHOAN",
                "requestId", UUID.randomUUID().toString(), "bankAccountId", bankId));
        mockMvc.perform(post("/api/invoices/{id}/payments", id).contentType(APPLICATION_JSON).content(payment))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.payments[0].bankAccountId").value(bankId));
        mockMvc.perform(put("/api/bank-accounts/{id}", bankId).contentType(APPLICATION_JSON)
                        .content(request.replace("true", "false"))).andExpect(status().isOk());
        mockMvc.perform(post("/api/invoices/{id}/payments", id).contentType(APPLICATION_JSON).content(payment))
                .andExpect(status().isOk()).andExpect(jsonPath("$.data.payments.length()").value(1));
        mockMvc.perform(post("/api/invoices/{id}/payments", id).contentType(APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("amount", 50000, "method", "CHUYEN_KHOAN",
                                "requestId", UUID.randomUUID().toString(), "bankAccountId", bankId))))
                .andExpect(status().isConflict());
    }

    private org.springframework.test.web.servlet.ResultActions change(String url, String from, String to) throws Exception {
        return mockMvc.perform(put(url).contentType(APPLICATION_JSON).content(objectMapper.writeValueAsString(
                Map.of("expectedStatus", from, "status", to, "notes", "Đã kiểm tra và cập nhật công việc."))));
    }
    private org.springframework.test.web.servlet.ResultActions createInvoice() throws Exception {
        return mockMvc.perform(post("/api/invoices").contentType(APPLICATION_JSON).content("{\"repairOrderId\":9202}"));
    }
    private org.springframework.test.web.servlet.ResultActions pay(int id, int amount, String key) throws Exception {
        return mockMvc.perform(post("/api/invoices/{id}/payments", id).contentType(APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(Map.of("amount", amount, "method", "TIEN_MAT", "requestId", key))));
    }
}
