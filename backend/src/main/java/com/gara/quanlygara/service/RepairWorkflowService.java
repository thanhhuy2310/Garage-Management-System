package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.repair.RepairRequests;
import com.gara.quanlygara.entity.RepairOrder;
import com.gara.quanlygara.entity.RepairProgress;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.GarageServiceRepository;
import com.gara.quanlygara.repository.RepairOrderRepository;
import com.gara.quanlygara.repository.RepairProgressRepository;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
@Transactional
public class RepairWorkflowService {
    private static final Map<String, Set<String>> TRANSITIONS = Map.of(
            "MOI_TAO", Set.of("DANG_KIEM_TRA", "CHO_SUA", "DANG_SUA"),
            "DANG_KIEM_TRA", Set.of("CHO_SUA", "DANG_SUA"),
            "CHO_SUA", Set.of("DANG_SUA"),
            "DANG_SUA", Set.of("CHO_PHU_TUNG", "HOAN_TAT"),
            "CHO_PHU_TUNG", Set.of("DANG_SUA"));

    private final RepairOrderRepository orders;
    private final RepairProgressRepository progress;
    private final GarageServiceRepository services;
    private final RepairOrderQueryService queries;
    private final JdbcTemplate jdbc;

    public RepairWorkflowService(RepairOrderRepository orders, RepairProgressRepository progress,
                                 GarageServiceRepository services, RepairOrderQueryService queries,
                                 JdbcTemplate jdbc) {
        this.orders = orders;
        this.progress = progress;
        this.services = services;
        this.queries = queries;
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public List<Map<String, Object>> availableReceptions() {
        return jdbc.queryForList("""
                SELECT t.MaTiepNhan AS id, x.BienSo AS licensePlate, k.HoTen AS customerName
                FROM PhieuTiepNhan t JOIN Xe x ON x.MaXe = t.MaXe
                JOIN KhachHang k ON k.MaKhachHang = x.MaKhachHang
                WHERE NOT EXISTS (SELECT 1 FROM PhieuSuaChua p WHERE p.MaTiepNhan = t.MaTiepNhan)
                ORDER BY t.MaTiepNhan DESC
                """);
    }

    public RepairOrder create(RepairRequests.Create request, Authentication auth) {
        if (jdbc.queryForObject("SELECT COUNT(*) FROM PhieuTiepNhan WHERE MaTiepNhan = ?",
                Integer.class, request.receptionId()) == 0) {
            throw new ResourceNotFoundException("Không tìm thấy phiếu tiếp nhận.");
        }
        if (orders.existsByReceptionId(request.receptionId())) {
            throw new ConflictException("Phiếu tiếp nhận đã có phiếu sửa chữa.");
        }
        if (new HashSet<>(request.services().stream().map(RepairRequests.ServiceLine::serviceId).toList()).size()
                != request.services().size()) {
            throw new BadRequestException("Dịch vụ không được chọn trùng.");
        }
        RepairOrder order = new RepairOrder();
        order.setReceptionId(request.receptionId());
        order.setCreatedAt(now());
        order.setStatus("MOI_TAO");
        orders.saveAndFlush(order);
        for (var line : request.services()) {
            addLine(order.getId(), line);
        }
        log(order, null, "MOI_TAO", "Lập phiếu sửa chữa từ phiếu tiếp nhận #" + request.receptionId(), auth);
        return order;
    }

    public void addService(Integer id, RepairRequests.ServiceLine line, Authentication auth) {
        RepairOrder order = lockAccessible(id, auth);
        requireOpen(order);
        if (!Set.of("MOI_TAO", "DANG_KIEM_TRA", "CHO_SUA").contains(order.getStatus())) {
            throw new ConflictException("Chỉ bổ sung dịch vụ trước khi bắt đầu sửa chữa.");
        }
        if (jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu WHERE MaPhieuSuaChua = ? AND MaDichVu = ?",
                Integer.class, id, line.serviceId()) > 0) {
            throw new ConflictException("Dịch vụ đã có trên phiếu.");
        }
        addLine(id, line);
        log(order, line.serviceId(), "CHO_SUA", "Bổ sung dịch vụ vào phiếu.", auth);
    }

