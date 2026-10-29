package com.gara.quanlygara.repository;

import com.gara.quanlygara.dto.appointment.AppointmentDtos.*;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.jdbc.core.simple.SimpleJdbcInsert;
import org.springframework.stereotype.Repository;
import java.sql.Date;
import java.sql.Time;
import java.time.LocalDate;
import java.time.LocalTime;
import java.util.*;

@Repository
public class AppointmentRepository {
    private final JdbcTemplate jdbc;
    public AppointmentRepository(JdbcTemplate jdbc) { this.jdbc = jdbc; }
    private static final String SELECT = """
        SELECT l.*, k.HoTen, x.BienSo, x.HangXe, x.DongXe, x.NamSanXuat, x.SoKm,
               d.TenDichVu, d.LoaiDichVu, d.DonGia
        FROM LichHen l JOIN KhachHang k ON k.MaKhachHang=l.MaKhachHang
        JOIN Xe x ON x.MaXe=l.MaXe LEFT JOIN DichVu d ON d.MaDichVu=l.MaDichVu
        """;
    private static final RowMapper<View> MAPPER = (r, n) -> new View(
        r.getInt("MaLichHen"), r.getInt("MaKhachHang"), r.getString("HoTen"), r.getInt("MaXe"),
        r.getString("BienSo"), r.getString("HangXe"), r.getString("DongXe"),
        r.getObject("NamSanXuat") == null ? null : r.getInt("NamSanXuat"),
        r.getObject("SoKm", Integer.class), r.getObject("MaDichVu", Integer.class),
        r.getString("TenDichVu"), r.getString("LoaiDichVu"), r.getBigDecimal("DonGia"),
        r.getDate("NgayHen").toLocalDate(), r.getTime("GioHen").toLocalTime(),
        r.getString("NoiDung"), r.getString("TrangThai"), r.getInt("PhienBan"));

