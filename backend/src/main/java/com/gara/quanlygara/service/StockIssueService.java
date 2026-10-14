// TV3-TUAN8
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.warehouse.ConfirmUsageRequest;
import com.gara.quanlygara.dto.warehouse.IssueRequest;
import com.gara.quanlygara.dto.warehouse.IssueResponse;
import com.gara.quanlygara.dto.warehouse.PageResponse;
import com.gara.quanlygara.entity.RepairPartItem;
import com.gara.quanlygara.entity.SparePart;
import com.gara.quanlygara.entity.StockIssue;
import com.gara.quanlygara.entity.StockIssueItem;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairPartItemRepository;
import com.gara.quanlygara.repository.RepairServiceItemRepository;
import com.gara.quanlygara.repository.SparePartRepository;
import com.gara.quanlygara.repository.StockIssueItemRepository;
import com.gara.quanlygara.repository.StockIssueRepository;
import com.gara.quanlygara.repository.StockMovementRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.security.access.AccessDeniedException;
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
 * Xuất kho = cấp phát phụ tùng cho phiếu sửa chữa.
 *  - Tạo phiếu xuất: kiểm tra tồn khả dụng, ghi số lượng cấp phát, KHÔNG giảm tồn, KHÔNG ghi biến động.
 *  - KTV xác nhận thực dùng (0..cấp phát): đây là thao tác DUY NHẤT giảm tồn, theo số lượng thực dùng;
 *    phần còn lại (cấp phát - thực dùng) là hoàn trả. Cùng quy tắc với dbo.sp_XacNhanSuDungPhuTung.
 */
@Service
public class StockIssueService {

    public static final String PENDING = "CHO_XAC_NHAN";
    public static final String CONFIRMED = "DA_XAC_NHAN";

    // Cùng điều kiện với dbo.sp_XacNhanSuDungPhuTung (lỗi 50016).
    private static final Set<String> ISSUABLE_ORDER_STATUSES = Set.of("DANG_SUA", "CHO_PHU_TUNG");
    private static final int MAX_PAGE_SIZE = 100;

    private final StockIssueRepository issueRepository;
    private final StockIssueItemRepository itemRepository;
    private final SparePartRepository sparePartRepository;
    private final StockMovementRepository movementRepository;
    private final RepairPartItemRepository repairPartItemRepository;
    private final RepairServiceItemRepository repairServiceItemRepository;
    private final StockLedger ledger;

    public StockIssueService(
            StockIssueRepository issueRepository,
            StockIssueItemRepository itemRepository,
            SparePartRepository sparePartRepository,
            StockMovementRepository movementRepository,
            RepairPartItemRepository repairPartItemRepository,
            RepairServiceItemRepository repairServiceItemRepository,
            StockLedger ledger
    ) {
        this.issueRepository = issueRepository;
        this.itemRepository = itemRepository;
        this.sparePartRepository = sparePartRepository;
        this.movementRepository = movementRepository;
        this.repairPartItemRepository = repairPartItemRepository;
        this.repairServiceItemRepository = repairServiceItemRepository;
        this.ledger = ledger;
    }

