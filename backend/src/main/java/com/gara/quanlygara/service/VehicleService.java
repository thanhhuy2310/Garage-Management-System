package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.vehicle.VehiclePageResponse;
import com.gara.quanlygara.dto.vehicle.VehicleRequest;
import com.gara.quanlygara.dto.vehicle.VehicleResponse;
import com.gara.quanlygara.entity.Vehicle;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.CustomerRepository;
import com.gara.quanlygara.repository.VehicleRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Year;
import java.util.List;
import java.util.Locale;

@Service
public class VehicleService {

    private static final int MIN_YEAR = 1886;
    private static final int MAX_PAGE_SIZE = 100;

    private final VehicleRepository vehicleRepository;
    private final CustomerRepository customerRepository;

    public VehicleService(VehicleRepository vehicleRepository, CustomerRepository customerRepository) {
        this.vehicleRepository = vehicleRepository;
        this.customerRepository = customerRepository;
    }

    @Transactional(readOnly = true)
    public VehiclePageResponse getAll(int page, int size, String search) {
        Pageable pageable = PageRequest.of(
                Math.max(page, 0),
                Math.min(Math.max(size, 1), MAX_PAGE_SIZE),
                Sort.by(Sort.Direction.DESC, "id"));

        String keyword = normalizeOptional(search);
        Page<Vehicle> result = keyword == null
                ? vehicleRepository.findAll(pageable)
                : vehicleRepository.findByLicensePlateContainingIgnoreCase(keyword, pageable);
        return VehiclePageResponse.from(result);
    }

    @Transactional(readOnly = true)
    public VehicleResponse getById(Integer id) {
        return VehicleResponse.from(findEntity(id));
    }

    @Transactional(readOnly = true)
    public List<VehicleResponse> getByCustomer(Integer customerId) {
        ensureCustomerExists(customerId);
        return vehicleRepository.findByCustomerIdOrderByIdDesc(customerId)
                .stream()
                .map(VehicleResponse::from)
                .toList();
    }

    @Transactional
    public VehicleResponse create(VehicleRequest request) {
        ensureCustomerExists(request.customerId());
        validateYear(request.year());

        String plate = normalizePlate(request.licensePlate());
        if (vehicleRepository.existsByLicensePlate(plate)) {
            throw new ConflictException("Biển số xe đã tồn tại.");
        }

        Vehicle vehicle = new Vehicle();
        apply(vehicle, request, plate);
        return VehicleResponse.from(vehicleRepository.saveAndFlush(vehicle));
    }

    @Transactional
    public VehicleResponse update(Integer id, VehicleRequest request) {
        Vehicle vehicle = findEntity(id);
        if (!request.customerId().equals(vehicle.getCustomerId())) {
            ensureCustomerExists(request.customerId());
        }
        validateYear(request.year());

        String plate = normalizePlate(request.licensePlate());
        if (vehicleRepository.existsByLicensePlateAndIdNot(plate, id)) {
            throw new ConflictException("Biển số xe đã được sử dụng bởi xe khác.");
        }

        apply(vehicle, request, plate);
        return VehicleResponse.from(vehicleRepository.saveAndFlush(vehicle));
    }

    private Vehicle findEntity(Integer id) {
        return vehicleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy xe."));
    }

    private void ensureCustomerExists(Integer customerId) {
        if (customerId == null || !customerRepository.existsById(customerId)) {
            throw new ResourceNotFoundException("Không tìm thấy khách hàng.");
        }
    }

    private void validateYear(Short year) {
        if (year == null) return;
        int maxYear = Year.now().getValue() + 1;
        if (year < MIN_YEAR || year > maxYear) {
            throw new BadRequestException("Năm sản xuất phải từ " + MIN_YEAR + " đến " + maxYear + ".");
        }
    }

    private void apply(Vehicle vehicle, VehicleRequest request, String plate) {
        vehicle.setCustomerId(request.customerId());
        vehicle.setLicensePlate(plate);
        vehicle.setBrand(normalizeOptional(request.brand()));
        vehicle.setModel(normalizeOptional(request.model()));
        vehicle.setYear(request.year());
        vehicle.setMileage(request.mileage());
    }

    private String normalizePlate(String value) {
        return value.trim().replaceAll("\\s+", " ").toUpperCase(Locale.ROOT);
    }

    private String normalizeOptional(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }
}
