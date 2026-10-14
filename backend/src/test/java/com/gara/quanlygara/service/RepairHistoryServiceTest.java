// TV3-TUAN9
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.history.HistoryDetailResponse;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairHistoryRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.math.BigDecimal;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class RepairHistoryServiceTest {

    private static final int CUSTOMER_ID = 7;

    @Mock
    private RepairHistoryRepository repository;

    private RepairHistoryService service;

    @BeforeEach
    void setUp() {
        service = new RepairHistoryService(repository);
        lenient().when(repository.findServiceLines(any())).thenReturn(new ArrayList<>());
        lenient().when(repository.findPartLines(any())).thenReturn(new ArrayList<>());
    }

    @Test
    void firstPageKeepsTheNewestFirstOrderAndBuildsSummaryCostsAndMetadata() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(2L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 0, 10)).thenReturn(rows(
                header(12, 1, "51G-123.45", Timestamp.valueOf("2026-09-20 10:00:00"), "1500000"),
                header(5, 2, "51A-456.78", Timestamp.valueOf("2026-06-01 09:00:00"), "300000")));
        when(repository.findServiceLines(any())).thenReturn(rows(
                service(12, 2, "Bảo dưỡng định kỳ", "BAO_DUONG", 1, "1200000"),
                service(5, 3, "Kiểm tra hệ thống phanh", "KIEM_TRA", 1, "300000")));
        when(repository.findPartLines(any())).thenReturn(rows(part(12, 9, "Lọc dầu", 1, "300000")));

        var page = service.getHistory(CUSTOMER_ID, null, 0, 10);

        assertEquals(List.of(12, 5), page.items().stream().map(item -> item.repairOrderId()).toList());
        assertEquals(0, page.page());
        assertEquals(10, page.size());
        assertEquals(2, page.totalElements());
        assertEquals(1, page.totalPages());
        assertEquals("51G-123.45", page.items().get(0).licensePlate());
        assertEquals("Bảo dưỡng định kỳ", page.items().get(0).summary());
        assertEquals(1, page.items().get(0).serviceCount());
        assertEquals(1, page.items().get(0).partCount());
        assertEquals(new BigDecimal("1500000.00"), page.items().get(0).totalCost());
        assertEquals("BAO_DUONG", page.items().get(0).category());
        assertEquals("SUA_CHUA", page.items().get(1).category());
        assertEquals(LocalDateTime.of(2026, 9, 20, 10, 0), page.items().get(0).completedAt());
    }

    @Test
    void laterPagesUseTheRightOffset() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(12L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 10, 5)).thenReturn(rows(
                header(3, 1, "A", Timestamp.valueOf("2026-01-02 00:00:00"), "0"),
                header(2, 1, "A", Timestamp.valueOf("2026-01-01 00:00:00"), "0")));

        var page = service.getHistory(CUSTOMER_ID, null, 2, 5);

        verify(repository).findHistoryRows(CUSTOMER_ID, 0, 0, 10, 5);
        assertEquals(2, page.page());
        assertEquals(12, page.totalElements());
        assertEquals(3, page.totalPages());
        assertEquals(2, page.items().size());
    }

    @Test
    void historyLongerThan200IsNeverSilentlyTruncated() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(250L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 240, 10)).thenReturn(rows(
                header(1, 1, "A", Timestamp.valueOf("2026-01-01 00:00:00"), "0")));

        var last = service.getHistory(CUSTOMER_ID, null, 24, 10);

        assertEquals(250, last.totalElements());
        assertEquals(25, last.totalPages());
        assertEquals(1, last.items().size());
        // Mỗi truy vấn chỉ lấy đúng một trang: không có TOP/giới hạn cố định nào cắt dữ liệu.
        verify(repository).findHistoryRows(CUSTOMER_ID, 0, 0, 240, 10);
    }

    @Test
    void pageBeyondTheEndIsEmptyWithoutARowQuery() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(5L);

        var page = service.getHistory(CUSTOMER_ID, null, 3, 10);

        assertTrue(page.items().isEmpty());
        assertEquals(5, page.totalElements());
        verify(repository, never()).findHistoryRows(any(), any(), any(), any(), any());
    }

    @Test
    void pageAndSizeAreClamped() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(500L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 0, 50)).thenReturn(new ArrayList<>());

        var page = service.getHistory(CUSTOMER_ID, null, -3, 1000);

        assertEquals(0, page.page());
        assertEquals(50, page.size());
        assertEquals(10, page.totalPages());
        verify(repository).findHistoryRows(CUSTOMER_ID, 0, 0, 0, 50);
    }

    @Test
    void categoryIsMaintenanceOnlyWhenEveryServiceIsMaintenance() {
        var maintenance = new HistoryDetailResponse.ServiceLine(1, "Thay dầu", "BAO_DUONG", 1, BigDecimal.ONE, BigDecimal.ONE);
        var repair = new HistoryDetailResponse.ServiceLine(2, "Thay má phanh", "SUA_CHUA", 1, BigDecimal.ONE, BigDecimal.ONE);

        assertEquals("BAO_DUONG", RepairHistoryService.category(List.of(maintenance)));
        assertEquals("BAO_DUONG_SUA_CHUA", RepairHistoryService.category(List.of(maintenance, repair)));
        assertEquals("SUA_CHUA", RepairHistoryService.category(List.of(repair)));
        assertEquals("SUA_CHUA", RepairHistoryService.category(List.of()));
    }

    @Test
    void summaryMentionsMoreServicesAndFallsBackToPartsOrResult() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(3L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 0, 10)).thenReturn(rows(
                header(1, 1, "A", Timestamp.valueOf("2026-01-01 00:00:00"), "0"),
                header(2, 1, "A", Timestamp.valueOf("2026-01-02 00:00:00"), "0"),
                header(3, 1, "A", Timestamp.valueOf("2026-01-03 00:00:00"), "0")));
        when(repository.findServiceLines(any())).thenReturn(rows(
                service(1, 1, "A1", "SUA_CHUA", 1, "1"), service(1, 2, "A2", "SUA_CHUA", 1, "1"),
                service(1, 3, "A3", "SUA_CHUA", 1, "1"), service(1, 4, "A4", "SUA_CHUA", 1, "1")));
        when(repository.findPartLines(any())).thenReturn(rows(part(2, 9, "Bugi", 4, "180000")));

        var items = service.getHistory(CUSTOMER_ID, null, 0, 10).items();

        assertEquals("A1, A2, A3 và 1 hạng mục khác", items.get(0).summary());
        assertEquals("Thay phụ tùng: Bugi", items.get(1).summary());
        assertEquals("Đã kiểm tra, xe hoạt động tốt", items.get(2).summary());
    }

    @Test
    void emptyHistoryIsAnEmptyPageWithoutRowOrLineQueries() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(0L);

        var page = service.getHistory(CUSTOMER_ID, null, 0, 10);

        assertTrue(page.items().isEmpty());
        assertEquals(0, page.totalElements());
        assertEquals(0, page.totalPages());
        verify(repository, never()).findHistoryRows(any(), any(), any(), any(), any());
        verify(repository, never()).findServiceLines(any());
    }

    @Test
    void filteringByAVehicleOfAnotherCustomerIsRejectedBeforeAnyHistoryQuery() {
        when(repository.countOwnedVehicle(99, CUSTOMER_ID)).thenReturn(0L);

        assertThrows(ResourceNotFoundException.class, () -> service.getHistory(CUSTOMER_ID, 99, 0, 10));
        verify(repository, never()).countHistory(any(), any());
        verify(repository, never()).findHistoryRows(any(), any(), any(), any(), any());
    }

    @Test
    void filteringByAnOwnedVehicleScopesCountAndRowsToThatVehicleAndCustomer() {
        when(repository.countOwnedVehicle(3, CUSTOMER_ID)).thenReturn(1L);
        when(repository.countHistory(CUSTOMER_ID, 3)).thenReturn(1L);
        when(repository.findHistoryRows(CUSTOMER_ID, 3, 0, 0, 10)).thenReturn(rows(
                header(12, 3, "A", Timestamp.valueOf("2026-01-01 00:00:00"), "0")));

        var page = service.getHistory(CUSTOMER_ID, 3, 0, 10);

        assertEquals(1, page.items().size());
        verify(repository).countHistory(CUSTOMER_ID, 3);
        verify(repository).findHistoryRows(CUSTOMER_ID, 3, 0, 0, 10);
    }

    @Test
    void invalidVehicleIdIsABadRequest() {
        assertThrows(BadRequestException.class, () -> service.getHistory(CUSTOMER_ID, 0, 0, 10));
        assertThrows(BadRequestException.class, () -> service.getHistory(CUSTOMER_ID, -4, 0, 10));
    }

    @Test
    void vehicleFilterListComesFromTheWholeHistoryNotFromAPage() {
        when(repository.findHistoryVehicles(CUSTOMER_ID)).thenReturn(rows(
                new Object[]{3, "51G-123.45", "Toyota", "Camry", 14L},
                new Object[]{4, "51A-456.78", null, "Vios", 1}));

        var vehicles = service.getVehicles(CUSTOMER_ID);

        assertEquals(2, vehicles.size());
        assertEquals(3, vehicles.get(0).vehicleId());
        assertEquals("51G-123.45", vehicles.get(0).licensePlate());
        assertEquals(14, vehicles.get(0).completedCount());
        assertEquals("", vehicles.get(1).brand());
        verify(repository, never()).findHistoryRows(any(), any(), any(), any(), any());
    }

    @Test
    void detailReturnsOnlyThatOrderWithServicesPartsAndTotalsThatAddUp() {
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 12, 0, 1)).thenReturn(rows(
                header(12, 1, "51G-123.45", Timestamp.valueOf("2026-09-20 10:00:00"), "1380000")));
        when(repository.findServiceLines(any())).thenReturn(rows(
                service(12, 2, "Bảo dưỡng định kỳ", "BAO_DUONG", 1, "1200000")));
        when(repository.findPartLines(any())).thenReturn(rows(part(12, 9, "Lọc dầu", 2, "90000")));

        var detail = service.getDetail(CUSTOMER_ID, 12);

        assertEquals(12, detail.item().repairOrderId());
        assertEquals("Bảo dưỡng định kỳ", detail.services().get(0).name());
        assertEquals(new BigDecimal("1200000.00"), detail.serviceTotal());
        assertEquals(new BigDecimal("180000.00"), detail.parts().get(0).lineTotal());
        assertEquals(new BigDecimal("180000.00"), detail.partsTotal());
        assertEquals(detail.item().totalCost(), detail.serviceTotal().add(detail.partsTotal()));
        assertEquals("Hoàn tất tốt", detail.item().result());
    }

    @Test
    void detailOfAnUnknownOrAnotherCustomersOrderIsNotFound() {
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 77, 0, 1)).thenReturn(new ArrayList<>());

        assertThrows(ResourceNotFoundException.class, () -> service.getDetail(CUSTOMER_ID, 77));
        verify(repository, never()).findServiceLines(any());
    }

    @Test
    void nullDatesAndResultDoNotBreakTheMapping() {
        when(repository.countHistory(CUSTOMER_ID, 0)).thenReturn(1L);
        when(repository.findHistoryRows(CUSTOMER_ID, 0, 0, 0, 10)).thenReturn(rows(
                new Object[]{4, 1, "51G-123.45", null, null, Timestamp.valueOf("2026-01-01 08:00:00"), null, null, null,
                        new BigDecimal("0")}));

        var item = service.getHistory(CUSTOMER_ID, null, 0, 10).items().get(0);

        assertNull(item.startedAt());
        assertNull(item.completedAt());
        assertEquals("", item.result());
        assertEquals("", item.brand());
        assertEquals(LocalDateTime.of(2026, 1, 1, 8, 0), item.createdAt());
        assertEquals("Không có hạng mục chi tiết", item.summary());
    }

    @Test
    void datesAcceptTimestampLocalDateTimeAndNull() {
        assertEquals(LocalDateTime.of(2026, 1, 2, 3, 4, 5), RepairHistoryService.toDateTime(Timestamp.valueOf("2026-01-02 03:04:05")));
        assertEquals(LocalDateTime.of(2026, 1, 2, 3, 4, 5), RepairHistoryService.toDateTime(LocalDateTime.of(2026, 1, 2, 3, 4, 5)));
        assertNull(RepairHistoryService.toDateTime(null));
    }

    // ------------------------------------------------------------------ helpers

    private List<Object[]> rows(Object[]... rows) {
        return new ArrayList<>(Arrays.asList(rows));
    }

    private Object[] header(int orderId, int vehicleId, String plate, Timestamp completed, String total) {
        String result = orderId == 12 ? "Hoàn tất tốt" : orderId == 3 ? "Đã kiểm tra, xe hoạt động tốt" : null;
        return new Object[]{orderId, vehicleId, plate, "Toyota", "Camry",
                Timestamp.valueOf("2026-09-18 08:00:00"), Timestamp.valueOf("2026-09-19 08:00:00"), completed,
                result, new BigDecimal(total)};
    }

    private Object[] service(int orderId, int serviceId, String name, String type, int quantity, String price) {
        return new Object[]{orderId, serviceId, name, type, quantity, new BigDecimal(price)};
    }

    private Object[] part(int orderId, int partId, String name, int quantity, String price) {
        return new Object[]{orderId, partId, name, quantity, new BigDecimal(price)};
    }
}
