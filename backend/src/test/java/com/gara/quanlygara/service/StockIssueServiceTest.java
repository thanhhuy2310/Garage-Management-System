// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.ConfirmUsageRequest;
import com.gara.quanlygara.dto.warehouse.IssueRequest;
import com.gara.quanlygara.entity.RepairPartItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockIssue;
import com.gara.quanlygara.entity.StockIssueItem;
import com.gara.quanlygara.entity.StockMovement;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockIssueItemRepository;
import com.gara.quanlygara.repository.StockIssueRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.Pageable;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyInt;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class StockIssueServiceTest {

    private static final int ISSUE_ID = 1;
    private static final int PART_ID = 5;
    private static final int ORDER_ID = 9;
    private static final int TECHNICIAN_ID = 2;

    @Mock
    private StockIssueRepository issueRepository;
    @Mock
    private StockIssueItemRepository itemRepository;
    @Mock
    private SparePartRepository sparePartRepository;
    @Mock
    private StockMovementRepository movementRepository;
    @Mock
    private RepairPartItemRepository repairPartItemRepository;
    @Mock
    private RepairServiceItemRepository repairServiceItemRepository;

    private StockIssueService service;
    private final List<StockIssueItem> savedItems = new ArrayList<>();

    @BeforeEach
    void setUp() {
        StockLedger ledger = new StockLedger(sparePartRepository, movementRepository);
        service = new StockIssueService(issueRepository, itemRepository, sparePartRepository, movementRepository,
                repairPartItemRepository, repairServiceItemRepository, ledger);
        lenient().when(sparePartRepository.updateStockQuantity(anyInt(), anyInt())).thenReturn(1);
        lenient().when(movementRepository.save(any(StockMovement.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(itemRepository.saveAndFlush(any(StockIssueItem.class))).thenAnswer(call -> call.getArgument(0));
        lenient().when(repairPartItemRepository.saveAndFlush(any(RepairPartItem.class)))
                .thenAnswer(call -> call.getArgument(0));
        lenient().when(sparePartRepository.findById(PART_ID)).thenReturn(Optional.of(part()));
    }

    // ------------------------------------------------------------------ CẤP PHÁT (tạo phiếu xuất)

    @Test
    void issueDoesNotReduceStockOrWriteMovements() {
        arrangeIssue(10, 0, "DANG_SUA", 1L);

        var response = service.create(request(5), 7);

        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
        assertEquals(1, response.items().size());
        assertEquals(5, response.items().get(0).issuedQuantity());
        assertEquals("CHO_XAC_NHAN", response.items().get(0).state());
        assertNull(response.items().get(0).actualUsedQuantity());
        assertFalse(savedItems.get(0).isConfirmed());
    }

    @Test
    void issueRejectsWhenAvailableStockCountsPendingAllocations() {
        arrangeIssue(10, 7, "DANG_SUA", 1L);

        assertThrows(ConflictException.class, () -> service.create(request(5), 7));
        verify(issueRepository, never()).saveAndFlush(any(StockIssue.class));
    }

    @Test
    void issueRejectsInsufficientStock() {
        arrangeIssue(3, 0, "DANG_SUA", 1L);

        assertThrows(ConflictException.class, () -> service.create(request(5), 7));
        verify(issueRepository, never()).saveAndFlush(any(StockIssue.class));
    }

    @Test
    void issueRejectsUnknownOrClosedRepairOrder() {
        when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> service.create(request(1), 7));

        when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.of("HOAN_TAT"));
        assertThrows(ConflictException.class, () -> service.create(request(1), 7));
    }

    @Test
    void issueRejectsTechnicianNotAssignedAndUnknownPartAndDuplicates() {
        when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.of("DANG_SUA"));
        when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(0L);
        assertThrows(ConflictException.class, () -> service.create(request(1), 7));

        when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(1L);
        when(sparePartRepository.findById(PART_ID)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> service.create(request(1), 7));

        assertThrows(BadRequestException.class, () -> service.create(new IssueRequest(
                ORDER_ID, TECHNICIAN_ID, "Thay bugi",
                List.of(new IssueRequest.Item(PART_ID, 1), new IssueRequest.Item(PART_ID, 2))), 7));
    }

    // ------------------------------------------------------------------ XÁC NHẬN THỰC DÙNG

    @Test
    void actualUsedEqualsIssuedReducesStockByIssued() {
        StockIssueItem item = arrangeConfirm(5, 12, 5, null);

        var result = service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(5, null), TECHNICIAN_ID, true);

        verify(sparePartRepository, times(1)).updateStockQuantity(PART_ID, 7);
        assertEquals(5, result.actualUsedQuantity());
        assertEquals(0, result.returnedQuantity());
        assertEquals(7, result.stockAfter());
        assertTrue(item.isConfirmed());
    }

    @Test
    void actualLessThanIssuedReducesStockByActualAndReturnsTheRest() {
        // Cấp phát 5, thực dùng 3 => tồn giảm 3 (không phải 5), hoàn trả 2.
        StockIssueItem item = arrangeConfirm(5, 12, 3, null);

        var result = service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true);

        verify(sparePartRepository, times(1)).updateStockQuantity(PART_ID, 9);
        ArgumentCaptor<StockMovement> movement = ArgumentCaptor.forClass(StockMovement.class);
        verify(movementRepository, times(1)).save(movement.capture());
        assertEquals("XUAT", movement.getValue().getType());
        assertEquals(3, movement.getValue().getQuantity());
        assertEquals(12, movement.getValue().getQuantityBefore());
        assertEquals(9, movement.getValue().getQuantityAfter());
        assertEquals(ISSUE_ID, movement.getValue().getIssueId());
        assertEquals(3, result.actualUsedQuantity());
        assertEquals(2, result.returnedQuantity());
        assertEquals(9, result.stockAfter());
        assertEquals(3, item.getActualUsedQuantity());
        assertEquals(2, item.getReturnedQuantity());
        assertEquals(TECHNICIAN_ID, item.getConfirmedTechnicianId());
    }

    @Test
    void repairPartLineUsesActualUsedNotIssued() {
        arrangeConfirm(5, 12, 3, null);
        ArgumentCaptor<RepairPartItem> line = ArgumentCaptor.forClass(RepairPartItem.class);

        service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true);

        verify(repairPartItemRepository).saveAndFlush(line.capture());
        assertEquals(3, line.getValue().getQuantity());
        assertEquals(new BigDecimal("180000.00"), line.getValue().getUnitPrice());
        assertEquals(ORDER_ID, line.getValue().getRepairOrderId());
    }

    @Test
    void existingRepairPartLineIsReplacedByTheConfirmedTotalNotAdded() {
        RepairPartItem planned = new RepairPartItem();
        planned.setRepairOrderId(ORDER_ID);
        planned.setSparePartId(PART_ID);
        planned.setQuantity(5);
        planned.setUnitPrice(new BigDecimal("1.00"));
        arrangeConfirm(5, 12, 3, planned);

        service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true);

        assertEquals(3, planned.getQuantity());
        assertEquals(new BigDecimal("180000.00"), planned.getUnitPrice());
    }

    @Test
    void actualUsedZeroKeepsStockAndReturnsEverything() {
        StockIssueItem item = arrangeConfirm(5, 12, 0, null);

        var result = service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(0, null), TECHNICIAN_ID, true);

        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
        verify(repairPartItemRepository, never()).saveAndFlush(any(RepairPartItem.class));
        assertEquals(0, result.actualUsedQuantity());
        assertEquals(5, result.returnedQuantity());
        assertNull(result.stockAfter());
        assertTrue(item.isConfirmed());
    }

    @Test
    void actualUsedGreaterThanIssuedIsRejectedWithoutAnyWrite() {
        StockIssueItem item = arrangeConfirm(5, 12, 0, null);

        assertThrows(BadRequestException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(6, null), TECHNICIAN_ID, true));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(itemRepository, never()).saveAndFlush(any(StockIssueItem.class));
        assertFalse(item.isConfirmed());
    }

    @Test
    void confirmingTwiceIsRejected() {
        StockIssueItem item = arrangeConfirm(5, 12, 3, null);
        item.setConfirmed(true);

        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void insufficientStockForActualUsedIsRejectedAndNothingChanges() {
        StockIssueItem item = arrangeConfirm(5, 2, 0, null);

        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(3, null), TECHNICIAN_ID, true));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
        verify(movementRepository, never()).save(any(StockMovement.class));
        assertFalse(item.isConfirmed());
    }

    @Test
    void unassignedTechnicianUnconfirmedQuotationAndClosedOrderAreRejected() {
        arrangeConfirm(5, 12, 0, null);

        when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(0L);
        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), TECHNICIAN_ID, true));

        when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(1L);
        when(itemRepository.countConfirmedQuotation(ORDER_ID)).thenReturn(0L);
        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), TECHNICIAN_ID, true));

        when(itemRepository.countConfirmedQuotation(ORDER_ID)).thenReturn(1L);
        when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.of("HOAN_TAT"));
        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), TECHNICIAN_ID, true));
        verify(sparePartRepository, never()).updateStockQuantity(anyInt(), anyInt());
    }

    @Test
    void technicianCanOnlyConfirmAsThemselvesAndManagerMustNameOne() {
        arrangeConfirm(5, 12, 1, null);

        assertThrows(AccessDeniedException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, 99), TECHNICIAN_ID, true));
        assertThrows(BadRequestException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), null, false));

        var result = service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, TECHNICIAN_ID), null, false);
        assertEquals(TECHNICIAN_ID, result.confirmedTechnicianId());
    }

    @Test
    void confirmRejectsUnknownItemAndIssueWithoutRepairOrder() {
        when(itemRepository.findById(new StockIssueItem.Key(ISSUE_ID, PART_ID))).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), TECHNICIAN_ID, true));

        StockIssueItem item = issueItem(5);
        when(itemRepository.findById(new StockIssueItem.Key(ISSUE_ID, PART_ID))).thenReturn(Optional.of(item));
        StockIssue noOrder = issue();
        noOrder.setRepairOrderId(null);
        when(issueRepository.findById(ISSUE_ID)).thenReturn(Optional.of(noOrder));
        assertThrows(ConflictException.class,
                () -> service.confirmUsage(ISSUE_ID, PART_ID, new ConfirmUsageRequest(1, null), TECHNICIAN_ID, true));
    }

    @Test
    void technicianWithNoRelatedIssuesGetsAnEmptyPage() {
        when(issueRepository.findIdsRelatedToTechnician(TECHNICIAN_ID)).thenReturn(List.of());

        var page = service.getAll(0, 10, TECHNICIAN_ID);

        assertTrue(page.items().isEmpty());
        verify(issueRepository, never()).findByIdInOrderByIdDesc(any(), any(Pageable.class));
    }

    @Test
    void technicianListIsFilteredToRelatedIssues() {
        when(issueRepository.findIdsRelatedToTechnician(TECHNICIAN_ID)).thenReturn(List.of(ISSUE_ID));
        when(issueRepository.findByIdInOrderByIdDesc(any(), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(issue())));
        when(itemRepository.findByIssueIdIn(any())).thenReturn(List.of(issueItem(5)));

        var page = service.getAll(0, 10, TECHNICIAN_ID);

        assertEquals(1, page.items().size());
        verify(issueRepository, never()).findAllByOrderByIdDesc(any(Pageable.class));
    }

    @Test
    void mutatingOperationsAreTransactional() throws Exception {
        assertNotNull(StockIssueService.class.getMethod("create", IssueRequest.class, Integer.class)
                .getAnnotation(Transactional.class));
        assertNotNull(StockIssueService.class.getMethod("confirmUsage", Integer.class, Integer.class,
                ConfirmUsageRequest.class, Integer.class, boolean.class).getAnnotation(Transactional.class));
    }

    // ------------------------------------------------------------------ helpers

    private IssueRequest request(int quantity) {
        return new IssueRequest(ORDER_ID, TECHNICIAN_ID, "Thay bugi",
                List.of(new IssueRequest.Item(PART_ID, quantity)));
    }

    private void arrangeIssue(int stock, long pending, String orderStatus, long assigned) {
        lenient().when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.of(orderStatus));
        lenient().when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(assigned);
        lenient().when(sparePartRepository.lockStockQuantity(PART_ID)).thenReturn(Optional.of(stock));
        lenient().when(itemRepository.sumPendingAllocation(PART_ID)).thenReturn(pending);
        lenient().when(issueRepository.saveAndFlush(any(StockIssue.class))).thenAnswer(call -> {
            StockIssue saved = call.getArgument(0);
            saved.setId(ISSUE_ID);
            return saved;
        });
        lenient().when(itemRepository.save(any(StockIssueItem.class))).thenAnswer(call -> {
            savedItems.add(call.getArgument(0));
            return call.getArgument(0);
        });
        lenient().when(itemRepository.findByIssueId(ISSUE_ID)).thenReturn(savedItems);
    }

    /** Dựng ngữ cảnh xác nhận hợp lệ: đã phân công, báo giá đã xác nhận, phiếu sửa chữa đang sửa. */
    private StockIssueItem arrangeConfirm(int issued, int stock, long confirmedTotal, RepairPartItem existingLine) {
        StockIssueItem item = issueItem(issued);
        lenient().when(itemRepository.findById(new StockIssueItem.Key(ISSUE_ID, PART_ID))).thenReturn(Optional.of(item));
        lenient().when(issueRepository.findById(ISSUE_ID)).thenReturn(Optional.of(issue()));
        lenient().when(itemRepository.countAssignment(ORDER_ID, TECHNICIAN_ID)).thenReturn(1L);
        lenient().when(itemRepository.countConfirmedQuotation(ORDER_ID)).thenReturn(1L);
        lenient().when(repairServiceItemRepository.findRepairOrderStatus(ORDER_ID)).thenReturn(Optional.of("DANG_SUA"));
        lenient().when(sparePartRepository.lockStockQuantity(PART_ID)).thenReturn(Optional.of(stock));
        lenient().when(itemRepository.sumConfirmedActual(ORDER_ID, PART_ID)).thenReturn(confirmedTotal);
        lenient().when(repairPartItemRepository.findById(new RepairPartItem.Key(ORDER_ID, PART_ID)))
                .thenReturn(Optional.ofNullable(existingLine));
        lenient().when(movementRepository.findFirstByIssueIdAndPartIdAndTypeOrderByIdDesc(any(), any(), any()))
                .thenReturn(Optional.empty());
        return item;
    }

    private StockIssue issue() {
        StockIssue issue = new StockIssue();
        issue.setId(ISSUE_ID);
        issue.setRepairOrderId(ORDER_ID);
        issue.setWarehouseStaffId(7);
        issue.setRequestedTechnicianId(TECHNICIAN_ID);
        issue.setReason("Thay bugi");
        return issue;
    }

    private StockIssueItem issueItem(int issued) {
        StockIssueItem item = new StockIssueItem();
        item.setIssueId(ISSUE_ID);
        item.setPartId(PART_ID);
        item.setQuantity(issued);
        item.setUnitPrice(new BigDecimal("180000.00"));
        return item;
    }

    private SparePart part() {
        SparePart part = new SparePart();
        part.setId(PART_ID);
        part.setWarehouseId(1);
        part.setName("Bugi");
        part.setUnitPrice(new BigDecimal("180000.00"));
        part.setMinStockLevel(5);
        return part;
    }
}
