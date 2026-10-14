// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.StockStatus;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.test.util.ReflectionTestUtils;

import java.math.BigDecimal;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class InventoryServiceTest {

    @Mock
    private SparePartRepository sparePartRepository;
    @Mock
    private StockMovementRepository movementRepository;

    private InventoryService service;

    @BeforeEach
    void setUp() {
        service = new InventoryService(sparePartRepository, movementRepository);
    }

    @Test
    void stockStatusIsDerivedFromStockAndMinimum() {
        assertEquals(StockStatus.HET_HANG, StockStatus.of(0, 5));
        assertEquals(StockStatus.HET_HANG, StockStatus.of(0, 0));
        assertEquals(StockStatus.SAP_HET, StockStatus.of(1, 5));
        assertEquals(StockStatus.SAP_HET, StockStatus.of(5, 5));
        assertEquals(StockStatus.CON_HANG, StockStatus.of(6, 5));
    }

    @Test
    void getStockMapsStatusAndPassesNormalizedFilters() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(sparePartRepository.searchInventory(eq("bugi"), eq("SAP_HET"), captor.capture()))
                .thenReturn(new PageImpl<>(List.of(part(1, "Bugi", 3, 5)), PageRequest.of(0, 10), 1));
        when(sparePartRepository.countAtOrBelowMinimum()).thenReturn(4L);

        var response = service.getStock(0, 10, "  bugi ", "sap_het");

        assertEquals(StockStatus.SAP_HET, response.items().get(0).stockStatus());
        assertEquals(3, response.items().get(0).stockQuantity());
        assertEquals(4, response.lowStockCount());
        assertEquals("name", captor.getValue().getSort().iterator().next().getProperty());
    }

    @Test
    void getStockWithoutFiltersUsesAllAndEmptyKeyword() {
        when(sparePartRepository.searchInventory(eq(""), eq("ALL"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        service.getStock(-1, 1000, null, null);

        verify(sparePartRepository).searchInventory(eq(""), eq("ALL"), any(Pageable.class));
    }

    @Test
    void getStockRejectsUnknownStatus() {
        assertThrows(BadRequestException.class, () -> service.getStock(0, 10, null, "KHONG_CO"));
        verify(sparePartRepository, never()).searchInventory(any(), any(), any(Pageable.class));
    }

    @Test
    void movementFiltersAreNormalizedAndValidated() {
        when(movementRepository.search(eq(0), eq("ALL"), any(Pageable.class))).thenReturn(new PageImpl<>(List.of()));
        when(movementRepository.search(eq(5), eq("XUAT"), any(Pageable.class))).thenReturn(new PageImpl<>(List.of()));

        service.getMovements(0, 20, null, null);
        service.getMovements(0, 20, 5, " xuat ");

        verify(movementRepository).search(eq(0), eq("ALL"), any(Pageable.class));
        verify(movementRepository).search(eq(5), eq("XUAT"), any(Pageable.class));
        assertThrows(BadRequestException.class, () -> service.getMovements(0, 20, null, "HUY"));
    }

    private SparePart part(int id, String name, int stock, int min) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setUnitPrice(new BigDecimal("1.00"));
        part.setMinStockLevel(min);
        ReflectionTestUtils.setField(part, "stockQuantity", stock);
        return part;
    }
}
