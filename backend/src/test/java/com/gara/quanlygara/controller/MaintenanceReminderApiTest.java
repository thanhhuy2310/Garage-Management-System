// TV3-TUAN10
package com.gara.quanlygara.controller;
import org.springframework.jdbc.core.JdbcTemplate;


import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.MaintenanceReminder;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerNotificationRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.EmployeeRepository;
import com.gara.quanlygara.repository.GarageServiceRepository;
import com.gara.quanlygara.repository.InventoryCheckItemRepository;
import com.gara.quanlygara.repository.InventoryCheckRepository;
import com.gara.quanlygara.repository.InvoiceRepository;
import com.gara.quanlygara.repository.MaintenanceReminderRepository;
import com.gara.quanlygara.repository.PaymentRepository;
import com.gara.quanlygara.repository.ReceivingBankAccountRepository;
import com.gara.quanlygara.repository.RepairHistoryRepository;
import com.gara.quanlygara.repository.RepairOrderRepository;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairProgressRepository;
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
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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
class MaintenanceReminderApiTest {

    @MockitoBean
    private JdbcTemplate jdbcTemplateTestMock;


    private static final String BODY = "{\"vehicleId\":1,\"dueDate\":\"2026-11-01\",\"dueKm\":15000,\"note\":\"Thay dầu\"}";

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AccountRepository accountRepository;

    @MockitoBean
    private CustomerNotificationRepository customerNotificationRepository;

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
    private InvoiceRepository invoiceRepository;

    @MockitoBean
    private MaintenanceReminderRepository maintenanceReminderRepository;

    @MockitoBean
    private PaymentRepository paymentRepository;

    @MockitoBean
    private ReceivingBankAccountRepository receivingBankAccountRepository;

    @MockitoBean
    private RepairHistoryRepository repairHistoryRepository;

    @MockitoBean
    private RepairOrderRepository repairOrderRepository;

    @MockitoBean
    private RepairPartItemRepository repairPartItemRepository;

    @MockitoBean
    private RepairProgressRepository repairProgressRepository;

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

    private void account(String username, AccountRole role, Integer employeeId) {
        Account account = new Account();
        account.setId(1);
        account.setUsername(username);
        account.setPasswordHash("hash");
        account.setRole(role);
        account.setActive(true);
        account.setEmployeeId(employeeId);
        when(accountRepository.findByUsername(username)).thenReturn(Optional.of(account));
    }

    private MaintenanceReminder reminder(int id, String status) {
        MaintenanceReminder reminder = new MaintenanceReminder();
        reminder.setId(id);
        reminder.setVehicleId(1);
        reminder.setDueDate(LocalDate.of(2026, 11, 1));
        reminder.setDueKm(15000);
        reminder.setStatus(status);
        reminder.setCreatedAt(LocalDate.of(2026, 10, 1).atStartOfDay());
        return reminder;
    }

    @Test
    void remindersRequireJwt() throws Exception {
        mockMvc.perform(get("/api/maintenance-reminders")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "CUSTOMER")
    void customersCannotManageMaintenanceReminders() throws Exception {
        mockMvc.perform(get("/api/maintenance-reminders")).andExpect(status().isForbidden());
        mockMvc.perform(post("/api/maintenance-reminders").contentType(APPLICATION_JSON).content(BODY))
                .andExpect(status().isForbidden());
        mockMvc.perform(post("/api/maintenance-reminders/1/cancel")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = {"WAREHOUSE"})
    void warehouseStaffCannotManageMaintenanceReminders() throws Exception {
        mockMvc.perform(get("/api/maintenance-reminders")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "letan", roles = "RECEPTIONIST")
    void receptionistCreatesAReminderAndTheCreatorIsRecorded() throws Exception {
        account("letan", AccountRole.RECEPTIONIST, 4);
        when(maintenanceReminderRepository.countVehicle(1)).thenReturn(1L);
        when(maintenanceReminderRepository.saveAndFlush(any(MaintenanceReminder.class))).thenAnswer(call -> {
            MaintenanceReminder saved = call.getArgument(0);
            saved.setId(8);
            return saved;
        });

        mockMvc.perform(post("/api/maintenance-reminders").contentType(APPLICATION_JSON).content(BODY))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value(8))
                .andExpect(jsonPath("$.data.status").value("CHO_NHAC"))
                .andExpect(jsonPath("$.data.dueKm").value(15000))
                .andExpect(jsonPath("$.data.dueDate").value("2026-11-01"));
    }

    @Test
    @WithMockUser(username = "letan", roles = "RECEPTIONIST")
    void aReminderWithoutDateOrKilometersIsRejected() throws Exception {
        account("letan", AccountRole.RECEPTIONIST, 4);

        mockMvc.perform(post("/api/maintenance-reminders").contentType(APPLICATION_JSON).content("{\"vehicleId\":1}"))
                .andExpect(status().isBadRequest());
        mockMvc.perform(post("/api/maintenance-reminders").contentType(APPLICATION_JSON)
                        .content("{\"vehicleId\":1,\"dueKm\":-5}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.dueKm").exists());
        verify(maintenanceReminderRepository, never()).saveAndFlush(any(MaintenanceReminder.class));
    }

    @Test
    @WithMockUser(username = "letan", roles = "RECEPTIONIST")
    void unknownVehicleIsNotFoundAndNonMaintenanceServiceIsRejected() throws Exception {
        account("letan", AccountRole.RECEPTIONIST, 4);
        when(maintenanceReminderRepository.countVehicle(1)).thenReturn(0L);
        mockMvc.perform(post("/api/maintenance-reminders").contentType(APPLICATION_JSON).content(BODY))
                .andExpect(status().isNotFound());

        when(maintenanceReminderRepository.countVehicle(1)).thenReturn(1L);
        when(maintenanceReminderRepository.findServiceType(3)).thenReturn(Optional.of("SUA_CHUA"));
        mockMvc.perform(post("/api/maintenance-reminders").contentType(APPLICATION_JSON)
                        .content("{\"vehicleId\":1,\"serviceId\":3,\"dueDate\":\"2026-11-01\"}"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(username = "quanly", roles = "MANAGER")
    void managerListsRemindersWithPaginationMetadata() throws Exception {
        account("quanly", AccountRole.MANAGER, 1);
        when(maintenanceReminderRepository.search(eq(0), eq("ALL"), any()))
                .thenReturn(new PageImpl<>(List.of(reminder(2, "CHO_NHAC"), reminder(1, "DA_NHAC"))));

        mockMvc.perform(get("/api/maintenance-reminders"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(2))
                .andExpect(jsonPath("$.data.totalElements").value(2));
    }

    @Test
    @WithMockUser(username = "quanly", roles = "MANAGER")
    void managerCancelsAPendingReminderAndCannotCancelOneAlreadySent() throws Exception {
        account("quanly", AccountRole.MANAGER, 1);
        when(maintenanceReminderRepository.cancelPending(2)).thenReturn(1);
        when(maintenanceReminderRepository.findById(2)).thenReturn(Optional.of(reminder(2, "DA_HUY")));
        mockMvc.perform(post("/api/maintenance-reminders/2/cancel"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.status").value("DA_HUY"));

        when(maintenanceReminderRepository.cancelPending(3)).thenReturn(0);
        when(maintenanceReminderRepository.findById(3)).thenReturn(Optional.of(reminder(3, "DA_NHAC")));
        mockMvc.perform(post("/api/maintenance-reminders/3/cancel")).andExpect(status().isConflict());
    }
}
