package com.gara.quanlygara.service;

import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.TechnicianRepository;
import jakarta.validation.constraints.*;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.util.*;

@Service
public class TechnicianWorkloadService {
    private final JdbcTemplate jdbc;
    private final TechnicianRepository technicians;
    public TechnicianWorkloadService(JdbcTemplate jdbc, TechnicianRepository technicians) {
        this.jdbc = jdbc; this.technicians = technicians;
    }
    public record Shift(Integer id, String name, LocalTime start, LocalTime end) {}
    public record ShiftRequest(@NotBlank @Size(max=100) String name, @NotNull LocalTime start, @NotNull LocalTime end) {}
    public record ScheduleRequest(@NotNull LocalDate date, @NotNull List<@NotNull Integer> shiftIds,
                                  @Min(1) @Max(100) int vehicleLimit) {}
    public record Workload(int id, String fullName, int activeVehicles, int pendingTasks,
                           int completedToday, int vehicleLimit, String status, String shiftStatus,
                           boolean assignable, List<Shift> shifts) {}
    private static final String ACTIVE = """
        r.TrangThai NOT IN ('HOAN_TAT','HUY','DA_HUY') AND (
          r.TrangThai IN ('MOI_TAO','DANG_KIEM_TRA') OR
          EXISTS (SELECT 1 FROM ChiTietDichVu d WHERE d.MaPhieuSuaChua=r.MaPhieuSuaChua
                  AND COALESCE(d.TrangThai,'CHO_SUA') NOT IN ('HOAN_TAT','HUY','DA_HUY')))
        """;
    public List<Shift> shifts() {
        return jdbc.query("SELECT Id,TenCa,BatDau,KetThuc FROM CaLamKyThuatVien ORDER BY BatDau,Id",
                (rs,n)->new Shift(rs.getInt(1),rs.getString(2),rs.getTime(3).toLocalTime(),rs.getTime(4).toLocalTime()));
    }
    @Transactional
    public void saveShift(Integer id, ShiftRequest request) {
        if (!request.start().isBefore(request.end())) throw new ConflictException("Giờ kết thúc phải sau giờ bắt đầu.");
        if (id == null) jdbc.update("INSERT INTO CaLamKyThuatVien(TenCa,BatDau,KetThuc) VALUES (?,?,?)",
                request.name().trim(),request.start(),request.end());
        else if (jdbc.update("UPDATE CaLamKyThuatVien SET TenCa=?,BatDau=?,KetThuc=? WHERE Id=?",
                request.name().trim(),request.start(),request.end(),id)==0) throw new ResourceNotFoundException("Không tìm thấy ca làm.");
    }
    @Transactional
    public void saveSchedule(int id, ScheduleRequest request) {
        technicians.findForUpdate(id).orElseThrow(()->new ResourceNotFoundException("Không tìm thấy kỹ thuật viên."));
        var selected = shifts().stream().filter(s->request.shiftIds().contains(s.id())).toList();
        if (selected.size()!=new HashSet<>(request.shiftIds()).size()) throw new ConflictException("Ca làm không tồn tại.");
        for (int i=1;i<selected.size();i++) if (selected.get(i).start().isBefore(selected.get(i-1).end()))
            throw new ConflictException("Các ca làm không được trùng giờ.");
        if (activeVehicles(id)>request.vehicleLimit()) throw new ConflictException("Giới hạn mới thấp hơn số xe đang xử lý.");
        jdbc.update("UPDATE KyThuatVien SET GioiHanXe=? WHERE MaNhanVien=?",request.vehicleLimit(),id);
        jdbc.update("DELETE FROM LichLamKyThuatVien WHERE MaKyThuatVien=? AND Ngay=?",id,request.date());
        for (Shift shift:selected) jdbc.update("INSERT INTO LichLamKyThuatVien(MaKyThuatVien,Ngay,MaCa) VALUES (?,?,?)",id,request.date(),shift.id());
    }
    int activeVehicles(int id) {
        return jdbc.queryForObject("SELECT COUNT(DISTINCT r.MaPhieuSuaChua) FROM PhieuSuaChua r JOIN PhanCongKyThuatVien a ON a.MaPhieuSuaChua=r.MaPhieuSuaChua WHERE a.MaKyThuatVien=? AND "+ACTIVE,Integer.class,id);
    }
    @Transactional(readOnly=true)
    public List<Workload> list(LocalDate date) {
        return technicians.findOptions().stream().map(t->load(t.id(),t.fullName(),date))
                .sorted(Comparator.comparing(Workload::assignable).reversed().thenComparingInt(Workload::activeVehicles)
                        .thenComparingInt(Workload::pendingTasks).thenComparing(Workload::fullName)).toList();
    }
    private Workload load(int id, String name, LocalDate date) {
        var now=LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh"));
        var shifts=jdbc.query("SELECT c.Id,c.TenCa,c.BatDau,c.KetThuc FROM LichLamKyThuatVien l JOIN CaLamKyThuatVien c ON c.Id=l.MaCa WHERE l.MaKyThuatVien=? AND l.Ngay=? ORDER BY c.BatDau",
                (rs,n)->new Shift(rs.getInt(1),rs.getString(2),rs.getTime(3).toLocalTime(),rs.getTime(4).toLocalTime()),id,date);
        boolean onShift=date.equals(now.toLocalDate()) && shifts.stream().anyMatch(s->!now.toLocalTime().isBefore(s.start()) && now.toLocalTime().isBefore(s.end()));
        int limit=jdbc.queryForObject("SELECT GioiHanXe FROM KyThuatVien WHERE MaNhanVien=?",Integer.class,id);
        int active=activeVehicles(id);
        int pending=jdbc.queryForObject("SELECT COUNT(*) FROM ChiTietDichVu d JOIN PhieuSuaChua r ON r.MaPhieuSuaChua=d.MaPhieuSuaChua JOIN PhanCongKyThuatVien a ON a.MaPhieuSuaChua=r.MaPhieuSuaChua WHERE a.MaKyThuatVien=? AND r.TrangThai NOT IN ('HOAN_TAT','HUY','DA_HUY') AND COALESCE(d.TrangThai,'CHO_SUA') NOT IN ('HOAN_TAT','HUY','DA_HUY')",Integer.class,id);
        int completed=jdbc.queryForObject("SELECT COUNT(*) FROM PhieuSuaChua r JOIN PhanCongKyThuatVien a ON a.MaPhieuSuaChua=r.MaPhieuSuaChua WHERE a.MaKyThuatVien=? AND r.TrangThai='HOAN_TAT' AND r.NgayHoanThanh>=? AND r.NgayHoanThanh<?",Integer.class,id,date.atStartOfDay(),date.plusDays(1).atStartOfDay());
        return new Workload(id,name,active,pending,completed,limit,active>0?"Đang bận":"Còn trống",
                shifts.isEmpty()?"Nghỉ / chưa xếp ca":onShift?"Trong ca":"Ngoài ca",onShift && active<limit,shifts);
    }
    // Caller holds the technician row lock until the assignment transaction commits.
    public void requireAssignable(int id) {
        var state=load(id,"",LocalDate.now(ZoneId.of("Asia/Ho_Chi_Minh")));
        if (!"Trong ca".equals(state.shiftStatus())) throw new ConflictException("Kỹ thuật viên đang nghỉ hoặc ngoài ca.");
        if (!state.assignable()) throw new ConflictException("Kỹ thuật viên đã đạt giới hạn xe đang xử lý.");
    }
}
