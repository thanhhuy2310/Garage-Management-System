// TV3-TUAN10
package com.gara.quanlygara.controller;
import org.springframework.jdbc.core.JdbcTemplate;


import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.CustomerNotification;
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
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
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
class CustomerNotificationApiTest {

    @MockitoBean
    private com.gara.quanlygara.repository.InsuranceCompanyRepository insuranceCompanyRepository;

    @MockitoBean
    private com.gara.quanlygara.repository.InsurancePolicyRepository insurancePolicyRepository;

    @MockitoBean
    private com.gara.quanlygara.repository.InsuranceClaimRepository insuranceClaimRepository;

    @MockitoBean
    private com.gara.quanlygara.repository.InsuranceClaimEventRepository insuranceClaimEventRepository;

    @MockitoBean
    private com.gara.quanlygara.repository.InsuranceReceptionRepository insuranceReceptionRepository;

    @MockitoBean
    private JdbcTemplate jdbcTemplateTestMock;


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

    private CustomerNotification notification(long id, String type, boolean read) {
        CustomerNotification notification = new CustomerNotification();
        notification.setId(id);
        notification.setCustomerId(1);
        notification.setTypeCode(type);
        notification.setTitle("Tiêu đề " + id);
        notification.setMessage("Nội dung " + id);
        notification.setCreatedAt(LocalDateTime.of(2026, 10, 1, 9, 0).plusMinutes(id));
        notification.setRead(read);
        return notification;
    }

    @Test
    void notificationsRequireJwt() throws Exception {
        mockMvc.perform(get("/api/customers/me/notifications")).andExpect(status().isUnauthorized());
        mockMvc.perform(patch("/api/customers/me/notifications/read-all")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void staffRolesCannotUseTheCustomerNotificationApi() throws Exception {
        mockMvc.perform(get("/api/customers/me/notifications")).andExpect(status().isForbidden());
        mockMvc.perform(get("/api/customers/me/notifications/unread-count")).andExpect(status().isForbidden());
        mockMvc.perform(patch("/api/customers/me/notifications/1/read")).andExpect(status().isForbidden());
        mockMvc.perform(patch("/api/customers/me/notifications/read-all")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "TECHNICIAN")
    void technicianCannotUseTheCustomerNotificationApi() throws Exception {
        mockMvc.perform(get("/api/customers/me/notifications")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void customerListsOwnNotificationsNewestFirstAndIgnoresACustomerIdParameter() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(customerNotificationRepository.findByCustomerIdOrderByCreatedAtDescIdDesc(eq(1), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(
                        notification(3L, "HOAN_TAT_SUA_CHUA", false),
                        notification(2L, "LICH_HEN", true),
                        notification(1L, "NHAC_BAO_DUONG", false)), PageRequest.of(0, 20), 3));

        mockMvc.perform(get("/api/customers/me/notifications").param("customerId", "2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.items.length()").value(3))
                .andExpect(jsonPath("$.data.items[0].id").value(3))
                .andExpect(jsonPath("$.data.items[0].type").value("repair"))
                .andExpect(jsonPath("$.data.items[0].isRead").value(false))
                .andExpect(jsonPath("$.data.items[1].type").value("appointment"))
                .andExpect(jsonPath("$.data.items[1].isRead").value(true))
                .andExpect(jsonPath("$.data.items[2].type").value("maintenance"))
                .andExpect(jsonPath("$.data.totalElements").value(3))
                .andExpect(jsonPath("$.data.page").value(0));

        verify(customerNotificationRepository).findByCustomerIdOrderByCreatedAtDescIdDesc(eq(1), any(Pageable.class));
        verify(customerNotificationRepository, never()).findByCustomerIdOrderByCreatedAtDescIdDesc(eq(2), any(Pageable.class));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void unreadCountReturnsACountField() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(customerNotificationRepository.countByCustomerIdAndReadFalse(1)).thenReturn(5L);

        mockMvc.perform(get("/api/customers/me/notifications/unread-count"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.count").value(5));
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void markReadStoresTheStateThroughTheOwnedUpdate() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(customerNotificationRepository.markRead(2L, 1)).thenReturn(1);
        when(customerNotificationRepository.findByIdAndCustomerId(2L, 1))
                .thenReturn(Optional.of(notification(2L, "LICH_HEN", true)));

        mockMvc.perform(patch("/api/customers/me/notifications/2/read"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(2))
                .andExpect(jsonPath("$.data.isRead").value(true));
        verify(customerNotificationRepository).markRead(2L, 1);
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void markReadOfSomeoneElsesNotificationIsNotFoundAndLeaksNothing() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(customerNotificationRepository.markRead(77L, 1)).thenReturn(0);

        mockMvc.perform(patch("/api/customers/me/notifications/77/read"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(content().string(org.hamcrest.Matchers.not(containsString("Tiêu đề"))));
        verify(customerNotificationRepository, never()).findByIdAndCustomerId(any(), any());
    }

    @Test
    @WithMockUser(username = "khachA", roles = "CUSTOMER")
    void readAllReportsTheUpdatedAndRemainingUnreadCounts() throws Exception {
        account("khachA", AccountRole.CUSTOMER, 1);
        when(customerNotificationRepository.markAllRead(1)).thenReturn(4);
        when(customerNotificationRepository.countByCustomerIdAndReadFalse(1)).thenReturn(0L);

        mockMvc.perform(patch("/api/customers/me/notifications/read-all"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.updatedCount").value(4))
                .andExpect(jsonPath("$.data.unreadCount").value(0));
        verify(customerNotificationRepository).markAllRead(1);
    }

    @Test
    @WithMockUser(username = "khachX", roles = "CUSTOMER")
    void customerAccountWithoutALinkedCustomerIsForbidden() throws Exception {
        account("khachX", AccountRole.CUSTOMER, null);

        mockMvc.perform(get("/api/customers/me/notifications")).andExpect(status().isForbidden());
        mockMvc.perform(patch("/api/customers/me/notifications/read-all")).andExpect(status().isForbidden());
        verify(customerNotificationRepository, never()).markAllRead(any());
    }

    @Test
    void swaggerListsTheNotificationAndReminderApis() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/api/customers/me/notifications")))
                .andExpect(content().string(containsString("/api/customers/me/notifications/unread-count")))
                .andExpect(content().string(containsString("/api/maintenance-reminders")));
    }
}
