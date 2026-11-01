package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.catalog.PublicPartResponse;
import com.gara.quanlygara.dto.service.ServiceResponse;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@Transactional(readOnly=true)
public class PublicCatalogService {
    private final ServiceCatalogService services;
    private final SparePartService parts;
    public PublicCatalogService(ServiceCatalogService services,SparePartService parts) { this.services=services;this.parts=parts; }
    public List<ServiceResponse> services() { return services.getAll(null); }
    public record PartPage(List<PublicPartResponse> items,int page,int size,long totalElements,int totalPages) { }
    public PartPage parts(int page,int size) {
        var result=parts.getAll(page,size,null);
        return new PartPage(result.items().stream().map(PublicPartResponse::from).toList(),result.page(),result.size(),result.totalElements(),result.totalPages());
    }
}
