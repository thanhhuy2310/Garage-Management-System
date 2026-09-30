package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.vehicle.VehicleRequest;
import com.gara.quanlygara.entity.Vehicle;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.VehicleRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;

import java.time.Year;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class VehicleServiceTest {

    @Mock
    private VehicleRepository vehicleRepository;

    @Mock
    private CustomerRepository customerRepository;

    private VehicleService vehicleService;

    @BeforeEach
    void setUp() {
        vehicleService = new VehicleService(vehicleRepository, customerRepository);
    }

    @Test
    void createNormalizesAndPersistsVehicle() {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.existsByLicensePlate("51A-123.45")).thenReturn(false);
        when(vehicleRepository.saveAndFlush(any(Vehicle.class))).thenAnswer(invocation -> {
            Vehicle vehicle = invocation.getArgument(0);
            vehicle.setId(7);
            return vehicle;
        });

        var response = vehicleService.create(
                new VehicleRequest(1, "  51a-123.45 ", " Toyota ", "   ", (short) 2021, 1000));

        assertEquals(7, response.id());
        assertEquals(1, response.customerId());
        assertEquals("51A-123.45", response.licensePlate());
        assertEquals("Toyota", response.brand());
        assertNull(response.model());
        assertEquals((short) 2021, response.year());
        assertEquals(1000, response.mileage());
    }

    @Test
    void createRejectsDuplicateLicensePlate() {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.existsByLicensePlate("51A-123.45")).thenReturn(true);

        assertThrows(ConflictException.class, () -> vehicleService.create(request(1, "51a-123.45")));
        verify(vehicleRepository, never()).saveAndFlush(any(Vehicle.class));
    }

    @Test
    void createRejectsMissingCustomer() {
        when(customerRepository.existsById(99)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class, () -> vehicleService.create(request(99, "51A-123.45")));
        verify(vehicleRepository, never()).saveAndFlush(any(Vehicle.class));
    }

    @Test
    void createRejectsYearInTheFarFuture() {
        when(customerRepository.existsById(1)).thenReturn(true);
        short tooLate = (short) (Year.now().getValue() + 2);

        assertThrows(BadRequestException.class, () -> vehicleService.create(
                new VehicleRequest(1, "51A-123.45", "Toyota", "Vios", tooLate, 0)));
    }

    @Test
    void getByIdReturnsVehicle() {
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle(3, 1, "59K-456.78")));

        var response = vehicleService.getById(3);

        assertEquals(3, response.id());
        assertEquals("59K-456.78", response.licensePlate());
    }

    @Test
    void getByIdRejectsMissingVehicle() {
        when(vehicleRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> vehicleService.getById(404));
    }

    @Test
    void getAllUsesPaginationAndSortsNewestFirst() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(vehicleRepository.findAll(captor.capture())).thenReturn(
                new PageImpl<>(List.of(vehicle(1, 1, "51A-123.45")), PageRequest.of(1, 5), 11));

        var response = vehicleService.getAll(1, 5, null);

        assertEquals(1, response.items().size());
        assertEquals(1, response.page());
        assertEquals(5, response.size());
        assertEquals(11, response.totalElements());
        assertEquals(3, response.totalPages());
        assertEquals(1, captor.getValue().getPageNumber());
        assertEquals(5, captor.getValue().getPageSize());
        assertEquals(Sort.Direction.DESC, captor.getValue().getSort().getOrderFor("id").getDirection());
    }

    @Test
    void getAllClampsPageAndSize() {
        ArgumentCaptor<Pageable> captor = ArgumentCaptor.forClass(Pageable.class);
        when(vehicleRepository.findAll(captor.capture())).thenReturn(new PageImpl<>(List.of()));

        vehicleService.getAll(-3, 1000, "   ");

        assertEquals(0, captor.getValue().getPageNumber());
        assertEquals(100, captor.getValue().getPageSize());
    }

    @Test
    void getAllSearchesByLicensePlate() {
        when(vehicleRepository.findByLicensePlateContainingIgnoreCase(eq("51A"), any(Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(vehicle(1, 1, "51A-123.45"))));

        var response = vehicleService.getAll(0, 10, "  51A ");

        assertEquals(1, response.items().size());
        assertEquals("51A-123.45", response.items().get(0).licensePlate());
        verify(vehicleRepository, never()).findAll(any(Pageable.class));
    }

    @Test
    void getByCustomerReturnsEmptyListWhenCustomerHasNoVehicles() {
        when(customerRepository.existsById(2)).thenReturn(true);
        when(vehicleRepository.findByCustomerIdOrderByIdDesc(2)).thenReturn(List.of());

        assertTrue(vehicleService.getByCustomer(2).isEmpty());
    }

    @Test
    void getByCustomerReturnsOnlyThatCustomersVehicles() {
        when(customerRepository.existsById(1)).thenReturn(true);
        when(vehicleRepository.findByCustomerIdOrderByIdDesc(1)).thenReturn(
                List.of(vehicle(2, 1, "51A-222.22"), vehicle(1, 1, "51A-111.11")));

        var response = vehicleService.getByCustomer(1);

        assertEquals(2, response.size());
        assertEquals("51A-222.22", response.get(0).licensePlate());
    }

    @Test
    void getByCustomerRejectsMissingCustomer() {
        when(customerRepository.existsById(99)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class, () -> vehicleService.getByCustomer(99));
    }

    @Test
    void updateKeepsVehicleIdentity() {
        Vehicle vehicle = vehicle(3, 1, "59K-456.78");
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle));
        when(vehicleRepository.existsByLicensePlateAndIdNot("51A-999.99", 3)).thenReturn(false);
        when(vehicleRepository.saveAndFlush(vehicle)).thenReturn(vehicle);

        var response = vehicleService.update(3, request(1, "51a-999.99"));

        assertEquals(3, response.id());
        assertEquals("51A-999.99", response.licensePlate());
        assertEquals("Toyota", response.brand());
    }

    @Test
    void updateRejectsPlateOwnedByAnotherVehicle() {
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle(3, 1, "59K-456.78")));
        when(vehicleRepository.existsByLicensePlateAndIdNot("51A-999.99", 3)).thenReturn(true);

        assertThrows(ConflictException.class, () -> vehicleService.update(3, request(1, "51A-999.99")));
        verify(vehicleRepository, never()).saveAndFlush(any(Vehicle.class));
    }

    @Test
    void updateChecksNewOwnerOnlyWhenCustomerChanges() {
        when(vehicleRepository.findById(3)).thenReturn(Optional.of(vehicle(3, 1, "59K-456.78")));
        when(customerRepository.existsById(2)).thenReturn(false);

        assertThrows(ResourceNotFoundException.class, () -> vehicleService.update(3, request(2, "59K-456.78")));
    }

    @Test
    void updateRejectsMissingVehicle() {
        when(vehicleRepository.findById(404)).thenReturn(Optional.empty());

        assertThrows(ResourceNotFoundException.class, () -> vehicleService.update(404, request(1, "51A-999.99")));
    }

    private VehicleRequest request(int customerId, String plate) {
        return new VehicleRequest(customerId, plate, "Toyota", "Vios", (short) 2021, 1000);
    }

    private Vehicle vehicle(int id, int customerId, String plate) {
        Vehicle vehicle = new Vehicle();
        vehicle.setId(id);
        vehicle.setCustomerId(customerId);
        vehicle.setLicensePlate(plate);
        vehicle.setBrand("Honda");
        vehicle.setModel("City");
        vehicle.setYear((short) 2020);
        vehicle.setMileage(62100);
        return vehicle;
    }
}
