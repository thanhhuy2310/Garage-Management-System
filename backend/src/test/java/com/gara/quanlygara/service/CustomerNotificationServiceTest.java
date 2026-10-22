// TV3-TUAN10
package com.gara.quanlygara.service;

import com.gara.quanlygara.entity.CustomerNotification;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.CustomerNotificationRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class CustomerNotificationServiceTest {

    private static final int CUSTOMER = 7;

    @Mock
    private CustomerNotificationRepository repository;

    private CustomerNotificationService service;

    @BeforeEach
    void setUp() {
        service = new CustomerNotificationService(repository);
    }

    @Test
    void listIsScopedToTheCustomerNewestFirstWithMetadataAndMappedTypes() {
        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        when(repository.findByCustomerIdOrderByCreatedAtDescIdDesc(org.mockito.ArgumentMatchers.eq(CUSTOMER), pageable.capture()))
                .thenReturn(new PageImpl<>(List.of(
                        notification(3L, "HOAN_TAT_SUA_CHUA", false, 5, null, null),
                        notification(2L, "LICH_HEN", true, null, 9, null),
                        notification(1L, "NHAC_BAO_DUONG", false, null, null, 4)),
                        PageRequest.of(0, 20), 41));

        var page = service.getAll(CUSTOMER, 0, 20);

        assertEquals(List.of(3L, 2L, 1L), page.items().stream().map(item -> item.id()).toList());
        assertEquals(List.of("repair", "appointment", "maintenance"), page.items().stream().map(item -> item.type()).toList());
        assertEquals(41, page.totalElements());
        assertEquals(3, page.totalPages());
        assertEquals(5, page.items().get(0).repairOrderId());
        assertEquals(9, page.items().get(1).appointmentId());
        assertEquals(4, page.items().get(2).maintenanceScheduleId());
        assertTrue(page.items().get(1).read());
        assertFalse(page.items().get(0).read());
        assertEquals(20, pageable.getValue().getPageSize());
    }

    @Test
    void pageAndSizeAreClamped() {
        ArgumentCaptor<Pageable> pageable = ArgumentCaptor.forClass(Pageable.class);
        when(repository.findByCustomerIdOrderByCreatedAtDescIdDesc(org.mockito.ArgumentMatchers.eq(CUSTOMER), pageable.capture()))
                .thenReturn(new PageImpl<>(List.of()));

        service.getAll(CUSTOMER, -5, 5000);

        assertEquals(0, pageable.getValue().getPageNumber());
        assertEquals(100, pageable.getValue().getPageSize());
    }

    @Test
    void unknownTypeCodesAreMappedToGeneral() {
        assertEquals("general", com.gara.quanlygara.dto.notification.NotificationResponse
                .from(notification(1L, "THANH_TOAN", false, null, null, null)).type());
        assertEquals("repair", com.gara.quanlygara.dto.notification.NotificationResponse
                .from(notification(1L, "TIEN_DO_SUA_CHUA", false, 1, null, null)).type());
    }

    @Test
    void unreadCountIsReadFromTheRepositoryForTheCustomer() {
        when(repository.countByCustomerIdAndReadFalse(CUSTOMER)).thenReturn(4L);

        assertEquals(4, service.unreadCount(CUSTOMER).count());
    }

    @Test
    void markReadChecksOwnershipInTheUpdateAndReturnsTheNotification() {
        when(repository.markRead(5L, CUSTOMER)).thenReturn(1);
        when(repository.findByIdAndCustomerId(5L, CUSTOMER))
                .thenReturn(Optional.of(notification(5L, "LICH_HEN", true, null, 9, null)));

        var response = service.markRead(CUSTOMER, 5L);

        assertTrue(response.read());
        verify(repository).markRead(5L, CUSTOMER);
    }

    @Test
    void markReadOfAnotherCustomersOrUnknownNotificationIsNotFound() {
        when(repository.markRead(99L, CUSTOMER)).thenReturn(0);

        assertThrows(ResourceNotFoundException.class, () -> service.markRead(CUSTOMER, 99L));
        verify(repository, never()).findByIdAndCustomerId(org.mockito.ArgumentMatchers.any(), org.mockito.ArgumentMatchers.any());
    }

    @Test
    void markAllReadOnlyTouchesTheCustomerAndReportsTheRemainingUnread() {
        when(repository.markAllRead(CUSTOMER)).thenReturn(3);
        when(repository.countByCustomerIdAndReadFalse(CUSTOMER)).thenReturn(0L);

        var response = service.markAllRead(CUSTOMER);

        assertEquals(3, response.updatedCount());
        assertEquals(0, response.unreadCount());
        verify(repository).markAllRead(CUSTOMER);
        verify(repository, never()).markAllRead(8);
    }

    private CustomerNotification notification(
            long id, String type, boolean read, Integer repairOrderId, Integer appointmentId, Integer reminderId
    ) {
        CustomerNotification notification = new CustomerNotification();
        notification.setId(id);
        notification.setCustomerId(CUSTOMER);
        notification.setTypeCode(type);
        notification.setTitle("Tiêu đề " + id);
        notification.setMessage("Nội dung " + id);
        notification.setCreatedAt(LocalDateTime.of(2026, 10, 1, 9, 0).plusMinutes(id));
        notification.setRead(read);
        notification.setRepairOrderId(repairOrderId);
        notification.setAppointmentId(appointmentId);
        notification.setMaintenanceReminderId(reminderId);
        return notification;
    }
}
