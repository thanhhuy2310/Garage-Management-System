// TV3-TUAN7
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.repairdetail.RepairDetailCreateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailType;
import com.gara.quanlygara.dto.repairdetail.RepairDetailUpdateRequest;
import com.gara.quanlygara.entity.RepairPartItem;
import com.gara.quanlygara.entity.RepairServiceItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairDetailRow;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RepairDetailServiceTest {

    @Mock
    private RepairServiceItemRepository serviceItemRepository;

    @Mock
    private RepairPartItemRepository partItemRepository;

    @Mock
    private SparePartRepository sparePartRepository;

    private RepairDetailService service;

    @BeforeEach
    void setUp() {
        service = new RepairDetailService(serviceItemRepository, partItemRepository, sparePartRepository);
    }

    @Test
    void getAllReturnsServicesPartsAndTotals() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Kiểm tra phanh", 2, "300000.00", "HOAN_TAT")));
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 4, "180000.00", null)));

        var response = service.getAll(1);

        assertEquals(2, response.items().size());
        assertEquals(RepairDetailType.SERVICE, response.items().get(0).type());
        assertEquals(new BigDecimal("600000.00"), response.items().get(0).lineTotal());
        assertEquals(new BigDecimal("720000.00"), response.items().get(1).lineTotal());
        assertEquals(new BigDecimal("600000.00"), response.serviceTotal());
        assertEquals(new BigDecimal("720000.00"), response.partsTotal());
        assertEquals(new BigDecimal("1320000.00"), response.totalAmount());
        assertTrue(response.editable());
    }

    @Test
    void getAllRejectsMissingRepairOrder() {
        when(serviceItemRepository.findRepairOrderStatus(99)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.getAll(99));
    }

    @Test
    void completedOrderIsReadOnly() {
        openOrder(3, "HOAN_TAT");
        when(serviceItemRepository.findDetailRows(3)).thenReturn(List.of());
        when(partItemRepository.findDetailRows(3)).thenReturn(List.of());

        assertFalse(service.getAll(3).editable());
    }

    @Test
    void getByIdReturnsMatchingItemOnly() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Kiểm tra phanh", 1, "300000.00", null)));
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(3, "Bugi", 1, "180000.00", null)));

        assertEquals("Bugi", service.get(1, RepairDetailType.SPARE_PART, 3).itemName());
        assertEquals("Kiểm tra phanh", service.get(1, RepairDetailType.SERVICE, 3).itemName());
        assertThrows(ResourceNotFoundException.class, () -> service.get(1, RepairDetailType.SERVICE, 9));
    }

    @Test
    void createPartLineUsesCatalogPriceAndNeverChangesStock() {
        openOrder(1, "DANG_SUA");
        SparePart part = sparePart(5, "Bugi", "180000.00", 7);
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part));
        when(partItemRepository.existsById(new RepairPartItem.Key(1, 5))).thenReturn(false);
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 2, "180000.00", null)));
        ArgumentCaptor<RepairPartItem> captor = ArgumentCaptor.forClass(RepairPartItem.class);

        var response = service.create(1, new RepairDetailCreateRequest(RepairDetailType.SPARE_PART, 5, 2, null));

        verify(partItemRepository).saveAndFlush(captor.capture());
        assertEquals(new BigDecimal("180000.00"), captor.getValue().getUnitPrice());
        assertEquals(2, captor.getValue().getQuantity());
        assertEquals(new BigDecimal("360000.00"), response.lineTotal());
        // Thêm chi tiết KHÔNG xuất kho, KHÔNG giảm tồn.
        assertEquals(7, part.getStockQuantity());
        verify(sparePartRepository, never()).save(any(SparePart.class));
        verify(sparePartRepository, never()).saveAndFlush(any(SparePart.class));
        verify(sparePartRepository, never()).delete(any(SparePart.class));
    }

    @Test
    void createPartLineKeepsExplicitUnitPrice() {
        openOrder(1, "DANG_SUA");
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(sparePart(5, "Bugi", "180000.00", 7)));
        when(partItemRepository.existsById(new RepairPartItem.Key(1, 5))).thenReturn(false);
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 1, "150000.00", null)));
        ArgumentCaptor<RepairPartItem> captor = ArgumentCaptor.forClass(RepairPartItem.class);

        service.create(1, new RepairDetailCreateRequest(RepairDetailType.SPARE_PART, 5, 1, new BigDecimal("150000")));

        verify(partItemRepository).saveAndFlush(captor.capture());
        assertEquals(new BigDecimal("150000.00"), captor.getValue().getUnitPrice());
    }

    @Test
    void createServiceLineUsesCatalogPrice() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findServiceCatalogPrice(2)).thenReturn(Optional.of(new BigDecimal("1200000.00")));
        when(serviceItemRepository.existsById(new RepairServiceItem.Key(1, 2))).thenReturn(false);
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of(row(2, "Bảo dưỡng", 1, "1200000.00", null)));
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of());
        ArgumentCaptor<RepairServiceItem> captor = ArgumentCaptor.forClass(RepairServiceItem.class);

        var response = service.create(1, new RepairDetailCreateRequest(RepairDetailType.SERVICE, 2, 1, null));

        verify(serviceItemRepository).saveAndFlush(captor.capture());
        assertEquals(new BigDecimal("1200000.00"), captor.getValue().getUnitPrice());
        assertEquals(new BigDecimal("1200000.00"), response.lineTotal());
    }

    @Test
    void createRejectsMissingRepairOrder() {
        when(serviceItemRepository.findRepairOrderStatus(99)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.create(
                99, new RepairDetailCreateRequest(RepairDetailType.SERVICE, 2, 1, null)));
    }

    @Test
    void createRejectsMissingService() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findServiceCatalogPrice(77)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.create(
                1, new RepairDetailCreateRequest(RepairDetailType.SERVICE, 77, 1, null)));
        verify(serviceItemRepository, never()).saveAndFlush(any(RepairServiceItem.class));
    }

    @Test
    void createRejectsMissingSparePart() {
        openOrder(1, "DANG_SUA");
        when(sparePartRepository.findById(77)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.create(
                1, new RepairDetailCreateRequest(RepairDetailType.SPARE_PART, 77, 1, null)));
        verify(partItemRepository, never()).saveAndFlush(any(RepairPartItem.class));
    }

    @Test
    void createRejectsDuplicateLine() {
        openOrder(1, "DANG_SUA");
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(sparePart(5, "Bugi", "180000.00", 7)));
        when(partItemRepository.existsById(new RepairPartItem.Key(1, 5))).thenReturn(true);

        assertThrows(ConflictException.class, () -> service.create(
                1, new RepairDetailCreateRequest(RepairDetailType.SPARE_PART, 5, 1, null)));
        verify(partItemRepository, never()).saveAndFlush(any(RepairPartItem.class));
    }

    @Test
    void closedOrderRejectsCreateUpdateAndDelete() {
        openOrder(3, "HOAN_TAT");

        assertThrows(ConflictException.class, () -> service.create(
                3, new RepairDetailCreateRequest(RepairDetailType.SERVICE, 2, 1, null)));
        assertThrows(ConflictException.class, () -> service.update(
                3, RepairDetailType.SERVICE, 2, new RepairDetailUpdateRequest(1, null)));
        assertThrows(ConflictException.class, () -> service.delete(3, RepairDetailType.SPARE_PART, 5));
    }

    @Test
    void updateChangesQuantityAndKeepsPriceWhenOmitted() {
        openOrder(1, "DANG_SUA");
        RepairPartItem item = partItem(1, 5, 2, "180000.00");
        when(partItemRepository.findById(new RepairPartItem.Key(1, 5))).thenReturn(Optional.of(item));
        when(serviceItemRepository.findDetailRows(1)).thenReturn(List.of());
        when(partItemRepository.findDetailRows(1)).thenReturn(List.of(row(5, "Bugi", 6, "180000.00", null)));

        var response = service.update(1, RepairDetailType.SPARE_PART, 5, new RepairDetailUpdateRequest(6, null));

        assertEquals(6, item.getQuantity());
        assertEquals(new BigDecimal("180000.00"), item.getUnitPrice());
        assertEquals(new BigDecimal("1080000.00"), response.lineTotal());
        verify(sparePartRepository, never()).saveAndFlush(any(SparePart.class));
    }

    @Test
    void updateRejectsMissingLine() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findById(new RepairServiceItem.Key(1, 9))).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.update(
                1, RepairDetailType.SERVICE, 9, new RepairDetailUpdateRequest(1, null)));
    }

    @Test
    void deleteRemovesOnlyTheDetailLineAndNeverTouchesStock() {
        openOrder(1, "DANG_SUA");
        RepairPartItem item = partItem(1, 5, 2, "180000.00");
        when(partItemRepository.findById(new RepairPartItem.Key(1, 5))).thenReturn(Optional.of(item));

        service.delete(1, RepairDetailType.SPARE_PART, 5);

        verify(partItemRepository).delete(item);
        verify(sparePartRepository, never()).findById(any());
        verify(sparePartRepository, never()).save(any(SparePart.class));
    }

    @Test
    void deleteRejectsMissingLine() {
        openOrder(1, "DANG_SUA");
        when(serviceItemRepository.findById(new RepairServiceItem.Key(1, 9))).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.delete(1, RepairDetailType.SERVICE, 9));
    }

    private void openOrder(int id, String status) {
        when(serviceItemRepository.findRepairOrderStatus(id)).thenReturn(Optional.of(status));
    }

    private SparePart sparePart(int id, String name, String price, int stock) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setUnitPrice(new BigDecimal(price));
        part.setMinStockLevel(5);
        ReflectionTestUtils.setField(part, "stockQuantity", stock);
        return part;
    }

    private RepairPartItem partItem(int orderId, int partId, int quantity, String price) {
        RepairPartItem item = new RepairPartItem();
        item.setRepairOrderId(orderId);
        item.setSparePartId(partId);
        item.setQuantity(quantity);
        item.setUnitPrice(new BigDecimal(price));
        return item;
    }

    private RepairDetailRow row(int itemId, String name, int quantity, String price, String status) {
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
                return status;
            }
        };
    }
}
