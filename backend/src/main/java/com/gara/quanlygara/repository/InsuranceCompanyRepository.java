  package com.gara.quanlygara.repository;

import com.gara.quanlygara.entity.InsuranceCompany;
import org.springframework.data.jpa.repository.JpaRepository;

public interface InsuranceCompanyRepository extends JpaRepository<InsuranceCompany, Integer> {
    boolean existsByCode(String code);
    boolean existsByCodeAndIdNot(String code, Integer id);
}
