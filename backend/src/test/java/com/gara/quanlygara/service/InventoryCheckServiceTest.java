// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.CheckActualRequest;
import com.gara.quanlygara.dto.warehouse.CheckCreateRequest;
import com.gara.quanlygara.entity.InventoryCheck;
import com.gara.quanlygara.entity.InventoryCheckItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.InventoryCheckItemRepository;
import com.gara.quanlygara.repository.InventoryCheckRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
class InventoryCheckServiceTest {

    @Mock
    private InventoryCheckRepository checkRepository;
    @Mock
    private InventoryCheckItemRepository itemRepository;
    @Mock
    private SparePartRepository sparePartRepository;
    @Mock
    private StockMovementRepository movementRepository;

    private InventoryCheckService service;
    private InventoryCheck check;
    private final List<InventoryCheckItem> store = new ArrayList<>();

    @BeforeEach
    void setUp() {
        StockLedger ledger = new StockLedger(sparePartRepository, movementRepository);
        service = new InventoryCheckService(checkRepository, itemRepository, sparePartRepository, ledger);

        lenient().when(sparePartRepository.updateStockQuantity(anyInt(), anyInt())).thenReturn(1);
        lenient().when(movementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(checkRepository.saveAndFlush(any(InventoryCheck.class))).thenAnswer(call -> {
            InventoryCheck saved = call.getArgument(0);
            if (saved.getId() == null) saved.setId(1);
            check = saved;
            return saved;
        });
        lenient().when(checkRepository.findById(1)).thenAnswer(call -> Optional.ofNullable(check));
        lenient().when(itemRepository.save(any(InventoryCheckItem.class))).thenAnswer(call -> {
            InventoryCheckItem item = call.getArgument(0);
            if (!store.contains(item)) store.add(item);
            return item;
        });
        lenient().when(itemRepository.saveAndFlush(any(InventoryCheckItem.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(itemRepository.findById(any(InventoryCheckItem.Key.class))).thenAnswer(call -> {
            InventoryCheckItem.Key key = call.getArgument(0);
            return store.stream().filter(i -> new InventoryCheckItem.Key(i.getCheckId(), i.getPartId()).equals(key)).findFirst();
        });
        lenient().when(itemRepository.findByCheckIdOrderByPartId(1)).thenAnswer(call ->
                store.stream().sorted(Comparator.comparing(InventoryCheckItem::getPartId)).toList());
        lenient().when(sparePartRepository.existsById(anyInt())).thenReturn(true);
        lenient().when(sparePartRepository.findAllById(any())).thenReturn(List.of(part(5, "Bugi"), part(6, "Lọc dầu")));
    }

    @Test
    void createSnapshotsSystemStockWithoutChangingIt() {
        lenient().when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));
        lenient().when(sparePartRepository.lockStockQuantity(6)).thenReturn(Optional.of(3));

        var response = service.create(new CheckCreateRequest("Kiểm kê tháng 10", List.of(6, 5)), 7);

        assertEquals("DANG_KIEM_KE", response.status());
        assertEquals(7, response.createdBy());
        assertEquals(2, response.items().size());
        assertEquals(10, response.items().get(0).systemQuantity());
        assertEquals(3, response.items().get(1).systemQuantity());
        assertNull(response.items().get(0).actualQuantity());
        assertNull(response.items().get(0).difference());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void createRejectsDuplicateAndUnknownParts() {
        assertThrows(BadRequestException.class,
                () -> service.create(new CheckCreateRequest(null, List.of(5, 5)), 7));

        lenient().when(sparePartRepository.existsById(99)).thenReturn(false);
        assertThrows(ResourceNotFoundException.class,
                () -> service.create(new CheckCreateRequest(null, List.of(99)), 7));
    }

    @Test
    void partialCountKeepsTheSessionOpen() {
        startSession(10, 3);

        var response = service.setActual(1, 5, new CheckActualRequest(10, null));

        assertEquals("DANG_KIEM_KE", response.status());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void zeroDifferencesCompleteWithoutApprovalAndWithoutStockChange() {
        startSession(10, 3);

        service.setActual(1, 5, new CheckActualRequest(10, null));
        var response = service.setActual(1, 6, new CheckActualRequest(3, null));

        assertEquals("DA_HOAN_TAT", response.status());
        assertNull(response.approvedBy());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
    }

    @Test
    void anyDifferenceWaitsForApprovalAndDoesNotChangeStock() {
        startSession(10, 3);

        service.setActual(1, 5, new CheckActualRequest(7, "Hỏng 3 cái"));
        var response = service.setActual(1, 6, new CheckActualRequest(3, null));

        assertEquals("CHO_PHE_DUYET", response.status());
        assertEquals(-3, response.items().get(0).difference());
        assertEquals("Hỏng 3 cái", response.items().get(0).reason());
        assertFalse(response.items().get(0).adjustmentApproved());
        // Trước khi phê duyệt tồn kho tuyệt đối không đổi.
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
    }

    @Test
    void approveSetsStockToActualAndRecordsKiemKeMovement() {
        startSession(10, 3);
        service.setActual(1, 5, new CheckActualRequest(7, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));
        lenient().when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));

        var response = service.approve(1, "Đồng ý điều chỉnh", 8);

        verify(sparePartRepository, times(1)).updateStockQuantity(5, 7);
        verify(sparePartRepository, never()).updateStockQuantity(6, 3);
        ArgumentCaptor<StockMovement> movement = ArgumentCaptor.forClass(StockMovement.class);
        verify(movementRepository, times(1)).save(movement.capture());
        assertEquals("KIEM_KE", movement.getValue().getType());
        assertEquals(3, movement.getValue().getQuantity());
        assertEquals(10, movement.getValue().getQuantityBefore());
        assertEquals(7, movement.getValue().getQuantityAfter());
        assertEquals("DA_HOAN_TAT", response.status());
        assertEquals(8, response.approvedBy());
        assertTrue(response.items().get(0).adjustmentApproved());
        assertFalse(response.items().get(1).adjustmentApproved());
    }

    @Test
    void approveHandlesSurplusDifference() {
        startSession(10, 3);
        service.setActual(1, 5, new CheckActualRequest(14, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));
        lenient().when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(10));

        service.approve(1, null, 8);

        verify(sparePartRepository).updateStockQuantity(5, 14);
        ArgumentCaptor<StockMovement> movement = ArgumentCaptor.forClass(StockMovement.class);
        verify(movementRepository).save(movement.capture());
        assertEquals(4, movement.getValue().getQuantity());
    }

    @Test
    void approveRejectsWhenStockChangedSinceTheSnapshot() {
        startSession(10, 3);
        service.setActual(1, 5, new CheckActualRequest(7, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));
        lenient().when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(12));

        assertThrows(ConflictException.class, () -> service.approve(1, null, 8));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        assertEquals("CHO_PHE_DUYET", check.getStatus());
    }

