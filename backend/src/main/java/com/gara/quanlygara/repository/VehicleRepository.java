package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Vehicle;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface VehicleRepository extends JpaRepository<Vehicle, Integer> {

    @org.springframework.data.jpa.repository.Lock(jakarta.persistence.LockModeType.PESSIMISTIC_WRITE)
    @org.springframework.data.jpa.repository.Query("select v from Vehicle v where v.id = :id")
    java.util.Optional<Vehicle> findForUpdate(@org.springframework.data.repository.query.Param("id") Integer id);

    boolean existsByLicensePlate(String licensePlate);

    boolean existsByLicensePlateAndIdNot(String licensePlate, Integer id);

    Page<Vehicle> findByLicensePlateContainingIgnoreCase(String keyword, Pageable pageable);

    List<Vehicle> findByCustomerIdOrderByIdDesc(Integer customerId);
}
