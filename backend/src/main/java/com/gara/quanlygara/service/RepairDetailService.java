// TV3-TUAN7
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.repairdetail.RepairDetailCreateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailResponse;
import com.gara.quanlygara.dto.repairdetail.RepairDetailType;
import com.gara.quanlygara.dto.repairdetail.RepairDetailUpdateRequest;
import com.gara.quanlygara.dto.repairdetail.RepairDetailsResponse;
import com.gara.quanlygara.entity.RepairPartItem;
import com.gara.quanlygara.entity.RepairServiceItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairDetailRow;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Set;

/**
 * Chi tiết phiếu sửa chữa = các dòng ChiTietDichVu + ChiTietPhuTung của một phiếu.
 * Thêm/sửa/xóa dòng KHÔNG xuất kho và KHÔNG thay đổi SoLuongTon (thuộc nghiệp vụ kho, Tuần 8).
 */
@Service
public class RepairDetailService {

    // Không sửa hạng mục khi phiếu đã đóng. Các trạng thái khác do module Phiếu sửa chữa quản lý.
    private static final Set<String> LOCKED_STATUSES = Set.of("HOAN_TAT", "DA_HUY");

    private final RepairServiceItemRepository serviceItemRepository;
    private final RepairPartItemRepository partItemRepository;
    private final SparePartRepository sparePartRepository;

    public RepairDetailService(
            RepairServiceItemRepository serviceItemRepository,
            RepairPartItemRepository partItemRepository,
            SparePartRepository sparePartRepository
    ) {
        this.serviceItemRepository = serviceItemRepository;
        this.partItemRepository = partItemRepository;
        this.sparePartRepository = sparePartRepository;
    }

    @Transactional(readOnly = true)
    public RepairDetailsResponse getAll(Integer repairOrderId) {
        String status = requireOrderStatus(repairOrderId);

        List<RepairDetailResponse> items = new ArrayList<>();
        for (RepairDetailRow row : serviceItemRepository.findDetailRows(repairOrderId)) {
            items.add(toResponse(RepairDetailType.SERVICE, row));
        }
        for (RepairDetailRow row : partItemRepository.findDetailRows(repairOrderId)) {
            items.add(toResponse(RepairDetailType.SPARE_PART, row));
        }

        BigDecimal serviceTotal = sum(items, RepairDetailType.SERVICE);
        BigDecimal partsTotal = sum(items, RepairDetailType.SPARE_PART);
        return new RepairDetailsResponse(
                repairOrderId, status, isEditable(status), items,
                serviceTotal, partsTotal, serviceTotal.add(partsTotal));
    }

    @Transactional(readOnly = true)
    public RepairDetailResponse get(Integer repairOrderId, RepairDetailType type, Integer itemId) {
        return getAll(repairOrderId).items().stream()
                .filter(item -> item.type() == type && item.itemId().equals(itemId))
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hạng mục trong phiếu sửa chữa."));
    }

    @Transactional
    public RepairDetailResponse create(Integer repairOrderId, RepairDetailCreateRequest request) {
        ensureEditable(requireOrderStatus(repairOrderId));

        switch (request.type()) {
            case SERVICE -> createServiceItem(repairOrderId, request);
            case SPARE_PART -> createPartItem(repairOrderId, request);
        }
        return get(repairOrderId, request.type(), request.itemId());
    }

