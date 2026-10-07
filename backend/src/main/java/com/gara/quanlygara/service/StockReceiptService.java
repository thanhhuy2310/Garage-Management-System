// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.ImportRequest;
import com.gara.quanlygara.dto.warehouse.ImportResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockReceipt;
import com.gara.quanlygara.entity.StockReceiptItem;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockReceiptItemRepository;
import com.gara.quanlygara.repository.StockReceiptRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Nhập kho: một ChiTietPhieuNhap = một lần tăng tồn (cùng ngữ nghĩa dbo.sp_ThemChiTietPhieuNhap).
 * Phiếu và các chi tiết được tạo trong một transaction; một dòng lỗi thì rollback toàn bộ.
 */
@Service
public class StockReceiptService {

    private static final int MAX_PAGE_SIZE = 100;

    private final StockReceiptRepository receiptRepository;
    private final StockReceiptItemRepository itemRepository;
    private final SparePartRepository sparePartRepository;
    private final StockLedger ledger;

    public StockReceiptService(
            StockReceiptRepository receiptRepository,
            StockReceiptItemRepository itemRepository,
            SparePartRepository sparePartRepository,
            StockLedger ledger
    ) {
        this.receiptRepository = receiptRepository;
        this.itemRepository = itemRepository;
        this.sparePartRepository = sparePartRepository;
        this.ledger = ledger;
    }

    @Transactional
    public ImportResponse create(ImportRequest request, Integer warehouseStaffId) {
        Set<Integer> seen = new HashSet<>();
        for (ImportRequest.Item item : request.items()) {
            if (!seen.add(item.partId())) {
                throw new BadRequestException("Phụ tùng " + item.partId() + " bị trùng trong phiếu nhập.");
            }
        }

        // Khóa theo thứ tự mã phụ tùng để tránh deadlock giữa các phiếu đồng thời.
        List<ImportRequest.Item> ordered = request.items().stream()
                .sorted(Comparator.comparing(ImportRequest.Item::partId)).toList();
        Map<Integer, String> names = new HashMap<>();
        for (ImportRequest.Item item : ordered) {
            SparePart part = sparePartRepository.findById(item.partId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phụ tùng " + item.partId() + "."));
            names.put(part.getId(), part.getName());
        }

        StockReceipt receipt = new StockReceipt();
        receipt.setReceiptDate(request.importDate() != null ? request.importDate() : LocalDateTime.now());
        receipt.setSupplier(request.supplier().trim());
        receipt.setWarehouseStaffId(warehouseStaffId);
        receipt.setNote(normalizeOptional(request.note()));
        receipt = receiptRepository.saveAndFlush(receipt);

        for (ImportRequest.Item item : ordered) {
            int before = ledger.lock(item.partId());
            int after;
            try {
                after = Math.addExact(before, item.quantity());
            } catch (ArithmeticException exception) {
                throw new BadRequestException("Số lượng nhập vượt giới hạn tồn kho.");
            }

            StockReceiptItem detail = new StockReceiptItem();
            detail.setReceiptId(receipt.getId());
            detail.setPartId(item.partId());
            detail.setQuantity(item.quantity());
            detail.setUnitPrice(item.unitPrice().setScale(2, RoundingMode.HALF_UP));
            itemRepository.save(detail);

            // Mỗi chi tiết nhập chỉ tăng tồn đúng một lần.
            ledger.apply(item.partId(), before, after, StockLedger.IN, item.quantity(),
                    receipt.getId(), null, "Nhập kho theo phiếu nhập");
        }
        return toResponse(receipt, itemRepository.findByReceiptId(receipt.getId()), names);
    }

    @Transactional(readOnly = true)
    public ImportResponse get(Integer id) {
        StockReceipt receipt = receiptRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu nhập kho."));
        List<StockReceiptItem> items = itemRepository.findByReceiptId(id);
        return toResponse(receipt, items, partNames(items));
    }

    @Transactional(readOnly = true)
    public PageResponse<ImportResponse> getAll(int page, int size) {
        Page<StockReceipt> receipts = receiptRepository.findAllByOrderByIdDesc(
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE)));
        List<Integer> ids = receipts.getContent().stream().map(StockReceipt::getId).toList();
        List<StockReceiptItem> allItems = ids.isEmpty() ? List.of() : itemRepository.findByReceiptIdIn(ids);
        Map<Integer, String> names = partNames(allItems);
        Map<Integer, List<StockReceiptItem>> byReceipt = allItems.stream()
                .collect(Collectors.groupingBy(StockReceiptItem::getReceiptId));
        return PageResponse.of(receipts, receipt ->
                toResponse(receipt, byReceipt.getOrDefault(receipt.getId(), List.of()), names));
    }

    private Map<Integer, String> partNames(List<StockReceiptItem> items) {
        Set<Integer> ids = items.stream().map(StockReceiptItem::getPartId).collect(Collectors.toSet());
        Map<Integer, String> names = new HashMap<>();
        if (!ids.isEmpty()) {
            sparePartRepository.findAllById(ids).forEach(part -> names.put(part.getId(), part.getName()));
        }
        return names;
    }

    private ImportResponse toResponse(StockReceipt receipt, List<StockReceiptItem> items, Map<Integer, String> names) {
        List<ImportResponse.Item> lines = items.stream()
                .sorted(Comparator.comparing(StockReceiptItem::getPartId))
                .map(item -> new ImportResponse.Item(
                        item.getPartId(), names.getOrDefault(item.getPartId(), "Phụ tùng " + item.getPartId()),
                        item.getQuantity(), item.getUnitPrice(),
                        item.getUnitPrice().multiply(BigDecimal.valueOf(item.getQuantity())).setScale(2, RoundingMode.HALF_UP)))
                .toList();
        BigDecimal total = lines.stream().map(ImportResponse.Item::lineTotal)
                .reduce(BigDecimal.ZERO.setScale(2), BigDecimal::add);
        return new ImportResponse(receipt.getId(), receipt.getReceiptDate(), receipt.getSupplier(),
                receipt.getWarehouseStaffId(), receipt.getNote(), lines, total);
    }

    private String normalizeOptional(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
