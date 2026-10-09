// TV3-TUAN9
package com.gara.quanlygara.controller;

import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.EmployeeRepository;
import com.gara.quanlygara.repository.GarageServiceRepository;
import com.gara.quanlygara.repository.InventoryCheckItemRepository;
import com.gara.quanlygara.repository.InventoryCheckRepository;
import com.gara.quanlygara.repository.RepairHistoryRepository;
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
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
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
class CustomerHistoryApiTest {

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
    private RepairHistoryRepository repairHistoryRepository;

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

    private void account(String username, AccountRole role, Integer customerId) {
        Account account = new Account();
        account.setId(1);
        account.setUsername(username);
        account.setPasswordHash("hash");
        account.setRole(role);
        account.setActive(true);
        account.setCustomerId(customerId);
        when(accountRepository.findByUsername(username)).thenReturn(Optional.of(account));
    }

    private List<Object[]> rows(Object[]... rows) {
        return new ArrayList<>(Arrays.asList(rows));
    }

    private Object[] header(int orderId, int vehicleId, String plate) {
        return new Object[]{orderId, vehicleId, plate, "Toyota", "Camry",
                Timestamp.valueOf("2026-09-18 08:00:00"), Timestamp.valueOf("2026-09-19 08:00:00"),
                Timestamp.valueOf("2026-09-20 10:00:00"), "Hoàn tất tốt", new BigDecimal("1380000")};
    }

    @Test
    void historyRequiresJwt() throws Exception {
        mockMvc.perform(get("/api/customers/me/history")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void managerCannotUseTheCustomerHistoryApi() throws Exception {
        mockMvc.perform(get("/api/customers/me/history")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void receptionistCannotUseTheCustomerHistoryApi() throws Exception {
        mockMvc.perform(get("/api/customers/me/history/1")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "TECHNICIAN")
    void technicianCannotUseTheCustomerHistoryApi() throws Exception {
        mockMvc.perform(get("/api/customers/me/history")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerSeesOwnHistoryAndCustomerIdFromTheClientIsIgnored() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.findHistoryRows(1, 0, 0)).thenReturn(rows(header(12, 3, "51G-123.45")));
        when(repairHistoryRepository.findServiceLines(any())).thenReturn(rows(
                new Object[]{12, 2, "Bảo dưỡng định kỳ", "BAO_DUONG", 1, new BigDecimal("1200000")}));
        when(repairHistoryRepository.findPartLines(any())).thenReturn(rows(
                new Object[]{12, 9, "Lọc dầu", 2, new BigDecimal("90000")}));

        // Client cố truyền customerId của người khác: bị bỏ qua, truy vấn luôn dùng customerId của JWT (1).
        mockMvc.perform(get("/api/customers/me/history").param("customerId", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(1))
                .andExpect(jsonPath("$.data[0].repairOrderId").value(12))
                .andExpect(jsonPath("$.data[0].licensePlate").value("51G-123.45"))
                .andExpect(jsonPath("$.data[0].category").value("BAO_DUONG"))
                .andExpect(jsonPath("$.data[0].totalCost").value(1380000.0));

        verify(repairHistoryRepository).findHistoryRows(1, 0, 0);
        verify(repairHistoryRepository, never()).findHistoryRows(2, 0, 0);
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerWithNoHistoryGetsAnEmptyList() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.findHistoryRows(1, 0, 0)).thenReturn(new ArrayList<>());

        mockMvc.perform(get("/api/customers/me/history"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.length()").value(0));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerCanFilterByOwnVehicle() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.countOwnedVehicle(3, 1)).thenReturn(1L);
        when(repairHistoryRepository.findHistoryRows(1, 3, 0)).thenReturn(rows(header(12, 3, "51G-123.45")));
        when(repairHistoryRepository.findServiceLines(any())).thenReturn(new ArrayList<>());
        when(repairHistoryRepository.findPartLines(any())).thenReturn(new ArrayList<>());

        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", "3"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].vehicleId").value(3));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerCannotFilterByAnotherCustomersVehicle() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.countOwnedVehicle(50, 1)).thenReturn(0L);

        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", "50"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
        verify(repairHistoryRepository, never()).findHistoryRows(any(), any(), any());
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void invalidVehicleIdIsABadRequest() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);

        mockMvc.perform(get("/api/customers/me/history").param("vehicleId", "0"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void detailOfTheCustomersOwnOrderHasServicesPartsAndTotals() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(repairHistoryRepository.findHistoryRows(1, 0, 12)).thenReturn(rows(header(12, 3, "51G-123.45")));
        when(repairHistoryRepository.findServiceLines(any())).thenReturn(rows(
                new Object[]{12, 2, "Bảo dưỡng định kỳ", "BAO_DUONG", 1, new BigDecimal("1200000")}));
        when(repairHistoryRepository.findPartLines(any())).thenReturn(rows(
                new Object[]{12, 9, "Lọc dầu", 2, new BigDecimal("90000")}));

        mockMvc.perform(get("/api/customers/me/history/12"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.item.repairOrderId").value(12))
                .andExpect(jsonPath("$.data.services[0].name").value("Bảo dưỡng định kỳ"))
                .andExpect(jsonPath("$.data.parts[0].lineTotal").value(180000.0))
                .andExpect(jsonPath("$.data.serviceTotal").value(1200000.0))
                .andExpect(jsonPath("$.data.partsTotal").value(180000.0));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void detailOfAnotherCustomersOrderIsNotFoundAndLeaksNothing() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        // Phiếu 99 của khách hàng khác: truy vấn (lọc theo khách hàng A) không trả dòng nào.
        when(repairHistoryRepository.findHistoryRows(1, 0, 99)).thenReturn(new ArrayList<>());

        mockMvc.perform(get("/api/customers/me/history/99"))
                .andExpect(status().isNotFound())
                .andExpect(content().string(not(containsString("51G"))));
        verify(repairHistoryRepository, never()).findServiceLines(any());
    }

    @Test
    @WithMockUser(username = "khachX", roles = "CUSTOMER")
    void customerAccountWithoutALinkedCustomerIsForbidden() throws Exception {
        account("khachX", AccountRole.CUSTOMER, null);

        mockMvc.perform(get("/api/customers/me/history")).andExpect(status().isForbidden());
        verify(repairHistoryRepository, never()).findHistoryRows(any(), any(), any());
    }

    @Test
    void swaggerListsTheHistoryApi() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/api/customers/me/history")));
    }
}