    @Transactional
    public RepairDetailResponse update(
            Integer repairOrderId, RepairDetailType type, Integer itemId, RepairDetailUpdateRequest request
    ) {
        ensureEditable(requireOrderStatus(repairOrderId));

        switch (type) {
            case SERVICE -> {
                RepairServiceItem item = serviceItemRepository
                        .findById(new RepairServiceItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                item.setQuantity(request.quantity());
                if (request.unitPrice() != null) item.setUnitPrice(scale(request.unitPrice()));
                serviceItemRepository.saveAndFlush(item);
            }
            case SPARE_PART -> {
                RepairPartItem item = partItemRepository
                        .findById(new RepairPartItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                item.setQuantity(request.quantity());
                if (request.unitPrice() != null) item.setUnitPrice(scale(request.unitPrice()));
                partItemRepository.saveAndFlush(item);
            }
        }
        return get(repairOrderId, type, itemId);
    }

    @Transactional
    public void delete(Integer repairOrderId, RepairDetailType type, Integer itemId) {
        ensureEditable(requireOrderStatus(repairOrderId));

        switch (type) {
            case SERVICE -> {
                RepairServiceItem item = serviceItemRepository
                        .findById(new RepairServiceItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                serviceItemRepository.delete(item);
            }
            case SPARE_PART -> {
                RepairPartItem item = partItemRepository
                        .findById(new RepairPartItem.Key(repairOrderId, itemId))
                        .orElseThrow(this::itemNotFound);
                partItemRepository.delete(item);
            }
        }
    }

    private void createServiceItem(Integer repairOrderId, RepairDetailCreateRequest request) {
        BigDecimal catalogPrice = serviceItemRepository.findServiceCatalogPrice(request.itemId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy dịch vụ."));
        if (serviceItemRepository.existsById(new RepairServiceItem.Key(repairOrderId, request.itemId()))) {
            throw new ConflictException("Dịch vụ đã có trong phiếu sửa chữa. Hãy sửa số lượng của hạng mục đó.");
        }

        RepairServiceItem item = new RepairServiceItem();
        item.setRepairOrderId(repairOrderId);
        item.setServiceId(request.itemId());
        item.setQuantity(request.quantity());
        item.setUnitPrice(scale(request.unitPrice() != null ? request.unitPrice() : catalogPrice));
        serviceItemRepository.saveAndFlush(item);
    }

    private void createPartItem(Integer repairOrderId, RepairDetailCreateRequest request) {
        // Chỉ ĐỌC phụ tùng để kiểm tra tồn tại và lấy đơn giá; không bao giờ ghi lại PhuTung/SoLuongTon.
        SparePart part = sparePartRepository.findById(request.itemId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phụ tùng."));
        if (partItemRepository.existsById(new RepairPartItem.Key(repairOrderId, request.itemId()))) {
            throw new ConflictException("Phụ tùng đã có trong phiếu sửa chữa. Hãy sửa số lượng của hạng mục đó.");
        }

        RepairPartItem item = new RepairPartItem();
        item.setRepairOrderId(repairOrderId);
        item.setSparePartId(request.itemId());
        item.setQuantity(request.quantity());
        item.setUnitPrice(scale(request.unitPrice() != null ? request.unitPrice() : part.getUnitPrice()));
        partItemRepository.saveAndFlush(item);
    }

    private String requireOrderStatus(Integer repairOrderId) {
        return serviceItemRepository.findRepairOrderStatus(repairOrderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
    }

    private boolean isEditable(String status) {
        return status == null || !LOCKED_STATUSES.contains(status.trim().toUpperCase(Locale.ROOT));
    }

    private void ensureEditable(String status) {
        if (!isEditable(status)) {
            throw new ConflictException("Phiếu sửa chữa đã đóng, không thể thay đổi hạng mục.");
        }
    }

    private ResourceNotFoundException itemNotFound() {
        return new ResourceNotFoundException("Không tìm thấy hạng mục trong phiếu sửa chữa.");
    }

    private RepairDetailResponse toResponse(RepairDetailType type, RepairDetailRow row) {
        BigDecimal lineTotal = row.getUnitPrice()
                .multiply(BigDecimal.valueOf(row.getQuantity()))
                .setScale(2, RoundingMode.HALF_UP);
        return new RepairDetailResponse(
                type, row.getItemId(), row.getItemName(), row.getQuantity(),
                scale(row.getUnitPrice()), lineTotal, row.getItemStatus());
    }

    private BigDecimal sum(List<RepairDetailResponse> items, RepairDetailType type) {
        return items.stream()
                .filter(item -> item.type() == type)
                .map(RepairDetailResponse::lineTotal)
                .reduce(BigDecimal.ZERO.setScale(2), BigDecimal::add);
    }

    private BigDecimal scale(BigDecimal value) {
        return value.setScale(2, RoundingMode.HALF_UP);
    }
}
