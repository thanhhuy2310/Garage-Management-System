package com.gara.quanlygara.config;

import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.EmployeeRepository;
import com.gara.quanlygara.repository.TechnicianRepository;
import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.Customer;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
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
class SecurityConfigTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AccountRepository accountRepository;

    @MockitoBean
    private CustomerRepository customerRepository;

    @MockitoBean
    private EmployeeRepository employeeRepository;

    @MockitoBean
    private TechnicianRepository technicianRepository;

    @Test
    void accountApiRejectsRequestWithoutJwt() throws Exception {
        mockMvc.perform(get("/api/accounts"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void accountApiRejectsWrongRole() throws Exception {
        mockMvc.perform(get("/api/accounts"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void publicRegisterIgnoresInjectedAdminRole() throws Exception {
        when(customerRepository.save(any(Customer.class))).thenAnswer(invocation -> {
            Customer customer = invocation.getArgument(0);
            customer.setId(10);
            return customer;
        });
        when(accountRepository.save(any(Account.class))).thenAnswer(invocation -> {
            Account account = invocation.getArgument(0);
            account.setId(20);
            return account;
        });

        mockMvc.perform(post("/api/auth/register")
                        .contentType(APPLICATION_JSON)
                        .content("""
                                {
                                  "fullName": "Khách Test",
                                  "phone": "0909999999",
                                  "email": "test@example.com",
                                  "address": "TP.HCM",
                                  "username": "khach-test",
                                  "password": "password123",
                                  "role": "ADMIN",
                                  "employeeId": 6
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.account.role").value("CUSTOMER"))
                .andExpect(jsonPath("$.data.account.customerId").value(10))
                .andExpect(jsonPath("$.data.account.employeeId").doesNotExist());
    }

    @Test
    @WithMockUser(roles = "CUSTOMER")
    void customerCannotCreateStaffAccount() throws Exception {
        mockMvc.perform(post("/api/accounts")
                        .contentType(APPLICATION_JSON)
                        .content("{}"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void receptionistCannotChangeAccountRole() throws Exception {
        mockMvc.perform(patch("/api/accounts/1/role")
                        .contentType(APPLICATION_JSON)
                        .content("{\"role\":\"MANAGER\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void managerCannotChangeAccountRole() throws Exception {
        mockMvc.perform(patch("/api/accounts/1/role")
                        .contentType(APPLICATION_JSON)
                        .content("{\"role\":\"ADMIN\"}"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void adminCanChangeStaffRole() throws Exception {
        Account account = new Account();
        account.setId(1);
        account.setUsername("staff");
        account.setPasswordHash("hash");
        account.setRole(AccountRole.RECEPTIONIST);
        account.setActive(true);
        account.setEmployeeId(1);
        when(accountRepository.findById(1)).thenReturn(Optional.of(account));
        when(employeeRepository.existsById(1)).thenReturn(true);
        when(accountRepository.save(account)).thenReturn(account);

        mockMvc.perform(patch("/api/accounts/1/role")
                        .contentType(APPLICATION_JSON)
                        .content("{\"role\":\"MANAGER\"}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.role").value("MANAGER"));
    }
}
