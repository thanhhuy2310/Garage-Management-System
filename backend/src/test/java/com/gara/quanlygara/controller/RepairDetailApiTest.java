// TV3-TUAN7
package com.gara.quanlygara.controller;

import com.gara.quanlygara.entity.RepairPartItem;
import com.gara.quanlygara.entity.RepairServiceItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.repository.RepairDetailRow;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
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
import com.gara.quanlygara.repository.InventoryCheckItemRepository;
import com.gara.quanlygara.repository.InventoryCheckRepository;
import com.gara.quanlygara.repository.StockIssueItemRepository;
import com.gara.quanlygara.repository.StockIssueRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import com.gara.quanlygara.repository.StockReceiptItemRepository;
import com.gara.quanlygara.repository.StockReceiptRepository;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.security.test.context.support.WithMockUser;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.util.ReflectionTestUtils;
import org.springframework.test.web.servlet.MockMvc;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.http.MediaType.APPLICATION_JSON;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
class RepairDetailApiTest {

    private static final String PART_BODY = "{\"type\":\"SPARE_PART\",\"itemId\":5,\"quantity\":2}";

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

    @MockitoBean
    private InventoryCheckItemRepository inventoryCheckItemRepository;

    @MockitoBean
    private InventoryCheckRepository inventoryCheckRepository;

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

    @Test
    void listRejectsRequestWithoutJwt() throws Exception {
        mockMvc.perform(get("/api/repair-orders/1/details")).andExpect(status().isUnauthorized());
    }

    @Test
    @WithMockUser(roles = "CUSTOMER")
    void customerCannotReadDetails() throws Exception {
        mockMvc.perform(get("/api/repair-orders/1/details")).andExpect(status().isForbidden());
    }

    @Test
    @WithMockUser(roles = "TECHNICIAN")
    void technicianCanReadDetailsWithTotals() throws Exception {
        stubOrder(1, "DANG_SUA");
        when(repairServiceItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Kiểm tra phanh", 1, "300000.00")));
        when(repairPartItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 4, "180000.00")));

