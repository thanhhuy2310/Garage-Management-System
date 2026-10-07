// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.CheckActualRequest;
import com.gara.quanlygara.dto.warehouse.CheckCreateRequest;
import com.gara.quanlygara.dto.warehouse.CheckResponse;
import com.gara.quanlygara.dto.warehouse.CheckSummaryResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.entity.InventoryCheck;
import com.gara.quanlygara.entity.InventoryCheckItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.InventoryCheckItemRepository;
import com.gara.quanlygara.repository.InventoryCheckRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Kiểm kê có phê duyệt:
 *   tạo phiên (snapshot tồn) -> nhập tồn thực tế -> tính chênh lệch
 *   -> mọi chênh lệch = 0: DA_HOAN_TAT; có chênh lệch: CHO_PHE_DUYET.
 * Tồn kho CHỈ đổi khi MANAGER phê duyệt (approve). Nhập thực tế/từ chối không bao giờ đổi tồn.
 */
@Service
public class InventoryCheckService {

    private static final int MAX_PAGE_SIZE = 100;

    private final InventoryCheckRepository checkRepository;
    private final InventoryCheckItemRepository itemRepository;
    private final SparePartRepository sparePartRepository;
    private final StockLedger ledger;

    public InventoryCheckService(
            InventoryCheckRepository checkRepository,
            InventoryCheckItemRepository itemRepository,
            SparePartRepository sparePartRepository,
            StockLedger ledger
    ) {
        this.checkRepository = checkRepository;
        this.itemRepository = itemRepository;
        this.sparePartRepository = sparePartRepository;
        this.ledger = ledger;
    }

    @Transactional
    public CheckResponse create(CheckCreateRequest request, Integer staffId) {
        Set<Integer> seen = new HashSet<>();
        for (Integer partId : request.partIds()) {
            if (!seen.add(partId)) {
                throw new BadRequestException("Phụ tùng " + partId + " bị trùng trong phiên kiểm kê.");
            }
        }
        List<Integer> ordered = request.partIds().stream().sorted().toList();
        for (Integer partId : ordered) {
            if (!sparePartRepository.existsById(partId)) {
                throw new ResourceNotFoundException("Không tìm thấy phụ tùng " + partId + ".");
            }
        }

        InventoryCheck check = new InventoryCheck();
        check.setCheckDate(LocalDateTime.now());
        check.setCreatedBy(staffId);
        check.setStatus(InventoryCheck.COUNTING);
        check.setNote(request.note() == null || request.note().isBlank() ? null : request.note().trim());
        check = checkRepository.saveAndFlush(check);

        for (Integer partId : ordered) {
            InventoryCheckItem item = new InventoryCheckItem();
            item.setCheckId(check.getId());
            item.setPartId(partId);
            item.setSystemQuantity(ledger.lock(partId)); // snapshot tồn hệ thống
            item.setAdjustmentApproved(false);
            itemRepository.save(item);
        }
        return get(check.getId());
    }

    /** Nhập tồn thực tế cho một phụ tùng; khi đã nhập đủ thì phiên tự chuyển trạng thái. Không đổi tồn. */
    @Transactional
    public CheckResponse setActual(Integer checkId, Integer partId, CheckActualRequest request) {
        InventoryCheck check = findCheck(checkId);
        if (!InventoryCheck.COUNTING.equals(check.getStatus())) {
            throw new ConflictException("Phiên kiểm kê không còn ở trạng thái đang kiểm kê.");
        }
        InventoryCheckItem item = itemRepository.findById(new InventoryCheckItem.Key(checkId, partId))
                .orElseThrow(() -> new ResourceNotFoundException("Phụ tùng không thuộc phiên kiểm kê này."));
        if (request.actualQuantity() == null || request.actualQuantity() < 0) {
            throw new BadRequestException("Số lượng thực tế không được âm.");
        }
        item.setActualQuantity(request.actualQuantity());
        item.setReason(request.reason() == null || request.reason().isBlank() ? null : request.reason().trim());
        itemRepository.saveAndFlush(item);

        List<InventoryCheckItem> items = itemRepository.findByCheckIdOrderByPartId(checkId);
        if (items.stream().allMatch(i -> i.getActualQuantity() != null)) {
            boolean hasDifference = items.stream().anyMatch(i -> i.difference() != 0);
            check.setStatus(hasDifference ? InventoryCheck.PENDING_APPROVAL : InventoryCheck.COMPLETED);
            checkRepository.saveAndFlush(check);
        }
        return get(checkId);
    }