    @Transactional
    public IssueResponse create(IssueRequest request, Integer warehouseStaffId) {
        Set<Integer> seen = new HashSet<>();
        for (IssueRequest.Item item : request.items()) {
            if (!seen.add(item.partId())) {
                throw new BadRequestException("Phụ tùng " + item.partId() + " bị trùng trong phiếu xuất.");
            }
        }

        String orderStatus = repairServiceItemRepository.findRepairOrderStatus(request.repairOrderId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
        if (orderStatus == null || !ISSUABLE_ORDER_STATUSES.contains(orderStatus.trim())) {
            throw new ConflictException("Phiếu sửa chữa không ở trạng thái cho phép cấp phát phụ tùng.");
        }
        if (request.requestedTechnicianId() != null
                && itemRepository.countAssignment(request.repairOrderId(), request.requestedTechnicianId()) == 0) {
            throw new ConflictException("Kỹ thuật viên chưa được phân công cho phiếu sửa chữa này.");
        }

        List<IssueRequest.Item> ordered = request.items().stream()
                .sorted(Comparator.comparing(IssueRequest.Item::partId)).toList();
        Map<Integer, SparePart> parts = new HashMap<>();
        for (IssueRequest.Item item : ordered) {
            SparePart part = sparePartRepository.findById(item.partId())
                    .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phụ tùng " + item.partId() + "."));
            parts.put(part.getId(), part);
        }

        // Kiểm tra tồn khả dụng = tồn - phần đã cấp phát chưa xác nhận. Khóa dòng phụ tùng để tuần tự hóa các phiếu đồng thời.
        for (IssueRequest.Item item : ordered) {
            int stock = ledger.lock(item.partId());
            long pending = itemRepository.sumPendingAllocation(item.partId());
            long available = stock - pending;
            if (available < item.quantity()) {
                throw new ConflictException("Không đủ tồn khả dụng cho '" + parts.get(item.partId()).getName()
                        + "': tồn " + stock + ", đã cấp phát chờ xác nhận " + pending
                        + ", yêu cầu " + item.quantity() + ".");
            }
        }

        StockIssue issue = new StockIssue();
        issue.setRepairOrderId(request.repairOrderId());
        issue.setWarehouseStaffId(warehouseStaffId);
        issue.setRequestedTechnicianId(request.requestedTechnicianId());
        issue.setIssueDate(LocalDateTime.now());
        issue.setReason(request.reason().trim());
        issue = issueRepository.saveAndFlush(issue);

        for (IssueRequest.Item item : ordered) {
            StockIssueItem detail = new StockIssueItem();
            detail.setIssueId(issue.getId());
            detail.setPartId(item.partId());
            detail.setQuantity(item.quantity());
            detail.setUnitPrice(parts.get(item.partId()).getUnitPrice());
            detail.setConfirmed(false);
            itemRepository.save(detail);
        }
        // Không gọi ledger.apply: cấp phát KHÔNG giảm tồn và không ghi BienDongKho.
        return toResponse(issue, itemRepository.findByIssueId(issue.getId()), names(parts));
    }

    @Transactional
    public IssueResponse.Item confirmUsage(
            Integer issueId, Integer partId, ConfirmUsageRequest request,
            Integer callerEmployeeId, boolean callerIsTechnician
    ) {
        StockIssueItem item = itemRepository.findForUpdate(issueId, partId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy chi tiết phiếu xuất."));
        if (item.isConfirmed()) {
            throw new ConflictException("Phụ tùng này đã được xác nhận sử dụng.");
        }
        StockIssue issue = issueRepository.findById(issueId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu xuất kho."));
        Integer orderId = issue.getRepairOrderId();
        if (orderId == null) {
            throw new ConflictException("Phiếu xuất này không gắn với phiếu sửa chữa.");
        }

        Integer technicianId = resolveTechnician(request, callerEmployeeId, callerIsTechnician);
        if (itemRepository.countAssignment(orderId, technicianId) == 0) {
            throw new ConflictException("Kỹ thuật viên không được phân công cho phiếu sửa chữa này.");
        }
        if (itemRepository.countConfirmedQuotation(orderId) == 0) {
            throw new ConflictException("Báo giá chưa được khách hàng xác nhận.");
        }
        String orderStatus = repairServiceItemRepository.findRepairOrderStatus(orderId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
        if (orderStatus == null || !ISSUABLE_ORDER_STATUSES.contains(orderStatus.trim())) {
            throw new ConflictException("Phiếu sửa chữa không ở trạng thái cho phép xác nhận sử dụng phụ tùng.");
        }

        int issued = item.getQuantity();
        int actual = request.actualUsed();
        if (actual < 0 || actual > issued) {
            throw new BadRequestException("Số lượng thực dùng phải từ 0 đến số lượng cấp phát (" + issued + ").");
        }

        Integer stockAfter = null;
        if (actual > 0) {
            int before = ledger.lock(partId);
            if (before < actual) {
                throw new ConflictException("Số lượng tồn kho không đủ để xác nhận sử dụng.");
            }
            stockAfter = before - actual;
            // Tồn giảm theo SỐ LƯỢNG THỰC DÙNG, không phải số cấp phát.
            ledger.apply(partId, before, stockAfter, StockLedger.OUT, actual, null, issueId,
                    "KTV xác nhận thực dùng " + actual + "/" + issued + " (hoàn trả " + (issued - actual) + ")");
        }

        item.setConfirmed(true);
        item.setConfirmedAt(LocalDateTime.now());
        item.setConfirmedTechnicianId(technicianId);
        item.setActualUsedQuantity(actual);
        item.setReturnedQuantity(issued - actual);
        itemRepository.saveAndFlush(item);

        syncRepairPartLine(orderId, partId, item);

        SparePart part = sparePartRepository.findById(partId).orElse(null);
        return toItem(item, part == null ? "Phụ tùng " + partId : part.getName(), stockAfter);
    }

    @Transactional(readOnly = true)
    public IssueResponse get(Integer id) {
        return get(id, 0);
    }

    /** technicianId = 0: không giới hạn; khác 0: chỉ được xem phiếu liên quan tới KTV đó, ngược lại AccessDenied (403). */
    @Transactional(readOnly = true)
    public IssueResponse get(Integer id, int technicianId) {
        if (technicianId != 0 && issueRepository.countRelatedToTechnician(id, technicianId) == 0) {
            throw new AccessDeniedException("Bạn không có quyền xem phiếu xuất này.");
        }
        StockIssue issue = issueRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu xuất kho."));
        List<StockIssueItem> items = itemRepository.findByIssueId(id);
        return toResponse(issue, items, partNames(items));
    }

    /** technicianId = 0: tất cả phiếu; khác 0: chỉ phiếu liên quan tới kỹ thuật viên đó. */
    @Transactional(readOnly = true)
    public PageResponse<IssueResponse> getAll(int page, int size, int technicianId) {
        PageRequest pageable = PageRequest.of(Math.max(page, 0), Math.min(Math.max(size, 1), MAX_PAGE_SIZE));
        Page<StockIssue> issues;
        if (technicianId == 0) {
            issues = issueRepository.findAllByOrderByIdDesc(pageable);
        } else {
            List<Integer> ids = issueRepository.findIdsRelatedToTechnician(technicianId);
            if (ids.isEmpty()) {
                return new PageResponse<>(List.of(), pageable.getPageNumber(), pageable.getPageSize(), 0, 0);
            }
            issues = issueRepository.findByIdInOrderByIdDesc(ids, pageable);
        }

        List<Integer> issueIds = issues.getContent().stream().map(StockIssue::getId).toList();
        List<StockIssueItem> allItems = issueIds.isEmpty() ? List.of() : itemRepository.findByIssueIdIn(issueIds);
        Map<Integer, String> names = partNames(allItems);
        Map<Integer, List<StockIssueItem>> byIssue = allItems.stream()
                .collect(Collectors.groupingBy(StockIssueItem::getIssueId));
        return PageResponse.of(issues, issue ->
                toResponse(issue, byIssue.getOrDefault(issue.getId(), List.of()), names));
    }

    private Integer resolveTechnician(ConfirmUsageRequest request, Integer callerEmployeeId, boolean callerIsTechnician) {
        if (callerIsTechnician) {
            if (request.technicianId() != null && !request.technicianId().equals(callerEmployeeId)) {
                throw new AccessDeniedException("Kỹ thuật viên chỉ được xác nhận với tài khoản của chính mình.");
            }
            return callerEmployeeId;
        }
        if (request.technicianId() == null) {
            throw new BadRequestException("Vui lòng chọn kỹ thuật viên xác nhận.");
        }
        return request.technicianId();
    }

    /**
     * ChiTietPhuTung.SoLuong của (phiếu sửa chữa, phụ tùng) = tổng số lượng THỰC DÙNG đã xác nhận
     * (không phải số cấp phát), đồng thời thay thế số lượng dự kiến do người dùng nhập ở Tuần 7.
     * Nếu tổng thực dùng = 0 thì không đụng tới dòng sẵn có (ràng buộc SoLuong > 0, và không xóa dữ liệu người dùng).
     */
    private void syncRepairPartLine(Integer orderId, Integer partId, StockIssueItem item) {
        long total = itemRepository.sumConfirmedActual(orderId, partId);
        if (total <= 0) return;

        BigDecimal unitPrice = item.getUnitPrice();
        if (unitPrice == null) {
            unitPrice = sparePartRepository.findById(partId).map(SparePart::getUnitPrice).orElse(null);
        }
        if (unitPrice == null) {
            throw new ConflictException("Không xác định được đơn giá phụ tùng.");
        }

        RepairPartItem line = repairPartItemRepository.findById(new RepairPartItem.Key(orderId, partId))
                .orElseGet(() -> {
                    RepairPartItem created = new RepairPartItem();
                    created.setRepairOrderId(orderId);
                    created.setSparePartId(partId);
                    return created;
                });
        line.setQuantity((int) total);
        line.setUnitPrice(unitPrice.setScale(2, RoundingMode.HALF_UP));
        repairPartItemRepository.saveAndFlush(line);
    }

    private Map<Integer, String> names(Map<Integer, SparePart> parts) {
        Map<Integer, String> names = new HashMap<>();
        parts.forEach((id, part) -> names.put(id, part.getName()));
        return names;
    }

    private Map<Integer, String> partNames(List<StockIssueItem> items) {
        Set<Integer> ids = items.stream().map(StockIssueItem::getPartId).collect(Collectors.toSet());
        Map<Integer, String> names = new HashMap<>();
        if (!ids.isEmpty()) {
            sparePartRepository.findAllById(ids).forEach(part -> names.put(part.getId(), part.getName()));
        }
        return names;
    }

    private IssueResponse toResponse(StockIssue issue, List<StockIssueItem> items, Map<Integer, String> names) {
        List<IssueResponse.Item> lines = items.stream()
                .sorted(Comparator.comparing(StockIssueItem::getPartId))
                .map(item -> toItem(item, names.getOrDefault(item.getPartId(), "Phụ tùng " + item.getPartId()),
                        stockAfter(item)))
                .toList();
        return new IssueResponse(issue.getId(), issue.getRepairOrderId(), issue.getWarehouseStaffId(),
                issue.getRequestedTechnicianId(), issue.getIssueDate(), issue.getReason(), lines);
    }

    private Integer stockAfter(StockIssueItem item) {
        if (!item.isConfirmed() || item.getActualUsedQuantity() == null || item.getActualUsedQuantity() == 0) return null;
        return movementRepository
                .findFirstByIssueIdAndPartIdAndTypeOrderByIdDesc(item.getIssueId(), item.getPartId(), StockLedger.OUT)
                .map(movement -> movement.getQuantityAfter())
                .orElse(null);
    }

    private IssueResponse.Item toItem(StockIssueItem item, String partName, Integer stockAfter) {
        return new IssueResponse.Item(
                item.getPartId(), partName, item.getQuantity(), item.getUnitPrice(),
                item.isConfirmed() ? CONFIRMED : PENDING, item.getConfirmedAt(), item.getConfirmedTechnicianId(),
                item.getActualUsedQuantity(), item.getReturnedQuantity(), stockAfter);
    }
}
