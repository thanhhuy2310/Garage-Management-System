// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.InventoryItemResponse;
import com.gara.quanlygara.dto.warehouse.InventoryPageResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.dto.warehouse.StockMovementResponse;
import com.gara.quanlygara.dto.warehouse.StockStatus;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;
import java.util.Set;

/** Tồn kho (chỉ đọc) và lịch sử biến động. Không ghi tồn ở đây. */
@Service
public class InventoryService {

    private static final int MAX_PAGE_SIZE = 100;
    private static final Set<String> MOVEMENT_TYPES = Set.of("NHAP", "XUAT", "KIEM_KE");

    private final SparePartRepository sparePartRepository;
    private final StockMovementRepository movementRepository;

    public InventoryService(SparePartRepository sparePartRepository, StockMovementRepository movementRepository) {
        this.sparePartRepository = sparePartRepository;
        this.movementRepository = movementRepository;
    }

    @Transactional(readOnly = true)
    public InventoryPageResponse getStock(int page, int size, String search, String status) {
        Pageable pageable = pageable(page, size, Sort.by("name").and(Sort.by("id")));
        String keyword = search == null ? "" : search.trim();
        Page<SparePart> result = sparePartRepository.searchInventory(keyword, normalizeStatus(status), pageable);

        return new InventoryPageResponse(
                result.getContent().stream().map(InventoryItemResponse::from).toList(),
                result.getNumber(), result.getSize(), result.getTotalElements(), result.getTotalPages(),
                sparePartRepository.countAtOrBelowMinimum());
    }

    @Transactional(readOnly = true)
    public PageResponse<StockMovementResponse> getMovements(int page, int size, Integer partId, String type) {
        String normalizedType = "ALL";
        if (type != null && !type.isBlank() && !type.trim().equalsIgnoreCase("ALL")) {
            normalizedType = type.trim().toUpperCase(Locale.ROOT);
            if (!MOVEMENT_TYPES.contains(normalizedType)) {
                throw new BadRequestException("Loại biến động không hợp lệ.");
            }
        }
        Pageable pageable = pageable(page, size, Sort.unsorted());
        return PageResponse.of(movementRepository.search(partId == null ? 0 : partId, normalizedType, pageable));
    }

    private String normalizeStatus(String status) {
        if (status == null || status.isBlank() || status.trim().equalsIgnoreCase("ALL")) return "ALL";
        try {
            return StockStatus.valueOf(status.trim().toUpperCase(Locale.ROOT)).name();
        } catch (IllegalArgumentException exception) {
            throw new BadRequestException("Trạng thái tồn kho không hợp lệ.");
        }
    }

    private Pageable pageable(int page, int size, Sort sort) {
        return PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE), sort);
    }
}
