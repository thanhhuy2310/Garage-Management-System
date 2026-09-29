package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Technician;
import com.gara.quanlygara.dto.technician.TechnicianResponse;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface TechnicianRepository extends JpaRepository<Technician, Integer> {

    @Query("""
            select new com.gara.quanlygara.dto.technician.TechnicianResponse(t.employeeId, e.fullName)
            from Technician t join Employee e on e.id = t.employeeId
            order by e.fullName, t.employeeId
            """)
    List<TechnicianResponse> findOptions();

    @Query("""
            select new com.gara.quanlygara.dto.technician.TechnicianResponse(t.employeeId, e.fullName)
            from Technician t join Employee e on e.id = t.employeeId
            where t.employeeId = :id
            """)
    Optional<TechnicianResponse> findOptionById(@Param("id") Integer id);
}
