// TV3-TUAN8
package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.warehouse.StockMovementResponse;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.InventoryCheck;
import com.gara.quanlygara.entity.InventoryCheckItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockIssue;
import com.gara.quanlygara.entity.StockIssueItem;
import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.entity.StockReceipt;
import com.gara.quanlygara.entity.StockReceiptItem;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.EmployeeRepository;
import com.gara.quanlygara.repository.GarageServiceRepository;
import com.gara.quanlygara.repository.InventoryCheckItemRepository;
import com.gara.quanlygara.repository.InventoryCheckRepository;
import com.gara.quanlygara.repository.RepairOrderRepository;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockIssueItemRepository;
import com.gara.quanlygara.repository.StockIssueRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import com.gara.quanlygara.repository.StockReceiptItemRepository;
import com.gara.quanlygara.repository.StockReceiptRepository;
import com.gara.quanlygara.repository.TechnicianAssignmentRepository;
import com.gara.quanlygara.repository.TechnicianRepository;
import com.gara.quanlygara.repository.VehicleRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {
        "app.jwt.secret=a-test-secret-that-is-at-least-32-characters",
        "spring.autoconfigure.exclude="
                + "org.springframework.boot.autoconfigure.jdbc.DataSourceAutoConfiguration,"
                + "org.springframework.boot.autoconfigure.orm.jpa.HibernateJpaAutoConfiguration,"
                + "org.springframework.boot.autoconfigure.data.jpa.JpaRepositoriesAutoConfiguration"
})
@AutoConfigureMockMvc
class WarehouseApiTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AccountRepository accountRepository;

    @MockitoBean
    private CustomerRepository customerRepository;

    @MockitoBean
    private EmployeeRepository employeeRepository;

    @MockitoBean
    private GarageServiceRepository garageServiceRepository;

    @MockitoBean
    private InventoryCheckItemRepository inventoryCheckItemRepository;

    @MockitoBean
    private InventoryCheckRepository inventoryCheckRepository;

    @MockitoBean
    private RepairOrderRepository repairOrderRepository;

    @MockitoBean
    private RepairPartItemRepository repairPartItemRepository;

    @MockitoBean
    private RepairServiceItemRepository repairServiceItemRepository;

    @MockitoBean
    private SparePartRepository sparePartRepository;

    @MockitoBean
    private StockIssueItemRepository stockIssueItemRepository;

    @MockitoBean
    private StockIssueRepository stockIssueRepository;

    @MockitoBean
    private StockMovementRepository stockMovementRepository;

    @MockitoBean
    private StockReceiptItemRepository stockReceiptItemRepository;

    @MockitoBean
    private StockReceiptRepository stockReceiptRepository;

    @MockitoBean
    private TechnicianAssignmentRepository technicianAssignmentRepository;

    @MockitoBean
    private TechnicianRepository technicianRepository;

    @MockitoBean
    private VehicleRepository vehicleRepository;

    private Account account(String username, AccountRole role, Integer employeeId) {
        Account account = new Account();
        account.setId(1);
        account.setUsername(username);
        account.setPasswordHash("hash");
        account.setRole(role);
        account.setActive(true);
        account.setEmployeeId(employeeId);
        when(accountRepository.findByUsername(username)).thenReturn(Optional.of(account));
        return account;
    }

    private SparePart part(int id, int unitPrice) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName("Bugi");
        part.setUnitPrice(new BigDecimal(unitPrice));
        part.setMinStockLevel(5);
        return part;
    }

    private static final String IMPORT_BODY =
            "{\"supplier\":\"Công ty ABC\",\"items\":[{\"partId\":5,\"quantity\":8,\"unitPrice\":100000}]}";
    private static final String ISSUE_BODY =
            "{\"repairOrderId\":9,\"requestedTechnicianId\":2,\"reason\":\"Thay bugi\",\"items\":[{\"partId\":5,\"quantity\":5}]}";

    // ------------------------------------------------------------------ NHẬP KHO

    @Test
    void importsRequireJwt() throws Exception {
        mockMvc.perform(get("/api/warehouse/imports")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = {"TECHNICIAN"})
    void technicianCannotImport() throws Exception {
        mockMvc.perform(post("/api/warehouse/imports").contentType(APPLICATION_JSON).content(IMPORT_BODY))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void warehouseImportRaisesStockOnceAndReturns201() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, 100000)));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(12));
        when(sparePartRepository.updateStockQuantity(5, 20)).thenReturn(1);
        when(stockReceiptRepository.saveAndFlush(any(StockReceipt.class))).thenAnswer(call -> {
            StockReceipt receipt = call.getArgument(0);
            receipt.setId(3);
            return receipt;
        });
        when(stockReceiptItemRepository.save(any(StockReceiptItem.class))).thenAnswer(call -> call.getArgument(0));
        when(stockMovementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));
        StockReceiptItem saved = new StockReceiptItem();
        saved.setReceiptId(3);
        saved.setPartId(5);
        saved.setQuantity(8);
        saved.setUnitPrice(new BigDecimal("100000.00"));
        when(stockReceiptItemRepository.findByReceiptId(3)).thenReturn(List.of(saved));

        mockMvc.perform(post("/api/warehouse/imports").contentType(APPLICATION_JSON).content(IMPORT_BODY))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value(3))
                .andExpect(jsonPath("$.data.warehouseStaffId").value(7))
                .andExpect(jsonPath("$.data.totalAmount").value(800000.0));

        verify(sparePartRepository).updateStockQuantity(5, 20);
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void importRejectsInvalidBodyAndUnlinkedAccount() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        mockMvc.perform(post("/api/warehouse/imports").contentType(APPLICATION_JSON)
                        .content("{\"supplier\":\" \",\"items\":[{\"partId\":5,\"quantity\":0,\"unitPrice\":-1}]}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));

        account("kho", AccountRole.WAREHOUSE, null);
        mockMvc.perform(post("/api/warehouse/imports").contentType(APPLICATION_JSON).content(IMPORT_BODY))
                .andExpect(status().isBadRequest());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void importReturns404ForUnknownPart() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        when(sparePartRepository.findById(5)).thenReturn(Optional.empty());

        mockMvc.perform(post("/api/warehouse/imports").contentType(APPLICATION_JSON).content(IMPORT_BODY))
                .andExpect(status().isNotFound());
    }

    // ------------------------------------------------------------------ XUẤT KHO / THỰC DÙNG

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void technicianCannotCreateIssueButSeesOnlyRelatedIssues() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        mockMvc.perform(post("/api/warehouse/exports").contentType(APPLICATION_JSON).content(ISSUE_BODY))
                .andExpect(status().isForbidden());

        when(stockIssueRepository.findIdsRelatedToTechnician(2)).thenReturn(List.of());
        mockMvc.perform(get("/api/warehouse/exports"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(0));
        verify(stockIssueRepository, never()).findAllByOrderByIdDesc(any(Pageable.class));
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void warehouseIssueReturns201AndDoesNotReduceStock() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        when(repairServiceItemRepository.findRepairOrderStatus(9)).thenReturn(Optional.of("DANG_SUA"));
        when(stockIssueItemRepository.countAssignment(9, 2)).thenReturn(1L);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, 180000)));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));
        when(stockIssueItemRepository.sumPendingAllocation(5)).thenReturn(0L);
        when(stockIssueRepository.saveAndFlush(any(StockIssue.class))).thenAnswer(call -> {
            StockIssue issue = call.getArgument(0);
            issue.setId(1);
            return issue;
        });
        StockIssueItem saved = new StockIssueItem();
        saved.setIssueId(1);
        saved.setPartId(5);
        saved.setQuantity(5);
        saved.setUnitPrice(new BigDecimal("180000.00"));
        when(stockIssueItemRepository.save(any(StockIssueItem.class))).thenAnswer(call -> call.getArgument(0));
        when(stockIssueItemRepository.findByIssueId(1)).thenReturn(List.of(saved));

        mockMvc.perform(post("/api/warehouse/exports").contentType(APPLICATION_JSON).content(ISSUE_BODY))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.items[0].state").value("CHO_XAC_NHAN"))
                .andExpect(jsonPath("$.data.items[0].issuedQuantity").value(5));

        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(stockMovementRepository, never()).save(any(StockMovement.class));
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void issueReturns409WhenStockIsNotEnough() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        when(repairServiceItemRepository.findRepairOrderStatus(9)).thenReturn(Optional.of("DANG_SUA"));
        when(stockIssueItemRepository.countAssignment(9, 2)).thenReturn(1L);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, 180000)));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(2));
        when(stockIssueItemRepository.sumPendingAllocation(5)).thenReturn(0L);

        mockMvc.perform(post("/api/warehouse/exports").contentType(APPLICATION_JSON).content(ISSUE_BODY))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void technicianConfirmsActualUsedAndStockDropsByActualOnly() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        arrangeConfirmable(5, 12);

        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":3}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.state").value("DA_XAC_NHAN"))
                .andExpect(jsonPath("$.data.issuedQuantity").value(5))
                .andExpect(jsonPath("$.data.actualUsedQuantity").value(3))
                .andExpect(jsonPath("$.data.returnedQuantity").value(2))
                .andExpect(jsonPath("$.data.stockAfter").value(9));

        verify(sparePartRepository).updateStockQuantity(5, 9);
    }

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void confirmRejectsActualGreaterThanIssuedAndDoubleConfirmation() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        StockIssueItem item = arrangeConfirmable(5, 12);

        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":6}"))
                .andExpect(status().isBadRequest());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());

        item.setConfirmed(true);
        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":3}"))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void confirmRejectsNegativeActualUsedAtValidation() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":-1}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.actualUsed").exists());
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void warehouseCannotConfirmUsage() throws Exception {
        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":3}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "quanly", roles = "MANAGER")
    void managerMustNameTheTechnicianWhenConfirming() throws Exception {
        account("quanly", AccountRole.MANAGER, 1);
        arrangeConfirmable(5, 12);

        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":3}"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/warehouse/exports/1/items/5/confirm").contentType(APPLICATION_JSON)
                        .content("{\"actualUsed\":3,\"technicianId\":2}"))
                .andExpect(status().isOk());
    }

    // ------------------------------------------------------------------ CHI TIẾT PHIẾU XUẤT THEO QUYỀN

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void technicianReadsAnIssueRelatedToThem() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        stubIssueDetail();
        when(stockIssueRepository.countRelatedToTechnician(1, 2)).thenReturn(1L);

        mockMvc.perform(get("/api/warehouse/exports/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(1))
                .andExpect(jsonPath("$.data.items[0].partId").value(5));
    }

    @Test
    @WithMockUser(username = "ktv", roles = "TECHNICIAN")
    void technicianGets403AndNoDataForAnUnrelatedIssue() throws Exception {
        account("ktv", AccountRole.TECHNICIAN, 2);
        stubIssueDetail();
        when(stockIssueRepository.countRelatedToTechnician(1, 2)).thenReturn(0L);

        mockMvc.perform(get("/api/warehouse/exports/1"))
                .andExpect(status().isForbidden())
                .andExpect(content().string(not(containsString("Thay bugi"))));
        verify(stockIssueRepository, never()).findById(any());
    }

    @Test
    @WithMockUser(username = "quanly", roles = "MANAGER")
    void managerReadsAnyIssue() throws Exception {
        account("quanly", AccountRole.MANAGER, 1);
        stubIssueDetail();

        mockMvc.perform(get("/api/warehouse/exports/1")).andExpect(status().isOk());
        verify(stockIssueRepository, never()).countRelatedToTechnician(any(), any());
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void warehouseReadsAnyIssue() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        stubIssueDetail();

        mockMvc.perform(get("/api/warehouse/exports/1")).andExpect(status().isOk());
        verify(stockIssueRepository, never()).countRelatedToTechnician(any(), any());
    }

    @Test
    @WithMockUser(username = "admin", roles = "ADMIN")
    void adminReadsAnyIssue() throws Exception {
        account("admin", AccountRole.ADMIN, null);
        stubIssueDetail();

        mockMvc.perform(get("/api/warehouse/exports/1")).andExpect(status().isOk());
        verify(stockIssueRepository, never()).countRelatedToTechnician(any(), any());
    }

    @Test
    @WithMockUser(roles = "CUSTOMER")
    void customerCannotReadIssues() throws Exception {
        mockMvc.perform(get("/api/warehouse/exports/1")).andExpect(status().isForbidden());
    }

    private void stubIssueDetail() {
        StockIssue issue = new StockIssue();
        issue.setId(1);
        issue.setRepairOrderId(9);
        issue.setReason("Thay bugi");
        StockIssueItem item = new StockIssueItem();
        item.setIssueId(1);
        item.setPartId(5);
        item.setQuantity(5);
        item.setUnitPrice(new BigDecimal("180000.00"));
        when(stockIssueRepository.findById(1)).thenReturn(Optional.of(issue));
        when(stockIssueItemRepository.findByIssueId(1)).thenReturn(List.of(item));
    }

    // ------------------------------------------------------------------ KIỂM KÊ

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void warehouseCreatesCheckButCannotApproveOrReject() throws Exception {
        account("kho", AccountRole.WAREHOUSE, 7);
        when(sparePartRepository.existsById(5)).thenReturn(true);
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));
        InventoryCheck[] holder = new InventoryCheck[1];
        when(inventoryCheckRepository.saveAndFlush(any(InventoryCheck.class))).thenAnswer(call -> {
            InventoryCheck check = call.getArgument(0);
            check.setId(1);
            holder[0] = check;
            return check;
        });
        when(inventoryCheckRepository.findById(1)).thenAnswer(call -> Optional.of(holder[0]));
        InventoryCheckItem item = new InventoryCheckItem();
        item.setCheckId(1);
        item.setPartId(5);
        item.setSystemQuantity(10);
        when(inventoryCheckItemRepository.save(any(InventoryCheckItem.class))).thenAnswer(call -> call.getArgument(0));
        when(inventoryCheckItemRepository.findByCheckIdOrderByPartId(1)).thenReturn(List.of(item));

        mockMvc.perform(post("/api/warehouse/checks").contentType(APPLICATION_JSON)
                        .content("{\"note\":\"Tháng 10\",\"partIds\":[5]}"))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.status").value("DANG_KIEM_KE"))
                .andExpect(jsonPath("$.data.items[0].systemQuantity").value(10));

        mockMvc.perform(post("/api/warehouse/checks/1/approve").contentType(APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/warehouse/checks/1/reject").contentType(APPLICATION_JSON)
                        .content("{\"reason\":\"x\"}"))
                .andExpect(status().isForbidden());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    @WithMockUser(username = "admin", roles = "ADMIN")
    void adminCannotApproveInventoryAdjustments() throws Exception {
        mockMvc.perform(post("/api/warehouse/checks/1/approve").contentType(APPLICATION_JSON).content("{}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "quanly", roles = "MANAGER")
    void managerApprovalSetsStockToActualCount() throws Exception {
        account("quanly", AccountRole.MANAGER, 1);
        InventoryCheck check = new InventoryCheck();
        check.setId(1);
        check.setStatus(InventoryCheck.PENDING_APPROVAL);
        InventoryCheckItem item = new InventoryCheckItem();
        item.setCheckId(1);
        item.setPartId(5);
        item.setSystemQuantity(10);
        item.setActualQuantity(7);
        when(inventoryCheckRepository.findById(1)).thenReturn(Optional.of(check));
        when(inventoryCheckRepository.saveAndFlush(any(InventoryCheck.class))).thenAnswer(call -> call.getArgument(0));
        when(inventoryCheckItemRepository.findByCheckIdOrderByPartId(1)).thenReturn(List.of(item));
        when(inventoryCheckItemRepository.save(any(InventoryCheckItem.class))).thenAnswer(call -> call.getArgument(0));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));
        when(sparePartRepository.updateStockQuantity(5, 7)).thenReturn(1);
        when(stockMovementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));

        mockMvc.perform(post("/api/warehouse/checks/1/approve").contentType(APPLICATION_JSON)
                        .content("{\"reason\":\"Đồng ý\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("DA_HOAN_TAT"))
                .andExpect(jsonPath("$.data.approvedBy").value(1));

        verify(sparePartRepository).updateStockQuantity(5, 7);
    }

    @Test
    @WithMockUser(username = "quanly", roles = "MANAGER")
    void managerRejectNeedsReasonAndNeverChangesStock() throws Exception {
        account("quanly", AccountRole.MANAGER, 1);
        InventoryCheck check = new InventoryCheck();
        check.setId(1);
        check.setStatus(InventoryCheck.PENDING_APPROVAL);
        when(inventoryCheckRepository.findById(1)).thenReturn(Optional.of(check));
        when(inventoryCheckRepository.saveAndFlush(any(InventoryCheck.class))).thenAnswer(call -> call.getArgument(0));
        when(inventoryCheckItemRepository.findByCheckIdOrderByPartId(1)).thenReturn(List.of());

        mockMvc.perform(post("/api/warehouse/checks/1/reject").contentType(APPLICATION_JSON).content("{}"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/warehouse/checks/1/reject").contentType(APPLICATION_JSON)
                        .content("{\"reason\":\"Cần đếm lại\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("DA_TU_CHOI"));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    @WithMockUser(username = "kho", roles = "WAREHOUSE")
    void checkActualQuantityValidationReturns400() throws Exception {
        mockMvc.perform(put("/api/warehouse/checks/1/items/5").contentType(APPLICATION_JSON)
                        .content("{\"actualQuantity\":-3}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.actualQuantity").exists());
    }

    // ------------------------------------------------------------------ helpers

    /** Ngữ cảnh xác nhận hợp lệ: đã phân công, báo giá xác nhận, phiếu sửa chữa đang sửa, đã cấp phát 5. */
    private StockIssueItem arrangeConfirmable(int issued, int stock) {
        StockIssueItem item = new StockIssueItem();
        item.setIssueId(1);
        item.setPartId(5);
        item.setQuantity(issued);
        item.setUnitPrice(new BigDecimal("180000.00"));
        StockIssue issue = new StockIssue();
        issue.setId(1);
        issue.setRepairOrderId(9);
        issue.setReason("Thay bugi");

        when(stockIssueItemRepository.findForUpdate(1, 5)).thenReturn(Optional.of(item));
        when(stockIssueRepository.findById(1)).thenReturn(Optional.of(issue));
        when(stockIssueItemRepository.countAssignment(9, 2)).thenReturn(1L);
        when(stockIssueItemRepository.countConfirmedQuotation(9)).thenReturn(1L);
        when(repairServiceItemRepository.findRepairOrderStatus(9)).thenReturn(Optional.of("DANG_SUA"));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(stock));
        when(sparePartRepository.updateStockQuantity(anyInt(), anyInt())).thenReturn(1);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, 180000)));
        when(stockMovementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));
        when(stockIssueItemRepository.saveAndFlush(any(StockIssueItem.class))).thenAnswer(call -> call.getArgument(0));
        when(stockIssueItemRepository.sumConfirmedActual(9, 5)).thenReturn(3L);
        when(repairPartItemRepository.findById(any())).thenReturn(Optional.empty());
        when(repairPartItemRepository.saveAndFlush(any())).thenAnswer(call -> call.getArgument(0));
        return item;
    }
}
