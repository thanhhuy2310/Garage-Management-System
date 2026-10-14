package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.repair.RepairOrderDetailResponse;
import com.gara.quanlygara.entity.AccountRole;
import com.gara.quanlygara.exception.ForbiddenException;
import com.gara.quanlygara.exception.UnauthorizedException;
import com.gara.quanlygara.mapper.RepairOrderMapper;
import com.gara.quanlygara.repository.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;

@Service
@Transactional(readOnly = true)
public class CustomerRepairService {
    private final AccountRepository accounts;
    private final RepairOrderRepository orders;
    private final RepairProgressRepository progress;
    private final TechnicianAssignmentRepository assignments;
    private final RepairOrderMapper mapper;
    private final JdbcTemplate jdbc;
    public CustomerRepairService(AccountRepository accounts, RepairOrderRepository orders,
            RepairProgressRepository progress, TechnicianAssignmentRepository assignments,
            RepairOrderMapper mapper, JdbcTemplate jdbc) {
        this.accounts = accounts;
        this.orders = orders;
        this.progress = progress;
        this.assignments = assignments;
        this.mapper = mapper;
        this.jdbc = jdbc;
    }

    public List<RepairOrderDetailResponse> getMyRepairs(String username) {
        var account = accounts.findByUsername(username)
                .orElseThrow(() -> new UnauthorizedException("Bạn cần đăng nhập lại."));
        if (!account.isActive() || account.getRole() != AccountRole.CUSTOMER || account.getCustomerId() == null) {
            throw new ForbiddenException("Tài khoản chưa được liên kết với khách hàng.");
        }
        // Customer identity comes only from the authenticated account, never from a query parameter.
        var ids = jdbc.queryForList("""
                SELECT p.MaPhieuSuaChua FROM PhieuSuaChua p
                JOIN PhieuTiepNhan t ON t.MaTiepNhan = p.MaTiepNhan
                JOIN Xe x ON x.MaXe = t.MaXe WHERE x.MaKhachHang = ?
                ORDER BY p.NgayLap DESC, p.MaPhieuSuaChua DESC
                """, Integer.class, account.getCustomerId());
        return ids.stream().map(id -> new RepairOrderDetailResponse(
                mapper.toResponse(orders.findOverviews(id, 0).getFirst()),
                orders.findServiceLines(id).stream().map(mapper::toServiceLine).toList(),
                assignments.findAssignments(id), progress.findByRepairOrderIdOrderByCreatedAtDescIdDesc(id))).toList();
    }
}
