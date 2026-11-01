package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Employee;
import com.gara.quanlygara.dto.employee.EmployeeResponse;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;
import java.util.List;
import java.util.Optional;

public interface EmployeeRepository extends JpaRepository<Employee, Integer> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select e from Employee e where e.id = :id")
    Optional<Employee> findForUpdate(@Param("id") Integer id);

    @Query("""
        select new com.gara.quanlygara.dto.employee.EmployeeResponse(
            e.id, e.fullName, e.phone, e.email, e.position,
            case when t.employeeId is null then false else true end,
            a.username, cast(a.role as string), a.active)
        from Employee e
        left join Technician t on t.employeeId = e.id
        left join Account a on a.employeeId = e.id
        order by e.fullName, e.id
        """)
    List<EmployeeResponse> findOverview();
}
