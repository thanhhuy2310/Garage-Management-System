package com.gara.quanlygara.controller;

import com.gara.quanlygara.dto.ApiResponse;
import com.gara.quanlygara.dto.service.ServiceResponse;
import com.gara.quanlygara.service.PublicCatalogService;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/public")
public class PublicCatalogController {
    private final PublicCatalogService service;
    public PublicCatalogController(PublicCatalogService service) { this.service=service; }
    @GetMapping("/services")
    public ApiResponse<List<ServiceResponse>> services() { return ApiResponse.success("Danh mục dịch vụ.",service.services()); }
    @GetMapping("/parts")
    public ApiResponse<PublicCatalogService.PartPage> parts(@RequestParam(defaultValue="0") int page,@RequestParam(defaultValue="100") int size) {
        return ApiResponse.success("Danh mục phụ tùng.",service.parts(page,size));
    }
}
