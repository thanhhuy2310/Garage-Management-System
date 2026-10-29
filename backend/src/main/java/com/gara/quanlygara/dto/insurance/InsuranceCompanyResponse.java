package com.gara.quanlygara.dto.insurance;

import com.gara.quanlygara.entity.InsuranceCompany;

public record InsuranceCompanyResponse(Integer id, String code, String name, String phone, String email,
                                       String address, String assessorName, String assessorContact, boolean active) {
    public static InsuranceCompanyResponse from(InsuranceCompany company) {
        return new InsuranceCompanyResponse(company.getId(), company.getCode(), company.getName(),
                company.getPhone(), company.getEmail(), company.getAddress(),
                company.getAssessorName(), company.getAssessorContact(), company.isActive());
    }
}
