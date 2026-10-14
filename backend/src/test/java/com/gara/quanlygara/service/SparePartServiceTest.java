// TV3-TUAN7
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.sparepart.SparePartRequest;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.SparePartRepository;
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
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SparePartServiceTest {

    @Mock
    private SparePartRepository sparePartRepository;

    private SparePartService sparePartService;

    @BeforeEach
    void setUp() {
        sparePartService = new SparePartService(sparePartRepository);
    }

    @Test
    void createNormalizesAndPersistsPart() {
        when(sparePartRepository.countWarehouse(1)).thenReturn(1L);
        when(sparePartRepository.saveAndFlush(any(SparePart.class))).thenAnswer(invocation -> {
            SparePart part = invocation.getArgument(0);
            part.setId(8);
            return part;
        });

        var response = sparePartService.create(
                new SparePartRequest(1, "  Lọc   dầu  động cơ ", "   ", new BigDecimal("180000"), null));

        assertEquals(8, response.id());
        assertEquals("Lọc dầu động cơ", response.name());
        assertNull(response.manufacturer());
        assertEquals(new BigDecimal("180000.00"), response.unitPrice());
        assertEquals(0, response.minStockLevel());
        // Phụ tùng mới: tồn mặc định 0, không do danh mục quyết định.
        assertEquals(0, response.stockQuantity());
    }

    @Test
    void createRejectsMissingWarehouse() {
        when(sparePartRepository.countWarehouse(99)).thenReturn(0L);

        assertThrows(ResourceNotFoundException.class, () -> sparePartService.create(request(99, "Bugi")));
        verify(sparePartRepository, never()).saveAndFlush(any(SparePart.class));
    }

    @Test
    void getByIdReturnsPartWithStock() {
        when(sparePartRepository.findById(3)).thenReturn(Optional.of(part(3, "Bugi", 12)));

        var response = sparePartService.getById(3);

        assertEquals("Bugi", response.name());
        assertEquals(12, response.stockQuantity());
    }

    @Test
    void getByIdRejectsMissingPart() {
        when(sparePartRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> sparePartService.getById(404));
    }

    @Test
    void getAllUsesPaginationAndSortsByName() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(sparePartRepository.findAll(captor.capture())).thenReturn(
                new PageImpl<>(List.of(part(1, "Bugi", 5)), PageRequest.of(1, 5), 11));

        var response = sparePartService.getAll(1, 5, null);

        assertEquals(1, response.items().size());
        assertEquals(1, response.page());
        assertEquals(11, response.totalElements());
        assertEquals(3, response.totalPages());
        assertEquals(1, captor.getValue().getPageNumber());
        assertEquals(5, captor.getValue().getPageSize());
        assertEquals("name", captor.getValue().getSort().iterator().next().getProperty());
    }

    @Test
    void getAllClampsPageAndSize() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(sparePartRepository.findAll(captor.capture())).thenReturn(new PageImpl<>(List.of()));

        sparePartService.getAll(-2, 1000, "  ");

        assertEquals(0, captor.getValue().getPageNumber());
        assertEquals(100, captor.getValue().getPageSize());
    }

    @Test
    void getAllSearchesByNameOrManufacturer() {
        when(sparePartRepository.findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                eq("loc"), eq("loc"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(part(1, "Lọc dầu", 5))));

        var response = sparePartService.getAll(0, 10, "  loc ");

        assertEquals(1, response.items().size());
        verify(sparePartRepository, never()).findAll(any(Pageable.class));
    }

    @Test
    void getAllNumericKeywordMatchesPartIdOrText() {
        when(sparePartRepository.findByIdOrNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                eq(5), eq("5"), eq("5"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(part(5, "Bugi", 12))));

        var response = sparePartService.getAll(0, 10, " 5 ");

        assertEquals(1, response.items().size());
        assertEquals(5, response.items().get(0).id());
        verify(sparePartRepository, never()).findAll(any(Pageable.class));
        verify(sparePartRepository, never()).findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                any(), any(), any(Pageable.class));
    }

    @Test
    void getAllNonNumericOrOversizedKeywordSearchesTextOnly() {
        when(sparePartRepository.findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                any(), any(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of()));

        sparePartService.getAll(0, 10, "5W-30");
        sparePartService.getAll(0, 10, "99999999999");

        verify(sparePartRepository, never()).findByIdOrNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                any(), any(), any(), any(Pageable.class));
    }

    @Test
    void getAllNumericSearchKeepsPaginationAndSorting() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(sparePartRepository.findByIdOrNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                eq(7), eq("7"), eq("7"), captor.capture()))
                .thenReturn(new PageImpl<>(List.of(part(7, "Bugi", 1)), PageRequest.of(2, 5), 11));

        var response = sparePartService.getAll(2, 5, "7");

        assertEquals(2, response.page());
        assertEquals(11, response.totalElements());
        assertEquals(3, response.totalPages());
        assertEquals(2, captor.getValue().getPageNumber());
        assertEquals(5, captor.getValue().getPageSize());
        assertEquals("name", captor.getValue().getSort().iterator().next().getProperty());
    }

    @Test
    void updateChangesCatalogFieldsButNeverTouchesStock() {
        SparePart part = part(3, "Bugi", 12);
        when(sparePartRepository.findById(3)).thenReturn(Optional.of(part));
        when(sparePartRepository.saveAndFlush(part)).thenReturn(part);

        var response = sparePartService.update(3, new SparePartRequest(
                1, "Bugi Iridium", "NGK", new BigDecimal("210000"), 6));

        assertEquals("Bugi Iridium", response.name());
        assertEquals(new BigDecimal("210000.00"), response.unitPrice());
        assertEquals(6, response.minStockLevel());
        assertEquals(12, response.stockQuantity());
        assertEquals(12, part.getStockQuantity());
    }

    @Test
    void updateChecksWarehouseOnlyWhenItChanges() {
        when(sparePartRepository.findById(3)).thenReturn(Optional.of(part(3, "Bugi", 12)));
        when(sparePartRepository.countWarehouse(2)).thenReturn(0L);

        assertThrows(ResourceNotFoundException.class, () -> sparePartService.update(3, request(2, "Bugi")));
    }

    @Test
    void updateRejectsMissingPart() {
        when(sparePartRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> sparePartService.update(404, request(1, "Bugi")));
    }

    @Test
    void warehousesAreMappedFromTheKhoTable() {
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

        var response = sparePartService.getWarehouses();

        assertEquals(1, response.size());
        assertEquals("Kho phụ tùng chính", response.get(0).name());
    }

    private SparePartRequest request(int warehouseId, String name) {
        return new SparePartRequest(warehouseId, name, "NGK", new BigDecimal("180000"), 5);
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
