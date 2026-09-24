package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.Employee;
import org.springframework.data.jpa.repository.JpaRepository;

public interface EmployeeRepository extends JpaRepository<Employee, Integer> {
}
