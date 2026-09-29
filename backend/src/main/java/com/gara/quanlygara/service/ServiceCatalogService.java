package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.service.ServiceRequest;
import com.gara.quanlygara.dto.service.ServiceResponse;
import com.gara.quanlygara.entity.GarageService;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.GarageServiceRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ServiceCatalogService {

    private final GarageServiceRepository serviceRepository;

    public ServiceCatalogService(GarageServiceRepository serviceRepository) {
        this.serviceRepository = serviceRepository;
    }

    @Transactional(readOnly = true)
    public List<ServiceResponse> getAll(String keyword) {
        Sort sort = Sort.by(Sort.Direction.ASC, "id");
        String search = keyword == null ? "" : keyword.strip();
        List<GarageService> services = search.isEmpty()
                ? serviceRepository.findAll(sort)
                : serviceRepository.findByNameContainingIgnoreCaseOrTypeContainingIgnoreCase(search, search, sort);
        return services.stream().map(ServiceResponse::from).toList();
    }

    @Transactional(readOnly = true)
    public ServiceResponse getById(Integer id) {
        return ServiceResponse.from(findEntity(id));
    }

    @Transactional
    public ServiceResponse create(ServiceRequest request) {
        GarageService service = new GarageService();
        apply(service, request);
        return ServiceResponse.from(serviceRepository.save(service));
    }

    @Transactional
    public ServiceResponse update(Integer id, ServiceRequest request) {
        GarageService service = findEntity(id);
        apply(service, request);
        return ServiceResponse.from(serviceRepository.save(service));
    }

    private GarageService findEntity(Integer id) {
        return serviceRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy dịch vụ."));
    }

    private void apply(GarageService service, ServiceRequest request) {
        service.setName(request.name());
        service.setType(request.type());
        service.setUnitPrice(request.unitPrice());
        service.setDescription(request.description());
    }
}
