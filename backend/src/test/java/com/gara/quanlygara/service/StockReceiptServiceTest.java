// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.ImportRequest;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.entity.StockReceipt;
import com.gara.quanlygara.entity.StockReceiptItem;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import com.gara.quanlygara.repository.StockReceiptItemRepository;
import com.gara.quanlygara.repository.StockReceiptRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.transaction.annotation.Transactional;

import java.lang.reflect.Method;
import java.math.BigDecimal;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StockReceiptServiceTest {

    @Mock
    private StockReceiptRepository receiptRepository;
    @Mock
    private StockReceiptItemRepository itemRepository;
    @Mock
    private SparePartRepository sparePartRepository;
    @Mock
    private StockMovementRepository movementRepository;

    private StockReceiptService service;

    @BeforeEach
    void setUp() {
        StockLedger ledger = new StockLedger(sparePartRepository, movementRepository);
        service = new StockReceiptService(receiptRepository, itemRepository, sparePartRepository, ledger);
        lenient().when(sparePartRepository.updateStockQuantity(anyInt(), anyInt())).thenReturn(1);
        lenient().when(movementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(itemRepository.save(any(StockReceiptItem.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(receiptRepository.saveAndFlush(any(StockReceipt.class))).thenAnswer(call -> {
            StockReceipt receipt = call.getArgument(0);
            receipt.setId(3);
            return receipt;
        });
    }

    @Test
    void importIncreasesStockExactlyOnceAndRecordsMovement() {
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, "Bugi")));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(12));
        when(itemRepository.findByReceiptId(3)).thenReturn(List.of(item(3, 5, 8, "100000.00")));

        var response = service.create(request(new ImportRequest.Item(5, 8, new BigDecimal("100000"))), 7);

        verify(sparePartRepository, times(1)).updateStockQuantity(5, 20);
        ArgumentCaptor<StockMovement> movement = ArgumentCaptor.forClass(StockMovement.class);
        verify(movementRepository, times(1)).save(movement.capture());
        assertEquals("NHAP", movement.getValue().getType());
        assertEquals(8, movement.getValue().getQuantity());
        assertEquals(12, movement.getValue().getQuantityBefore());
        assertEquals(20, movement.getValue().getQuantityAfter());
        assertEquals(3, movement.getValue().getReceiptId());
        assertEquals(3, response.id());
        assertEquals(7, response.warehouseStaffId());
        assertEquals(new BigDecimal("800000.00"), response.totalAmount());
        assertEquals("Bugi", response.items().get(0).partName());
    }

    @Test
    void importRejectsUnknownPartWithoutWritingAnything() {
        when(sparePartRepository.findById(99)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class,
                () -> service.create(request(new ImportRequest.Item(99, 1, BigDecimal.ONE)), 7));
        verify(receiptRepository, never()).saveAndFlush(any(StockReceipt.class));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void importRejectsDuplicatePartInTheSameReceipt() {
        assertThrows(BadRequestException.class, () -> service.create(request(
                new ImportRequest.Item(5, 1, BigDecimal.ONE), new ImportRequest.Item(5, 2, BigDecimal.ONE)), 7));
        verify(receiptRepository, never()).saveAndFlush(any(StockReceipt.class));
    }

    @Test
    void importRejectsQuantityThatOverflowsStock() {
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, "Bugi")));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(Integer.MAX_VALUE));

        assertThrows(BadRequestException.class,
                () -> service.create(request(new ImportRequest.Item(5, 1, BigDecimal.ONE)), 7));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void importFailureInLedgerPropagatesSoTheTransactionRollsBack() throws Exception {
        when(sparePartRepository.findById(5)).thenReturn(Optional.of(part(5, "Bugi")));
        when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(1));
        when(sparePartRepository.updateStockQuantity(5, 2)).thenReturn(0);

        assertThrows(ConflictException.class,
                () -> service.create(request(new ImportRequest.Item(5, 1, BigDecimal.ONE)), 7));
        // Không có try/catch nuốt lỗi và phương thức ghi chạy trong @Transactional => rollback toàn bộ.
        Method create = StockReceiptService.class.getMethod("create", ImportRequest.class, Integer.class);
        assertNotNull(create.getAnnotation(Transactional.class));
    }

    @Test
    void getRejectsMissingReceipt() {
        when(receiptRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> service.get(404));
    }

    private ImportRequest request(ImportRequest.Item... items) {
        return new ImportRequest("  Công ty ABC ", null, null, List.of(items));
    }

    private SparePart part(int id, String name) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setUnitPrice(new BigDecimal("180000.00"));
        part.setMinStockLevel(5);
        return part;
    }

    private StockReceiptItem item(int receiptId, int partId, int quantity, String price) {
        StockReceiptItem item = new StockReceiptItem();
        item.setReceiptId(receiptId);
        item.setPartId(partId);
        item.setQuantity(quantity);
        item.setUnitPrice(new BigDecimal(price));
        return item;
    }
}
