package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Vehicle;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface VehicleRepository extends JpaRepository<Vehicle, Integer> {

    boolean existsByLicensePlate(String licensePlate);

    boolean existsByLicensePlateAndIdNot(String licensePlate, Integer id);

    Page<Vehicle> findByLicensePlateContainingIgnoreCase(String keyword, Pageable pageable);

    List<Vehicle> findByCustomerIdOrderByIdDesc(Integer customerId);
}
