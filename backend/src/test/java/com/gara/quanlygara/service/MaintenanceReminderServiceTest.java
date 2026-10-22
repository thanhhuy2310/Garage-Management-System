// TV3-TUAN10
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.notification.MaintenanceReminderRequest;
import com.gara.quanlygara.entity.CustomerNotification;
import com.gara.quanlygara.entity.MaintenanceReminder;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.CustomerNotificationRepository;
import com.gara.quanlygara.repository.MaintenanceReminderRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.sql.Date;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.lenient;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class MaintenanceReminderServiceTest {

    private static final LocalDate TODAY = LocalDate.of(2026, 10, 20);

    @Mock
    private MaintenanceReminderRepository reminderRepository;
    @Mock
    private CustomerNotificationRepository notificationRepository;

    private MaintenanceReminderService service;

    @BeforeEach
    void setUp() {
        service = new MaintenanceReminderService(reminderRepository,
                new MaintenanceReminderDispatcher(reminderRepository, notificationRepository));
        lenient().when(reminderRepository.saveAndFlush(any(MaintenanceReminder.class))).thenAnswer(call -> {
            MaintenanceReminder saved = call.getArgument(0);
            saved.setId(1);
            return saved;
        });
        lenient().when(notificationRepository.saveAndFlush(any(CustomerNotification.class)))
                .thenAnswer(call -> call.getArgument(0));
    }

    // ------------------------------------------------------------------ thiết lập lịch nhắc

    @Test
    void createRequiresADueDateOrAKilometerMark() {
        assertThrows(BadRequestException.class,
                () -> service.create(new MaintenanceReminderRequest(1, null, null, null, null), 2));
        verify(reminderRepository, never()).saveAndFlush(any(MaintenanceReminder.class));
    }

    @Test
    void createRejectsNegativeKilometersAndUnknownVehicle() {
        assertThrows(BadRequestException.class,
                () -> service.create(new MaintenanceReminderRequest(1, null, null, -1, null), 2));

        when(reminderRepository.countVehicle(99)).thenReturn(0L);
        assertThrows(ResourceNotFoundException.class,
                () -> service.create(new MaintenanceReminderRequest(99, null, TODAY, null, null), 2));
    }

    @Test
    void createChecksThatTheServiceExistsAndIsMaintenance() {
        when(reminderRepository.countVehicle(1)).thenReturn(1L);
        when(reminderRepository.findServiceType(7)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class,
                () -> service.create(new MaintenanceReminderRequest(1, 7, TODAY, null, null), 2));

        when(reminderRepository.findServiceType(8)).thenReturn(Optional.of("SUA_CHUA"));
        assertThrows(BadRequestException.class,
                () -> service.create(new MaintenanceReminderRequest(1, 8, TODAY, null, null), 2));

        when(reminderRepository.findServiceType(9)).thenReturn(Optional.of("BAO_DUONG"));
        var response = service.create(new MaintenanceReminderRequest(1, 9, TODAY, 15000, "  Thay dầu  "), 2);

        assertEquals("CHO_NHAC", response.status());
        assertEquals("Thay dầu", response.note());
        assertEquals(15000, response.dueKm());
    }

    @Test
    void createStoresThePendingReminderWithTheCreator() {
        when(reminderRepository.countVehicle(1)).thenReturn(1L);
        ArgumentCaptor<MaintenanceReminder> captor = ArgumentCaptor.forClass(MaintenanceReminder.class);

        service.create(new MaintenanceReminderRequest(1, null, TODAY, null, null), 5);

        verify(reminderRepository).saveAndFlush(captor.capture());
        assertEquals(5, captor.getValue().getCreatedBy());
        assertEquals("CHO_NHAC", captor.getValue().getStatus());
        assertEquals(TODAY, captor.getValue().getDueDate());
    }

    @Test
    void cancelWorksOnPendingIsIdempotentWhenCancelledAndRejectedWhenAlreadyReminded() {
        MaintenanceReminder pending = reminder(1, "DA_HUY");
        when(reminderRepository.cancelPending(1)).thenReturn(1);
        when(reminderRepository.findById(1)).thenReturn(Optional.of(pending));
        assertEquals("DA_HUY", service.cancel(1).status());

        when(reminderRepository.cancelPending(2)).thenReturn(0);
        when(reminderRepository.findById(2)).thenReturn(Optional.of(reminder(2, "DA_HUY")));
        assertEquals("DA_HUY", service.cancel(2).status());

        when(reminderRepository.cancelPending(3)).thenReturn(0);
        when(reminderRepository.findById(3)).thenReturn(Optional.of(reminder(3, "DA_NHAC")));
        assertThrows(ConflictException.class, () -> service.cancel(3));

        when(reminderRepository.cancelPending(4)).thenReturn(0);
        when(reminderRepository.findById(4)).thenReturn(Optional.empty());
        assertThrows(ResourceNotFoundException.class, () -> service.cancel(4));
    }

    // ------------------------------------------------------------------ phát sinh thông báo khi đến hạn

    @Test
    void aReminderDueByDateCreatesOneNotificationForTheVehicleOwner() {
        when(reminderRepository.findDue(TODAY)).thenReturn(rows(due(4, 11, 7, "51G-123.45", TODAY, null, 12000, "Thay dầu", "Bảo dưỡng định kỳ")));
        when(reminderRepository.claim(4)).thenReturn(1);
        ArgumentCaptor<CustomerNotification> captor = ArgumentCaptor.forClass(CustomerNotification.class);

        int created = service.processDue(TODAY);

        assertEquals(1, created);
        verify(notificationRepository).saveAndFlush(captor.capture());
        CustomerNotification notification = captor.getValue();
        assertEquals(7, notification.getCustomerId());
        assertEquals(4, notification.getMaintenanceReminderId());
        assertEquals("NHAC_BAO_DUONG", notification.getTypeCode());
        assertFalse(notification.isRead());
        assertTrue(notification.getTitle().contains("51G-123.45"));
        assertTrue(notification.getMessage().contains("20/10/2026"));
        assertTrue(notification.getMessage().contains("Bảo dưỡng định kỳ"));
    }

    @Test
    void aKilometerOnlyReminderMentionsTheMilestoneAndTheCurrentKm() {
        when(reminderRepository.findDue(TODAY)).thenReturn(rows(due(5, 11, 7, "51G-123.45", null, 10000, 10250, "", "")));
        when(reminderRepository.claim(5)).thenReturn(1);
        ArgumentCaptor<CustomerNotification> captor = ArgumentCaptor.forClass(CustomerNotification.class);

        service.processDue(TODAY);

        verify(notificationRepository).saveAndFlush(captor.capture());
        assertTrue(captor.getValue().getMessage().contains("10250 km"));
        assertTrue(captor.getValue().getMessage().contains("10000 km"));
    }

    @Test
    void nothingDueCreatesNoNotificationAndSkipsClaiming() {
        when(reminderRepository.findDue(TODAY)).thenReturn(new ArrayList<>());

        assertEquals(0, service.processDue(TODAY));
        verify(reminderRepository, never()).claim(any());
        verify(notificationRepository, never()).saveAndFlush(any(CustomerNotification.class));
    }

    @Test
    void runningTheJobAgainDoesNotCreateADuplicate() {
        // Lượt đầu giành được lịch nhắc; lượt sau (job chạy lại / khởi động lại / chạy song song) nhận 0 dòng khi claim.
        when(reminderRepository.findDue(TODAY)).thenReturn(rows(due(4, 11, 7, "51G-123.45", TODAY, null, null, "", "")));
        when(reminderRepository.claim(4)).thenReturn(1, 0, 0);

        assertEquals(1, service.processDue(TODAY));
        assertEquals(0, service.processDue(TODAY));
        assertEquals(0, service.processDue(TODAY));

        verify(notificationRepository, times(1)).saveAndFlush(any(CustomerNotification.class));
    }

    @Test
    void aReminderLostToAnotherWorkerCreatesNothing() {
        when(reminderRepository.findDue(TODAY)).thenReturn(rows(due(4, 11, 7, "A", TODAY, null, null, "", "")));
        when(reminderRepository.claim(4)).thenReturn(0);

        assertEquals(0, service.processDue(TODAY));
        verify(notificationRepository, never()).saveAndFlush(any(CustomerNotification.class));
    }

    @Test
    void oneFailingReminderDoesNotBlockTheOthers() {
        when(reminderRepository.findDue(TODAY)).thenReturn(rows(
                due(4, 11, 7, "A", TODAY, null, null, "", ""),
                due(5, 12, 8, "B", TODAY, null, null, "", "")));
        when(reminderRepository.claim(4)).thenReturn(1);
        when(reminderRepository.claim(5)).thenReturn(1);
        when(notificationRepository.saveAndFlush(any(CustomerNotification.class)))
                .thenThrow(new IllegalStateException("db down"))
                .thenAnswer(call -> call.getArgument(0));

        assertEquals(1, service.processDue(TODAY));
        verify(notificationRepository, times(2)).saveAndFlush(any(CustomerNotification.class));
    }

    @Test
    void creatingNotificationsOnlyTouchesTheReminderAndNotificationTables() {
        when(reminderRepository.findDue(TODAY)).thenReturn(rows(due(4, 11, 7, "A", TODAY, null, null, "", "")));
        when(reminderRepository.claim(4)).thenReturn(1);

        service.processDue(TODAY);

        // Chỉ có 2 repository tham gia (lịch nhắc + thông báo): không có kho, xe, phiếu sửa chữa, lịch hẹn...
        verify(reminderRepository).findDue(TODAY);
        verify(reminderRepository).claim(4);
        verify(notificationRepository).saveAndFlush(any(CustomerNotification.class));
        org.mockito.Mockito.verifyNoMoreInteractions(reminderRepository, notificationRepository);
    }

    @Test
    void listFiltersAreValidated() {
        assertThrows(BadRequestException.class, () -> service.getAll(null, "KHONG_CO", 0, 20));
    }

    // ------------------------------------------------------------------ helpers

    private List<Object[]> rows(Object[]... rows) {
        return new ArrayList<>(List.of(rows));
    }

    private Object[] due(int id, int vehicleId, int customerId, String plate, LocalDate dueDate, Integer dueKm,
                         Integer currentKm, String note, String serviceName) {
        return new Object[]{id, vehicleId, customerId, plate, dueDate == null ? null : Date.valueOf(dueDate),
                dueKm, currentKm, note, serviceName};
    }

    private MaintenanceReminder reminder(int id, String status) {
        MaintenanceReminder reminder = new MaintenanceReminder();
        reminder.setId(id);
        reminder.setVehicleId(1);
        reminder.setStatus(status);
        reminder.setDueDate(TODAY);
        reminder.setCreatedAt(TODAY.atStartOfDay());
        return reminder;
    }
}