    /** Chỉ MANAGER (kiểm tra ở controller): mới đặt tồn = thực tế và ghi biến động KIEM_KE. */
    @Transactional
    public CheckResponse approve(Integer checkId, String reason, Integer approverId) {
        InventoryCheck check = findCheck(checkId);
        requirePendingApproval(check);
        List<InventoryCheckItem> items = itemRepository.findByCheckIdOrderByPartId(checkId);
        Map<Integer, String> names = partNames(items);

        for (InventoryCheckItem item : items) {
            Integer difference = item.difference();
            if (difference == null || difference == 0) continue;

            int current = ledger.lock(item.getPartId());
            if (current != item.getSystemQuantity()) {
                throw new ConflictException("Tồn kho của '" + names.get(item.getPartId())
                        + "' đã thay đổi kể từ lúc kiểm kê (hệ thống " + item.getSystemQuantity()
                        + ", hiện tại " + current + "). Hãy tạo phiên kiểm kê mới.");
            }
            ledger.apply(item.getPartId(), current, item.getActualQuantity(), StockLedger.COUNT,
                    Math.abs(difference), null, null, "Điều chỉnh tồn sau kiểm kê #" + checkId);
            item.setAdjustmentApproved(true);
            itemRepository.save(item);
        }

        check.setStatus(InventoryCheck.COMPLETED);
        check.setApprovedBy(approverId);
        check.setApprovedAt(LocalDateTime.now());
        check.setDecisionReason(normalize(reason));
        checkRepository.saveAndFlush(check);
        return get(checkId);
    }

    /** Từ chối: tồn không đổi; giữ lý do và trạng thái DA_TU_CHOI. */
    @Transactional
    public CheckResponse reject(Integer checkId, String reason, Integer approverId) {
        InventoryCheck check = findCheck(checkId);
        requirePendingApproval(check);
        String normalized = normalize(reason);
        if (normalized == null) {
            throw new BadRequestException("Vui lòng nhập lý do từ chối.");
        }
        check.setStatus(InventoryCheck.REJECTED);
        check.setApprovedBy(approverId);
        check.setApprovedAt(LocalDateTime.now());
        check.setDecisionReason(normalized);
        checkRepository.saveAndFlush(check);
        return get(checkId);
    }

    @Transactional(readOnly = true)
    public CheckResponse get(Integer checkId) {
        InventoryCheck check = findCheck(checkId);
        List<InventoryCheckItem> items = itemRepository.findByCheckIdOrderByPartId(checkId);
        Map<Integer, String> names = partNames(items);
        List<CheckResponse.Item> lines = items.stream()
                .map(item -> new CheckResponse.Item(
                        item.getPartId(), names.getOrDefault(item.getPartId(), "Phụ tùng " + item.getPartId()),
                        item.getSystemQuantity(), item.getActualQuantity(), item.difference(),
                        item.getReason(), item.isAdjustmentApproved()))
                .toList();
        return new CheckResponse(check.getId(), check.getCheckDate(), check.getCreatedBy(), check.getApprovedBy(),
                check.getApprovedAt(), check.getStatus(), check.getNote(), check.getDecisionReason(), lines);
    }

    @Transactional(readOnly = true)
    public PageResponse<CheckSummaryResponse> getAll(int page, int size) {
        Page<InventoryCheck> checks = checkRepository.findAllByOrderByIdDesc(
                PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE)));
        List<Integer> ids = checks.getContent().stream().map(InventoryCheck::getId).toList();
        Map<Integer, List<InventoryCheckItem>> byCheck = ids.isEmpty() ? Map.of()
                : itemRepository.findByCheckIdIn(ids).stream()
                        .collect(Collectors.groupingBy(InventoryCheckItem::getCheckId));
        return PageResponse.of(checks, check -> {
            List<InventoryCheckItem> items = byCheck.getOrDefault(check.getId(), List.of());
            int differences = (int) items.stream().filter(i -> i.difference() != null && i.difference() != 0).count();
            return new CheckSummaryResponse(check.getId(), check.getCheckDate(), check.getCreatedBy(),
                    check.getApprovedBy(), check.getStatus(), check.getNote(), items.size(), differences);
        });
    }

    private InventoryCheck findCheck(Integer id) {
        return checkRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiên kiểm kê."));
    }

    private void requirePendingApproval(InventoryCheck check) {
        if (!InventoryCheck.PENDING_APPROVAL.equals(check.getStatus())) {
            throw new ConflictException("Phiên kiểm kê không ở trạng thái chờ phê duyệt.");
        }
    }

    private Map<Integer, String> partNames(List<InventoryCheckItem> items) {
        Set<Integer> ids = items.stream().map(InventoryCheckItem::getPartId).collect(Collectors.toSet());
        Map<Integer, String> names = new HashMap<>();
        if (!ids.isEmpty()) {
            for (SparePart part : sparePartRepository.findAllById(ids)) names.put(part.getId(), part.getName());
        }
        return names;
    }

    private String normalize(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }
}