    // Transaction-owned lock: capacity checks, insert, update and audit commit atomically.
    // All application instances use the same SQL resource; no in-process mutex.
    public void lockBooking() {
        if (!org.springframework.transaction.support.TransactionSynchronizationManager.isActualTransactionActive())
            throw new IllegalStateException("Booking lock requires a Spring transaction");
        Integer result = jdbc.queryForObject("""
            -- JDBC implicit transactions do not start for EXEC alone.
            -- Spring owns the connection and commits/rolls back this transaction.
            IF @@TRANCOUNT = 0 BEGIN TRANSACTION;
            DECLARE @r INT;
            EXEC @r=sys.sp_getapplock @Resource=N'garage-appointments', @LockMode='Exclusive',
                 @LockOwner='Transaction', @LockTimeout=10000;
            SELECT @r;
            """, Integer.class);
        if (result == null || result < 0) throw new ConflictException("Lịch đang được cập nhật. Vui lòng thử lại.");
    }
    public List<View> list(Integer customerId) {
        return customerId == null
            ? jdbc.query(SELECT + " ORDER BY l.NgayHen DESC,l.GioHen DESC,l.MaLichHen DESC", MAPPER)
            : jdbc.query(SELECT + " WHERE l.MaKhachHang=? ORDER BY l.NgayHen DESC,l.GioHen DESC,l.MaLichHen DESC", MAPPER, customerId);
    }
    public View get(int id) {
        return jdbc.query(SELECT + " WHERE l.MaLichHen=?", MAPPER, id).stream().findFirst()
            .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy lịch hẹn."));
    }
    public Integer activeVehicleOwner(int vehicleId) {
        return jdbc.query("SELECT x.MaKhachHang FROM Xe x JOIN KhachHang k ON k.MaKhachHang=x.MaKhachHang WHERE x.MaXe=? AND k.TrangThai=1",
            (r,n) -> r.getInt(1), vehicleId).stream().findFirst().orElse(null);
    }
    public boolean activeService(int id) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM DichVu WHERE MaDichVu=? AND TrangThai=1", Integer.class, id) > 0;
    }
    public List<Schedule> schedule() {
        return jdbc.query("SELECT Thu,Gio,SucChua FROM KhungGioTiepNhan ORDER BY Thu,Gio",
            (r,n) -> new Schedule(r.getInt(1), r.getTime(2).toLocalTime(), r.getInt(3)));
    }
    public int occupied(LocalDate date, LocalTime time, int excludedId) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM LichHen WHERE NgayHen=? AND GioHen=? AND MaLichHen<>? AND TrangThai NOT IN (N'HUY',N'DA_HUY')",
            Integer.class, Date.valueOf(date), time.toString(), excludedId);
    }
    public boolean duplicateVehicle(int vehicleId, LocalDate date, LocalTime time, int excludedId) {
        return jdbc.queryForObject("SELECT COUNT(*) FROM LichHen WHERE MaXe=? AND NgayHen=? AND GioHen=? AND MaLichHen<>? AND TrangThai NOT IN (N'HUY',N'DA_HUY')",
            Integer.class, vehicleId, Date.valueOf(date), time.toString(), excludedId) > 0;
    }
    public int create(Create input, int customerId) {
        Map<String,Object> values = new LinkedHashMap<>();
        values.put("MaKhachHang", customerId); values.put("MaXe", input.vehicleId());
        values.put("MaDichVu", input.serviceId()); values.put("NgayHen", Date.valueOf(input.date()));
        values.put("GioHen", input.time().toString()); values.put("NoiDung", input.note());
        values.put("TrangThai", "CHO_XAC_NHAN");
        values.put("NgayTao", java.sql.Timestamp.valueOf(java.time.LocalDateTime.now(java.time.ZoneId.of("Asia/Ho_Chi_Minh"))));
        return new SimpleJdbcInsert(jdbc).withTableName("LichHen").usingGeneratedKeyColumns("MaLichHen")
            .usingColumns(values.keySet().toArray(String[]::new)).executeAndReturnKey(values).intValue();
    }
    public void update(int id, int version, LocalDate date, LocalTime time, String status) {
        int changed = jdbc.update("UPDATE LichHen SET NgayHen=?,GioHen=?,TrangThai=?,PhienBan=PhienBan+1,NgayCapNhat=SYSDATETIME() WHERE MaLichHen=? AND PhienBan=?",
            Date.valueOf(date), time.toString(), status, id, version);
        if (changed != 1) throw new ConflictException("Lịch đã thay đổi. Vui lòng tải lại trước khi thao tác.");
    }
    public void audit(View item, int accountId, String action, String reason) {
        jdbc.update("INSERT INTO LichSuLichHen(MaLichHen,MaTaiKhoan,HanhDong,NgayHen,GioHen,TrangThai,PhienBan,LyDo) VALUES(?,?,?,?,?,?,?,?)",
            item.id(), accountId, action, Date.valueOf(item.date()), item.time().toString(), item.status(), item.version(), reason);
    }
    public List<Audit> history(int id) {
        return jdbc.query("SELECT * FROM LichSuLichHen WHERE MaLichHen=? ORDER BY Id", (r,n) ->
            new Audit(r.getLong("Id"),r.getInt("MaTaiKhoan"),r.getString("HanhDong"),r.getDate("NgayHen").toLocalDate(),
                r.getTime("GioHen").toLocalTime(),r.getString("TrangThai"),r.getInt("PhienBan"),r.getString("LyDo"),
                r.getTimestamp("ThoiGian").toLocalDateTime()), id);
    }
    public void saveSchedule(Schedule slot, int accountId) {
        if (jdbc.update("UPDATE KhungGioTiepNhan SET SucChua=?,MaTaiKhoanCapNhat=?,NgayCapNhat=SYSDATETIME() WHERE Thu=? AND Gio=?",
                slot.capacity(), accountId, slot.dayOfWeek(), slot.time().toString()) == 0)
            jdbc.update("INSERT INTO KhungGioTiepNhan(Thu,Gio,SucChua,MaTaiKhoanCapNhat) VALUES(?,?,?,?)",
                slot.dayOfWeek(), slot.time().toString(), slot.capacity(), accountId);
    }
}