    public void updateProgress(Integer id, RepairRequests.Progress request, Authentication auth) {
        RepairOrder order = lockAccessible(id, auth);
        requireOpen(order);
        if (!order.getStatus().equals(request.expectedStatus())) {
            throw new ConflictException("Phiếu vừa được cập nhật. Vui lòng tải lại trước khi thao tác.");
        }
        if (!TRANSITIONS.getOrDefault(order.getStatus(), Set.of()).contains(request.status())) {
            throw new ConflictException("Không thể chuyển sang trạng thái này từ trạng thái hiện tại.");
        }
        if (jdbc.queryForObject("SELECT COUNT(*) FROM PhanCongKyThuatVien WHERE MaPhieuSuaChua = ?",
                Integer.class, id) == 0) {
            throw new ConflictException("Cần phân công kỹ thuật viên trước khi cập nhật tiến độ.");
        }
        if ("HOAN_TAT".equals(request.status())) {
            List<String> states = jdbc.queryForList("SELECT TrangThai FROM ChiTietDichVu WHERE MaPhieuSuaChua = ?",
                    String.class, id);
            if (states.isEmpty() || states.stream().anyMatch(s -> !"HOAN_TAT".equals(s))) {
                throw new ConflictException("Cần hoàn tất tất cả dịch vụ trước khi hoàn tất phiếu.");
            }
            order.setCompletedAt(now());
            order.setResult(request.notes());
        }
        if ("DANG_SUA".equals(request.status()) && order.getStartedAt() == null) order.setStartedAt(now());
        order.setStatus(request.status());
        orders.saveAndFlush(order);
        log(order, null, request.status(), request.notes(), auth);
    }

    public void updateServiceProgress(Integer id, Integer serviceId, RepairRequests.Progress request,
                                      Authentication auth) {
        RepairOrder order = lockAccessible(id, auth);
        requireOpen(order);
        if (!"DANG_SUA".equals(order.getStatus())) {
            throw new ConflictException("Phiếu phải ở trạng thái đang sửa chữa để cập nhật dịch vụ.");
        }
        var states = jdbc.queryForList("SELECT TrangThai FROM ChiTietDichVu WHERE MaPhieuSuaChua = ? AND MaDichVu = ?",
                String.class, id, serviceId);
        if (states.isEmpty()) throw new ResourceNotFoundException("Dịch vụ không có trên phiếu sửa chữa.");
        String previous = states.getFirst() == null ? "CHO_SUA" : states.getFirst();
        if (!previous.equals(request.expectedStatus())) {
            throw new ConflictException("Dịch vụ vừa được cập nhật. Vui lòng tải lại.");
        }
        boolean allowed = Set.of("CHO_SUA", "MOI_TAO", "CHUA_THUC_HIEN").contains(previous)
                ? "DANG_SUA".equals(request.status())
                : "DANG_SUA".equals(previous) && "HOAN_TAT".equals(request.status());
        if (!allowed) throw new ConflictException("Trạng thái dịch vụ không hợp lệ.");
        jdbc.update("UPDATE ChiTietDichVu SET TrangThai = ? WHERE MaPhieuSuaChua = ? AND MaDichVu = ?",
                request.status(), id, serviceId);
        log(order, serviceId, request.status(), request.notes(), auth);
    }

    private RepairOrder lockAccessible(Integer id, Authentication auth) {
        queries.getById(id, auth); // Includes assignment ownership for technicians.
        return orders.findForUpdate(id).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
    }

    private void requireOpen(RepairOrder order) {
        if (Set.of("HOAN_TAT", "HUY", "DA_HUY").contains(order.getStatus())) {
            throw new ConflictException("Phiếu đã kết thúc, không thể sửa nội dung hoặc tiến độ.");
        }
        if (jdbc.queryForObject("SELECT COUNT(*) FROM HoaDon WHERE MaPhieuSuaChua = ?", Integer.class, order.getId()) > 0) {
            throw new ConflictException("Phiếu đã lập hóa đơn, không thể thay đổi.");
        }
    }

    private void addLine(Integer orderId, RepairRequests.ServiceLine line) {
        var service = services.findById(line.serviceId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy dịch vụ."));
        jdbc.update("""
                INSERT INTO ChiTietDichVu (MaPhieuSuaChua, MaDichVu, SoLuong, DonGia, TrangThai)
                VALUES (?, ?, ?, ?, N'CHO_SUA')
                """, orderId, service.getId(), line.quantity(), service.getUnitPrice());
    }

    private void log(RepairOrder order, Integer serviceId, String status, String notes, Authentication auth) {
        progress.save(new RepairProgress(order.getId(), serviceId, status, notes, auth.getName(), now()));
    }

    private LocalDateTime now() { return LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).withNano(0); }
}