    @Test
    void approveOnlyWorksWhileWaitingForApproval() {
        startSession(10, 3);

        assertThrows(ConflictException.class, () -> service.approve(1, null, 8));
        service.setActual(1, 5, new CheckActualRequest(10, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));
        assertThrows(ConflictException.class, () -> service.approve(1, null, 8));
    }

    @Test
    void rejectKeepsStockAndStoresTheReason() {
        startSession(10, 3);
        service.setActual(1, 5, new CheckActualRequest(7, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));

        var response = service.reject(1, "Cần đếm lại", 8);

        assertEquals("DA_TU_CHOI", response.status());
        assertEquals("Cần đếm lại", response.decisionReason());
        assertEquals(8, response.approvedBy());
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
        assertThrows(ConflictException.class, () -> service.approve(1, null, 8));
    }

    @Test
    void rejectRequiresAReason() {
        startSession(10, 3);
        service.setActual(1, 5, new CheckActualRequest(7, null));
        service.setActual(1, 6, new CheckActualRequest(3, null));

        assertThrows(BadRequestException.class, () -> service.reject(1, "   ", 8));
        assertEquals("CHO_PHE_DUYET", check.getStatus());
    }

    @Test
    void actualQuantityCanOnlyBeEnteredWhileCountingAndForPartsInTheSession() {
        startSession(10, 3);

        assertThrows(ResourceNotFoundException.class,
                () -> service.setActual(1, 77, new CheckActualRequest(1, null)));
        assertThrows(BadRequestException.class,
                () -> service.setActual(1, 5, new CheckActualRequest(-1, null)));

        check.setStatus("DA_HOAN_TAT");
        assertThrows(ConflictException.class,
                () -> service.setActual(1, 5, new CheckActualRequest(1, null)));
    }

    private void startSession(int stockOfPart5, int stockOfPart6) {
        lenient().when(sparePartRepository.lockStockQuantity(5)).thenReturn(Optional.of(stockOfPart5));
        lenient().when(sparePartRepository.lockStockQuantity(6)).thenReturn(Optional.of(stockOfPart6));
        service.create(new CheckCreateRequest(null, List.of(5, 6)), 7);
    }

    private SparePart part(int id, String name) {
        SparePart part = new SparePart();
        part.setId(id);
        part.setWarehouseId(1);
        part.setName(name);
        part.setUnitPrice(new BigDecimal("1.00"));
        part.setMinStockLevel(1);
        return part;
    }
}
