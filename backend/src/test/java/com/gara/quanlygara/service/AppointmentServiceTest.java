package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.appointment.AppointmentDtos.*;
import com.gara.quanlygara.entity.*;
import com.gara.quanlygara.exception.*;
import com.gara.quanlygara.repository.AppointmentRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import java.time.*;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class AppointmentServiceTest {
    AppointmentRepository repository = mock(AppointmentRepository.class);
    AppointmentService service = new AppointmentService(repository,
        Clock.fixed(Instant.parse("2026-10-29T00:00:00Z"),ZoneId.of("Asia/Ho_Chi_Minh")));
    Account customer = new Account();
    LocalDate date = LocalDate.of(2026,10,30);
    LocalTime time = LocalTime.of(9,30);
    @BeforeEach void init() {
        customer.setId(2); customer.setRole(AccountRole.CUSTOMER); customer.setCustomerId(7);
        when(repository.activeVehicleOwner(8)).thenReturn(7);
        when(repository.schedule()).thenReturn(List.of(new Schedule(5,time,1)));
    }
    View view(String status, int version) {
        return new View(1,7,"Nguyễn An",8,"51A-12345","Toyota","Vios",2021,1000,null,null,null,null,date,time,"",status,version);
    }
    @Test void cannotBookOthersVehicle() {
        when(repository.activeVehicleOwner(8)).thenReturn(9);
        assertThrows(ResourceNotFoundException.class,()->service.create(new Create(8,null,date,time,""),customer));
        verify(repository,never()).create(any(),anyInt());
    }
    @Test void rejectsPastSlot() {
        assertThrows(BadRequestException.class,()->service.create(new Create(8,null,date.minusDays(2),time,""),customer));
    }
    @Test void noConfigurationDoesNotInventAvailability() {
        when(repository.schedule()).thenReturn(List.of());
        assertFalse(service.availability(date).configured());
        assertTrue(service.availability(date).slots().isEmpty());
        assertThrows(ConflictException.class,()->service.create(new Create(8,null,date,time,""),customer));
    }
    @Test void fullSlotCannotBeBooked() {
        when(repository.occupied(date,time,0)).thenReturn(1);
        assertThrows(ConflictException.class,()->service.create(new Create(8,null,date,time,""),customer));
        verify(repository,never()).create(any(),anyInt());
    }
    @Test void duplicateVehicleCannotBeBooked() {
        when(repository.duplicateVehicle(8,date,time,0)).thenReturn(true);
        assertThrows(ConflictException.class,()->service.create(new Create(8,null,date,time,""),customer));
    }
    @Test void createdRecordIsReadBackAndAuditedUnderLock() {
        var input = new Create(8,null,date,time,"Kiểm tra phanh");
        when(repository.create(input,7)).thenReturn(1);
        when(repository.get(1)).thenReturn(view("CHO_XAC_NHAN",0));
        assertEquals(1,service.create(input,customer).id());
        var order = inOrder(repository);
        order.verify(repository).lockBooking();
        order.verify(repository).create(input,7);
        order.verify(repository).get(1);
        order.verify(repository).audit(any(),eq(2),eq("TAO"),eq(input.note()));
    }
    @Test void otherCustomerCannotReadOrCancel() {
        when(repository.get(1)).thenReturn(view("CHO_XAC_NHAN",0));
        customer.setCustomerId(99);
        assertThrows(ResourceNotFoundException.class,()->service.get(1,customer));
        assertThrows(ResourceNotFoundException.class,()->service.cancel(1,new Change(0,""),customer));
    }
    @Test void staleVersionDoesNotOverwriteNewState() {
        when(repository.get(1)).thenReturn(view("CHO_XAC_NHAN",2));
        assertThrows(ConflictException.class,()->service.move(1,new Move(date,time,1,""),customer));
        verify(repository,never()).update(anyInt(),anyInt(),any(),any(),any());
    }
    @Test void receivedAppointmentCannotMoveOrCancel() {
        when(repository.get(1)).thenReturn(view("DA_DEN",0));
        assertThrows(ConflictException.class,()->service.cancel(1,new Change(0,""),customer));
        assertThrows(ConflictException.class,()->service.move(1,new Move(date,time,0,""),customer));
    }
    @Test void repeatedCancellationDoesNotWriteAnotherAudit() {
        when(repository.get(1)).thenReturn(view("HUY",1));
        assertEquals("HUY",service.cancel(1,new Change(0,""),customer).status());
        verify(repository,never()).audit(any(),anyInt(),any(),any());
    }
    @Test void movedConfirmedAppointmentMustBeConfirmedAgain() {
        when(repository.get(1)).thenReturn(view("DA_XAC_NHAN",0),view("CHO_XAC_NHAN",1));
        service.move(1,new Move(date,time,0,"Đổi giờ"),customer);
        verify(repository).update(1,0,date,time,"CHO_XAC_NHAN");
    }
}
