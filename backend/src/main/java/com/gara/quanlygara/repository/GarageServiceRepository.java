package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.GarageService;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface GarageServiceRepository extends JpaRepository<GarageService, Integer> {
    List<GarageService> findByNameContainingIgnoreCaseOrTypeContainingIgnoreCase(
            String name, String type, Sort sort);
}
