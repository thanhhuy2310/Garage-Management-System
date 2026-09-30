package com.gara.quanlygara.controller;

import com.gara.quanlygara.entity.Account;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.entity.Vehicle;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.EmployeeRepository;
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

import java.util.List;
import java.util.Optional;

import static org.hamcrest.Matchers.containsString;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
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
class VehicleApiTest {

    private static final String VEHICLE_JSON = """
            {"customerId":1,"licensePlate":"51a-999.99","brand":"Toyota","model":"Vios","year":2021,"mileage":1000}
            """;

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

    @MockitoBean
    private VehicleRepository vehicleRepository;

    @Test
    void listRejectsRequestWithoutJwt() throws Exception {
        mockMvc.perform(get("/api/vehicles"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void warehouseCannotReadVehicles() throws Exception {
        mockMvc.perform(get("/api/vehicles"))
                .andExpect(status().isForbidden())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void receptionistCanListVehiclesWithPagination() throws Exception {
        when(vehicleRepository.findAll(any(Pageable.class))).thenReturn(
                new PageImpl<>(List.of(vehicle(1, 1, "51A-123.45")), PageRequest.of(0, 10), 1));

        mockMvc.perform(get("/api/vehicles").param("page", "0").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.items[0].licensePlate").value("51A-123.45"))
                .andExpect(jsonPath("$.data.totalElements").value(1))
                .andExpect(jsonPath("$.data.page").value(0));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void searchFiltersByLicensePlate() throws Exception {
        when(vehicleRepository.findByLicensePlateContainingIgnoreCase(eq("59K"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(vehicle(2, 2, "59K-456.78"))));

        mockMvc.perform(get("/api/vehicles").param("search", "59K"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].licensePlate").value("59K-456.78"));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void getByIdReturnsVehicle() throws Exception {
        when(vehicleRepository.findById(2)).thenReturn(Optional.of(vehicle(2, 2, "59K-456.78")));

        mockMvc.perform(get("/api/vehicles/2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(2))
                .andExpect(jsonPath("$.data.customerId").value(2));
    }

    @Test
    @WithMockUser(roles = "ADMIN")
    void getByIdReturns404WhenMissing() throws Exception {
        when(vehicleRepository.findById(404)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/vehicles/404"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns201() throws Exception {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.existsByLicensePlate("51A-999.99")).thenReturn(false);
        stubSave();

        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value(5))
                .andExpect(jsonPath("$.data.licensePlate").value("51A-999.99"));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns409ForDuplicateLicensePlate() throws Exception {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.existsByLicensePlate("51A-999.99")).thenReturn(true);

        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isConflict())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns404ForUnknownCustomer() throws Exception {
        when(customerRepository.existsById(1)).thenReturn(false);

        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns400ForInvalidBody() throws Exception {
        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON)
                        .content("{\"customerId\":1,\"licensePlate\":\"  \",\"mileage\":-5}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.data.licensePlate").exists())
                .andExpect(jsonPath("$.data.mileage").exists());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns400ForMalformedYear() throws Exception {
        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON)
                        .content("{\"customerId\":1,\"licensePlate\":\"51A-1\",\"year\":\"abc\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void updateReturns200() throws Exception {
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle(3, 1, "59K-456.78")));
        when(vehicleRepository.existsByLicensePlateAndIdNot("51A-999.99", 3)).thenReturn(false);
        stubSave();

        mockMvc.perform(put("/api/vehicles/3").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.id").value(3))
                .andExpect(jsonPath("$.data.licensePlate").value("51A-999.99"));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void updateReturns409ForPlateOfAnotherVehicle() throws Exception {
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle(3, 1, "59K-456.78")));
        when(vehicleRepository.existsByLicensePlateAndIdNot("51A-999.99", 3)).thenReturn(true);

        mockMvc.perform(put("/api/vehicles/3").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void staffCanReadVehiclesOfACustomer() throws Exception {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.findByCustomerIdOrderByIdDesc(1)).thenReturn(List.of(vehicle(1, 1, "51A-123.45")));

        mockMvc.perform(get("/api/customers/1/vehicles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].licensePlate").value("51A-123.45"));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void customerWithoutVehiclesGetsEmptyList() throws Exception {
        when(customerRepository.existsById(2)).thenReturn(true);
        when(vehicleRepository.findByCustomerIdOrderByIdDesc(2)).thenReturn(List.of());

        mockMvc.perform(get("/api/customers/2/vehicles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data").isEmpty());
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void customerVehiclesReturns404ForUnknownCustomer() throws Exception {
        when(customerRepository.existsById(99)).thenReturn(false);

        mockMvc.perform(get("/api/customers/99/vehicles"))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(username = "khach", roles = "CUSTOMER")
    void customerCanReadOwnVehicles() throws Exception {
        when(accountRepository.findByUsername("khach")).thenReturn(Optional.of(account(4)));
        when(customerRepository.existsById(4)).thenReturn(true);
        when(vehicleRepository.findByCustomerIdOrderByIdDesc(4)).thenReturn(List.of(vehicle(9, 4, "51K-789.01")));

        mockMvc.perform(get("/api/customers/4/vehicles"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].licensePlate").value("51K-789.01"));
    }

    @Test
    @WithMockUser(username = "khach", roles = "CUSTOMER")
    void customerCannotReadVehiclesOfAnotherCustomer() throws Exception {
        when(accountRepository.findByUsername("khach")).thenReturn(Optional.of(account(4)));

        mockMvc.perform(get("/api/customers/5/vehicles"))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "khach", roles = "CUSTOMER")
    void customerCanAddVehicleForThemselves() throws Exception {
        when(accountRepository.findByUsername("khach")).thenReturn(Optional.of(account(1)));
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.existsByLicensePlate("51A-999.99")).thenReturn(false);
        stubSave();

        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isCreated());
    }

    @Test
    @WithMockUser(username = "khach", roles = "CUSTOMER")
    void customerCannotAddVehicleForSomeoneElse() throws Exception {
        when(accountRepository.findByUsername("khach")).thenReturn(Optional.of(account(4)));

        mockMvc.perform(post("/api/vehicles").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(username = "khach", roles = "CUSTOMER")
    void customerCannotListOrUpdateVehicles() throws Exception {
        mockMvc.perform(get("/api/vehicles")).andExpect(status().isForbidden());
        mockMvc.perform(put("/api/vehicles/3").contentType(APPLICATION_JSON).content(VEHICLE_JSON))
                .andExpect(status().isForbidden());
    }

    @Test
    void swaggerDocumentationListsVehicleApi() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/api/vehicles")));
    }

    private void stubSave() {
        when(vehicleRepository.saveAndFlush(any(Vehicle.class))).thenAnswer(invocation -> {
            Vehicle vehicle = invocation.getArgument(0);
            if (vehicle.getId() == null) vehicle.setId(5);
            return vehicle;
        });
    }

    private Vehicle vehicle(int id, int customerId, String plate) {
        Vehicle vehicle = new Vehicle();
        vehicle.setId(id);
        vehicle.setCustomerId(customerId);
        vehicle.setLicensePlate(plate);
        vehicle.setBrand("Honda");
        vehicle.setModel("City");
        vehicle.setYear((short) 2020);
        vehicle.setMileage(62100);
        return vehicle;
    }

    private Account account(int customerId) {
        Account account = new Account();
        account.setId(1);
        account.setUsername("khach");
        account.setPasswordHash("hash");
        account.setRole(AccountRole.CUSTOMER);
        account.setActive(true);
        account.setCustomerId(customerId);
        return account;
    }
}
