package com.gara.quanlygara.repository;

import com.gara.quanlygara.dto.technician.TechnicianAssignmentResponse;
import com.gara.quanlygara.dto.technician.TechnicianRepairOrderResponse;
import com.gara.quanlygara.entity.TechnicianAssignment;
import com.gara.quanlygara.entity.TechnicianAssignmentId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface TechnicianAssignmentRepository extends JpaRepository<TechnicianAssignment, TechnicianAssignmentId> {

    @Query("""
            select new com.gara.quanlygara.dto.technician.TechnicianAssignmentResponse(
                a.id.repairOrderId, a.id.technicianId, e.fullName, a.assignedAt, a.notes)
            from TechnicianAssignment a
            join Technician t on t.employeeId = a.id.technicianId
            join Employee e on e.id = t.employeeId
            where a.id.repairOrderId = :repairOrderId
            order by a.assignedAt, a.id.technicianId
            """)
    List<TechnicianAssignmentResponse> findAssignments(@Param("repairOrderId") Integer repairOrderId);

    @Query("""
            select new com.gara.quanlygara.dto.technician.TechnicianRepairOrderResponse(
                r.id, r.receptionId, r.createdAt, r.startedAt, r.completedAt, r.status, r.result,
                a.assignedAt, a.notes)
            from TechnicianAssignment a
            join RepairOrder r on r.id = a.id.repairOrderId
            where a.id.technicianId = :technicianId
            order by a.assignedAt desc, r.id desc
            """)
    List<TechnicianRepairOrderResponse> findRepairOrders(@Param("technicianId") Integer technicianId);
}