        mockMvc.perform(get("/api/repair-orders/1/details"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.items.length()").value(2))
                .andExpect(jsonPath("$.data.items[1].lineTotal").value(720000.0))
                .andExpect(jsonPath("$.data.totalAmount").value(1020000.0))
                .andExpect(jsonPath("$.data.editable").value(true));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void listReturns404ForUnknownRepairOrder() throws Exception {
        when(repairServiceItemRepository.findRepairOrderStatus(99)).thenReturn(Optional.empty());

        mockMvc.perform(get("/api/repair-orders/99/details"))
                .andExpect(status().isNotFound())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    @WithMockUser(roles = "MANAGER")
    void getOneItemByTypeAndId() throws Exception {
        stubOrder(1, "DANG_SUA");
        when(repairServiceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(repairPartItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 4, "180000.00")));

        mockMvc.perform(get("/api/repair-orders/1/details/spare-part/5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.itemName").value("Bugi"));
        mockMvc.perform(get("/api/repair-orders/1/details/service/5"))
                .andExpect(status().isNotFound());
        mockMvc.perform(get("/api/repair-orders/1/details/labor/5"))
                .andExpect(status().isBadRequest());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createPartReturns201AndDoesNotWriteStock() throws Exception {
        stubOrder(1, "DANG_SUA");
        SparePart part = sparePart(5, 7);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part));
        when(repairPartItemRepository.existsById(new RepairPartItem.Key(1, 5))).thenReturn(false);
        when(repairServiceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(repairPartItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 2, "180000.00")));

        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.data.type").value("SPARE_PART"))
                .andExpect(jsonPath("$.data.lineTotal").value(360000.0));

        verify(sparePartRepository, never()).save(any(SparePart.class));
        verify(sparePartRepository, never()).saveAndFlush(any(SparePart.class));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns409ForDuplicateLine() throws Exception {
        stubOrder(1, "DANG_SUA");
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(sparePart(5, 7)));
        when(repairPartItemRepository.existsById(new RepairPartItem.Key(1, 5))).thenReturn(true);

        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns409ForClosedOrder() throws Exception {
        stubOrder(3, "HOAN_TAT");

        mockMvc.perform(post("/api/repair-orders/3/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isConflict());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns404ForUnknownRepairOrderServiceAndPart() throws Exception {
        when(repairServiceItemRepository.findRepairOrderStatus(99)).thenReturn(Optional.empty());
        mockMvc.perform(post("/api/repair-orders/99/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isNotFound());

        stubOrder(1, "DANG_SUA");
        when(repairServiceItemRepository.findServiceCatalogPrice(77)).thenReturn(Optional.empty());
        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON)
                        .content("{\"type\":\"SERVICE\",\"itemId\":77,\"quantity\":1}"))
                .andExpect(status().isNotFound());

        when(sparePartRepository.findById(5)).thenReturn(Optional.empty());
        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isNotFound());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void createReturns400ForInvalidQuantityAndPrice() throws Exception {
        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON)
                        .content("{\"type\":\"SERVICE\",\"itemId\":1,\"quantity\":0,\"unitPrice\":-1}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.data.quantity").exists())
                .andExpect(jsonPath("$.data.unitPrice").exists());
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void updateReturns200() throws Exception {
        stubOrder(1, "DANG_SUA");
        RepairServiceItem item = new RepairServiceItem();
        item.setRepairOrderId(1);
        item.setServiceId(3);
        item.setQuantity(1);
        item.setUnitPrice(new BigDecimal("300000.00"));
        when(repairServiceItemRepository.findById(new RepairServiceItem.Key(1, 3))).thenReturn(Optional.of(item));
        when(repairServiceItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Kiểm tra phanh", 3, "300000.00")));
        when(repairPartItemRepository.findDetailRows(1)).thenReturn(List.of());

        mockMvc.perform(put("/api/repair-orders/1/details/service/3").contentType(APPLICATION_JSON)
                        .content("{\"quantity\":3}"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.data.lineTotal").value(900000.0));
    }

    @Test
    @WithMockUser(roles = "RECEPTIONIST")
    void deleteReturns200AndRemovesOnlyTheLine() throws Exception {
        stubOrder(1, "DANG_SUA");
        RepairPartItem item = new RepairPartItem();
        item.setRepairOrderId(1);
        item.setSparePartId(5);
        item.setQuantity(2);
        item.setUnitPrice(new BigDecimal("180000.00"));
        when(repairPartItemRepository.findById(new RepairPartItem.Key(1, 5))).thenReturn(Optional.of(item));

        mockMvc.perform(delete("/api/repair-orders/1/details/spare-part/5"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(repairPartItemRepository).delete(item);
        verify(sparePartRepository, never()).saveAndFlush(any(SparePart.class));
    }

    @Test
    @WithMockUser(roles = "TECHNICIAN")
    void technicianCannotModifyDetails() throws Exception {
        mockMvc.perform(post("/api/repair-orders/1/details").contentType(APPLICATION_JSON).content(PART_BODY))
                .andExpect(status().isForbidden());
        mockMvc.perform(put("/api/repair-orders/1/details/service/3").contentType(APPLICATION_JSON)
                        .content("{\"quantity\":1}"))
                .andExpect(status().isForbidden());
        mockMvc.perform(delete("/api/repair-orders/1/details/service/3")).andExpect(status().isForbidden());
    }

    private void stubOrder(int id, String orderStatus) {
        when(repairServiceItemRepository.findRepairOrderStatus(id)).thenReturn(Optional.of(orderStatus));
    }

    private SparePart sparePart(int id, int stock) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName("Bugi");
        part.setUnitPrice(new BigDecimal("180000.00"));
        part.setMinStockLevel(5);
        ReflectionTestUtils.setField(part, "stockQuantity", stock);
        return part;
    }

    private RepairDetailRow row(int itemId, String name, int quantity, String price) {
        return new RepairDetailRow() {
            @Override
            public Integer getItemId() {
                return itemId;
            }

            @Override
            public String getItemName() {
                return name;
            }

            @Override
            public Integer getQuantity() {
                return quantity;
            }

            @Override
            public BigDecimal getUnitPrice() {
                return new BigDecimal(price);
            }

            @Override
            public String getItemStatus() {
                return null;
            }
        };
    }
}
