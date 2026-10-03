// TV3-TUAN7
package com.gara.quanlygara.controller;

import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.AccountRepository;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.EmployeeRepository;
import com.gara.quanlygara.repository.GarageServiceRepository;
import com.gara.quanlygara.repository.RepairOrderRepository;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
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
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
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
class SparePartApiTest {

    private static final String PART_JSON = """
            {"warehouseId":1,"name":"Bugi Iridium","manufacturer":"NGK","unitPrice":210000,"minStockLevel":6}
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
    private GarageServiceRepository garageServiceRepository;

    @MockitoBean
    private RepairOrderRepository repairOrderRepository;

    @MockitoBean
    private RepairPartItemRepository repairPartItemRepository;

    @MockitoBean
    private RepairServiceItemRepository repairServiceItemRepository;

    @MockitoBean
    private SparePartRepository sparePartRepository;

    @MockitoBean
    private TechnicianAssignmentRepository technicianAssignmentRepository;

    @MockitoBean
    private TechnicianRepository technicianRepository;

    @MockitoBean
    private VehicleRepository vehicleRepository;

    @Test
    void listRejectsRequestWithoutJwt() throws Exception {
        mockMvc.perform(get("/api/spare-parts"))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "CUSTOMER")
    void customerCannotReadCatalogApi() throws Exception {
        mockMvc.perform(get("/api/spare-parts")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void warehouseCanListWithPaginationAndSeesStock() throws Exception {
        when(sparePartRepository.findAll(any(Pageable.class))).thenReturn(
                new PageImpl<>(List.of(part(1, "Bugi", 12)), PageRequest.of(0, 10), 1));

        mockMvc.perform(get("/api/spare-parts").param("page", "0").param("size", "10"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].name").value("Bugi"))
                .andExpect(jsonPath("$.data.items[0].stockQuantity").value(12))
                .andExpect(jsonPath("$.data.totalElements").value(1));
    }

    @Test
    @WithMockUser(roles = "TECHNICIAN")
    void searchFiltersByNameOrManufacturer() throws Exception {
        when(sparePartRepository.findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                eq("bugi"), eq("bugi"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(part(2, "Bugi", 3))));

        mockMvc.perform(get("/api/spare-parts").param("search", "bugi"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items[0].id").value(2));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void getByIdReturnsPart() throws Exception {
        when(sparePartRepository.findById(2)).thenReturn(Optional.of(part(2, "Bugi", 3)));

        mockMvc.perform(get("/api/spare-parts/2"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Bugi"));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void getByIdReturns404WhenMissing() throws Exception {
        when(sparePartRepository.findById(404)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/spare-parts/404"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void warehousesAreListedForTheForm() throws Exception {
        SparePartRepository.WarehouseView view = new SparePartRepository.WarehouseView() {
            @Override
            public Integer getId() {
                return 1;
            }

            @Override
            public String getName() {
                return "Kho phụ tùng chính";
            }
        };
        when(sparePartRepository.findWarehouses()).thenReturn(List.of(view));

        mockMvc.perform(get("/api/spare-parts/warehouses"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data[0].name").value("Kho phụ tùng chính"));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void createReturns201() throws Exception {
        when(sparePartRepository.countWarehouse(1)).thenReturn(1L);
        when(sparePartRepository.saveAndFlush(any(SparePart.class))).thenAnswer(invocation -> {
            SparePart part = invocation.getArgument(0);
            part.setId(9);
            return part;
        });

        mockMvc.perform(post("/api/spare-parts").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.id").value(9))
                .andExpect(jsonPath("$.data.stockQuantity").value(0));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void createReturns404ForUnknownWarehouse() throws Exception {
        when(sparePartRepository.countWarehouse(1)).thenReturn(0L);

        mockMvc.perform(post("/api/spare-parts").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void createReturns400ForInvalidBody() throws Exception {
        mockMvc.perform(post("/api/spare-parts").contentType(APPLICATION_JSON)
                        .content("{\"warehouseId\":1,\"name\":\"  \",\"unitPrice\":-5,\"minStockLevel\":-1}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.name").exists())
                .andExpect(jsonPath("$.data.unitPrice").exists())
                .andExpect(jsonPath("$.data.minStockLevel").exists());
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void updateReturns200AndKeepsStock() throws Exception {
        when(sparePartRepository.findById(3)).thenReturn(Optional.of(part(3, "Bugi", 12)));
        when(sparePartRepository.saveAndFlush(any(SparePart.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(sparePartRepository.countWarehouse(1)).thenReturn(1L);

        mockMvc.perform(put("/api/spare-parts/3").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.name").value("Bugi Iridium"))
                .andExpect(jsonPath("$.data.stockQuantity").value(12));
    }

    @Test
    @WithMockUser(roles = "WAREHOUSE")
    void updateReturns404WhenMissing() throws Exception {
        when(sparePartRepository.findById(404)).thenReturn(Optional.empty());

        mockMvc.perform(put("/api/spare-parts/404").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void receptionistCanReadButNotWriteCatalog() throws Exception {
        when(sparePartRepository.findAll(any(Pageable.class))).thenReturn(new PageImpl<>(List.of()));

        mockMvc.perform(get("/api/spare-parts")).andExpect(status().isOk());
        mockMvc.perform(post("/api/spare-parts").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isForbidden());
        mockMvc.perform(put("/api/spare-parts/3").contentType(APPLICATION_JSON).content(PART_JSON))
                .andExpect(status().isForbidden());
    }

    @Test
    void swaggerDocumentationListsSparePartApi() throws Exception {
        mockMvc.perform(get("/v3/api-docs"))
                .andExpect(status().isOk())
                .andExpect(content().string(containsString("/api/spare-parts")));
    }

    private SparePart part(int id, String name, int stock) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setManufacturer("NGK");
        part.setUnitPrice(new BigDecimal("180000.00"));
        part.setMinStockLevel(5);
        ReflectionTestUtils.setField(part, "stockQuantity", stock);
        return part;
    }
}
