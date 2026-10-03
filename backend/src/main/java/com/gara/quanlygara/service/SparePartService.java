// TV3-TUAN7
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.sparepart.SparePartPageResponse;
import com.gara.quanlygara.dto.sparepart.SparePartRequest;
import com.gara.quanlygara.dto.sparepart.SparePartResponse;
import com.gara.quanlygara.dto.sparepart.WarehouseOptionResponse;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.SparePartRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.RoundingMode;
import java.util.List;

/**
 * Danh mục phụ tùng. Không nhập kho, không xuất kho, không điều chỉnh tồn:
 * SoLuongTon không được ghi ở đây (xem SparePart).
 */
@Service
public class SparePartService {

    private static final int MAX_PAGE_SIZE = 100;

    private final SparePartRepository sparePartRepository;

    public SparePartService(SparePartRepository sparePartRepository) {
        this.sparePartRepository = sparePartRepository;
    }

    @Transactional(readOnly = true)
    public SparePartPageResponse getAll(int page, int size, String search) {
        Pageable pageable = PageRequest.of(
                Math.max(page, 0),
                Math.min(Math.max(size, 1), MAX_PAGE_SIZE),
                Sort.by("name").and(Sort.by("id")));

        String keyword = normalizeOptional(search);
        Page<SparePart> result = keyword == null
                ? sparePartRepository.findAll(pageable)
                : sparePartRepository.findByNameContainingIgnoreCaseOrManufacturerContainingIgnoreCase(
                        keyword, keyword, pageable);
        return SparePartPageResponse.from(result);
    }

    @Transactional(readOnly = true)
    public SparePartResponse getById(Integer id) {
        return SparePartResponse.from(findEntity(id));
    }

    @Transactional(readOnly = true)
    public List<WarehouseOptionResponse> getWarehouses() {
        return sparePartRepository.findWarehouses().stream()
                .map(view -> new WarehouseOptionResponse(view.getId(), view.getName()))
                .toList();
    }

    @Transactional
    public SparePartResponse create(SparePartRequest request) {
        ensureWarehouseExists(request.warehouseId());

        SparePart part = new SparePart();
        apply(part, request);
        return SparePartResponse.from(sparePartRepository.saveAndFlush(part));
    }

    @Transactional
    public SparePartResponse update(Integer id, SparePartRequest request) {
        SparePart part = findEntity(id);
        if (!request.warehouseId().equals(part.getWarehouseId())) {
            ensureWarehouseExists(request.warehouseId());
        }

        apply(part, request);
        return SparePartResponse.from(sparePartRepository.saveAndFlush(part));
    }

    private SparePart findEntity(Integer id) {
        return sparePartRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phụ tùng."));
    }

    private void ensureWarehouseExists(Integer warehouseId) {
        if (sparePartRepository.countWarehouse(warehouseId) == 0) {
            throw new ResourceNotFoundException("Không tìm thấy kho.");
        }
    }

    private void apply(SparePart part, SparePartRequest request) {
        part.setWarehouseId(request.warehouseId());
        part.setName(request.name().trim().replaceAll("\\s+", " "));
        part.setManufacturer(normalizeOptional(request.manufacturer()));
        part.setUnitPrice(request.unitPrice().setScale(2, RoundingMode.HALF_UP));
        part.setMinStockLevel(request.minStockLevel() == null ? 0 : request.minStockLevel());
    }

    private String normalizeOptional(String value) {
        if (value == null || value.isBlank()) return null;
        return value.trim();
    }
}
