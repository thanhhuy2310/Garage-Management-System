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
class InventoryApiTest {

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

    @Test
    void stockRequiresJwtAndWarehouseStaffRoles() throws Exception {
        mockMvc.perform(get("/api/inventory")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = {"TECHNICIAN"})
    void technicianAndCustomerCannotReadStockList() throws Exception {
        mockMvc.perform(get("/api/inventory")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "CUSTOMER")
    void customerCannotReadMovements() throws Exception {
        mockMvc.perform(get("/api/inventory/movements")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void warehouseReadsStockWithDerivedStatusAndLowStockCount() throws Exception {
        SparePart low = part(2, 1000);
        org.springframework.test.util.ReflectionTestUtils.setField(low, "stockQuantity", 3);
        when(sparePartRepository.searchInventory(eq("bugi"), eq("SAP_HET"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(low), PageRequest.of(0, 10), 1));
        when(sparePartRepository.countAtOrBelowMinimum()).thenReturn(5L);

        mockMvc.perform(get("/api/inventory").param("search", "bugi").param("status", "SAP_HET"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].stockQuantity").value(3))
                .andExpect(jsonPath("$.data.items[0].stockStatus").value("SAP_HET"))
                .andExpect(jsonPath("$.data.lowStockCount").value(5))
                .andExpect(jsonPath("$.data.totalElements").value(1));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void stockRejectsUnknownStatusFilter() throws Exception {
        mockMvc.perform(get("/api/inventory").param("status", "KHONG_CO"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void movementsAreReadFromBienDongKho() throws Exception {
        StockMovementResponse row = new StockMovementResponse(
                9L, 5, "Bugi", null, 1, LocalDateTime.of(2026, 10, 7, 9, 30), "XUAT", 3, 12, 9, "KTV xác nhận");
        when(stockMovementRepository.search(eq(5), eq("XUAT"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(row), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/inventory/movements").param("partId", "5").param("type", "XUAT"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].type").value("XUAT"))
                .andExpect(jsonPath("$.data.items[0].quantity").value(3))
                .andExpect(jsonPath("$.data.items[0].quantityBefore").value(12))
                .andExpect(jsonPath("$.data.items[0].quantityAfter").value(9));
    }

    @Test
    void swaggerListsInventoryAndWarehouseApis() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/api/inventory")))
                .andExpect(content().string(containsString("/api/warehouse/imports")))
                .andExpect(content().string(containsString("/api/warehouse/exports")))
                .andExpect(content().string(containsString("/api/warehouse/checks")));
    }
}
