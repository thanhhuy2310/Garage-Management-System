package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.report.ReportResponse;
import com.gara.quanlygara.exception.BadRequestException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.YearMonth;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Service
public class ReportService {
    private static final BigDecimal ZERO = BigDecimal.ZERO.setScale(2);
    private final JdbcTemplate jdbc;

    public ReportService(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Transactional(readOnly = true)
    public ReportResponse overview(LocalDate from, LocalDate to) {
        if (from == null || to == null) {
            throw new BadRequestException("Vui lòng chọn đầy đủ thời gian báo cáo.");
        }
        if (from.isAfter(to)) {
            throw new BadRequestException("Ngày bắt đầu không được sau ngày kết thúc.");
        }
        LocalDateTime start = from.atStartOfDay();
        LocalDateTime end = to.plusDays(1).atStartOfDay();
        return new ReportResponse(
                from,
                to,
                billing(start, end),
                repairs(start, end),
                inventory(start, end),
                vehicleStatuses(end),
                trends(from, to, start, end),
                partMovements(start, end),
                technicianPerformance(start, end)
        );
    }

    private ReportResponse.BillingSummary billing(LocalDateTime start, LocalDateTime end) {
        return jdbc.queryForObject("""
                SELECT
                    COALESCE((SELECT SUM(TongTien) FROM HoaDon WHERE NgayLap >= ? AND NgayLap < ?), 0) AS Invoiced,
                    COALESCE((SELECT SUM(SoTien) FROM ThanhToan WHERE NgayThanhToan >= ? AND NgayThanhToan < ?), 0) AS Collected,
                    COALESCE((
                        SELECT SUM(CASE WHEN h.TongTien > COALESCE(p.DaThu, 0)
                                        THEN h.TongTien - COALESCE(p.DaThu, 0) ELSE 0 END)
                        FROM HoaDon h
                        LEFT JOIN (
                            SELECT MaHoaDon, SUM(SoTien) AS DaThu
                            FROM ThanhToan WHERE NgayThanhToan < ? GROUP BY MaHoaDon
                        ) p ON p.MaHoaDon = h.MaHoaDon
                        WHERE h.NgayLap < ?
                    ), 0) AS Outstanding,
                    (SELECT COUNT(*) FROM HoaDon WHERE NgayLap >= ? AND NgayLap < ?) AS InvoiceCount,
                    (SELECT COUNT(*)
                     FROM HoaDon h
                     WHERE h.NgayLap >= ? AND h.NgayLap < ?
                       AND COALESCE((SELECT SUM(t.SoTien) FROM ThanhToan t
                                     WHERE t.MaHoaDon = h.MaHoaDon AND t.NgayThanhToan < ?), 0) >= h.TongTien
                    ) AS PaidInvoiceCount
                """, (rs, rowNum) -> new ReportResponse.BillingSummary(
                        money(rs, "Invoiced"), money(rs, "Collected"), money(rs, "Outstanding"),
                        rs.getInt("InvoiceCount"), rs.getInt("PaidInvoiceCount")
                ), start, end, start, end, end, end, start, end, start, end, end);
    }

    private ReportResponse.RepairSummary repairs(LocalDateTime start, LocalDateTime end) {
        return jdbc.queryForObject("""
                SELECT
                    SUM(CASE WHEN NgayLap >= ? AND NgayLap < ? THEN 1 ELSE 0 END) AS Opened,
                    SUM(CASE WHEN TrangThai = N'HOAN_TAT' AND NgayHoanThanh >= ? AND NgayHoanThanh < ? THEN 1 ELSE 0 END) AS Completed,
                    SUM(CASE WHEN NgayLap >= ? AND NgayLap < ? AND TrangThai NOT IN (N'HOAN_TAT', N'HUY', N'DA_HUY') THEN 1 ELSE 0 END) AS InProgress,
                    SUM(CASE WHEN NgayLap >= ? AND NgayLap < ? AND TrangThai = N'HOAN_TAT' AND NgayHoanThanh < ? THEN 1 ELSE 0 END) AS CompletedFromOpened,
                    AVG(CASE WHEN TrangThai = N'HOAN_TAT' AND NgayHoanThanh >= ? AND NgayHoanThanh < ? AND NgayBatDau IS NOT NULL
                             THEN CAST(DATEDIFF(MINUTE, NgayBatDau, NgayHoanThanh) AS DECIMAL(18,2)) / 60 END) AS AverageHours
                FROM PhieuSuaChua
                """, (rs, rowNum) -> {
                    int opened = rs.getInt("Opened");
                    int completed = rs.getInt("Completed");
                    return new ReportResponse.RepairSummary(
                            opened,
                            completed,
                            rs.getInt("InProgress"),
                            percentage(rs.getInt("CompletedFromOpened"), opened),
                            decimal(rs, "AverageHours")
                    );
                }, start, end, start, end, start, end, start, end, end, start, end);
    }

    private ReportResponse.InventorySummary inventory(LocalDateTime start, LocalDateTime end) {
        return jdbc.queryForObject("""
                SELECT
                    COALESCE((SELECT SUM(CAST(SoLuong AS BIGINT)) FROM BienDongKho WHERE LoaiBienDong = N'NHAP' AND ThoiGian >= ? AND ThoiGian < ?), 0) AS Imported,
                    COALESCE((SELECT SUM(CAST(SoLuong AS BIGINT)) FROM BienDongKho WHERE LoaiBienDong = N'XUAT' AND ThoiGian >= ? AND ThoiGian < ?), 0) AS Exported,
                    COALESCE((SELECT SUM(CAST(SoLuongTon AS BIGINT)) FROM PhuTung), 0) AS CurrentStock,
                    (SELECT COUNT(*) FROM PhuTung WHERE SoLuongTon > 0 AND SoLuongTon <= MucTonToiThieu) AS LowStockParts,
                    (SELECT COUNT(*) FROM PhuTung WHERE SoLuongTon = 0) AS OutOfStockParts
                """, (rs, rowNum) -> new ReportResponse.InventorySummary(
                        rs.getLong("Imported"), rs.getLong("Exported"), rs.getLong("CurrentStock"),
                        rs.getInt("LowStockParts"), rs.getInt("OutOfStockParts")
                ), start, end, start, end);
    }

    private List<ReportResponse.StatusCount> vehicleStatuses(LocalDateTime end) {
        return jdbc.query("""
                WITH LatestRepair AS (
                    SELECT tn.MaXe, sc.TrangThai,
                           ROW_NUMBER() OVER (PARTITION BY tn.MaXe ORDER BY sc.NgayLap DESC, sc.MaPhieuSuaChua DESC) AS RowNumber
                    FROM PhieuSuaChua sc
                    INNER JOIN PhieuTiepNhan tn ON tn.MaTiepNhan = sc.MaTiepNhan
                    WHERE sc.NgayLap < ?
                )
                SELECT TrangThai, COUNT(*) AS SoLuong
                FROM LatestRepair WHERE RowNumber = 1
                GROUP BY TrangThai ORDER BY SoLuong DESC, TrangThai
                """, (rs, rowNum) -> new ReportResponse.StatusCount(rs.getString("TrangThai"), rs.getInt("SoLuong")), end);
    }

    private List<ReportResponse.TrendPoint> trends(
            LocalDate from, LocalDate to, LocalDateTime start, LocalDateTime end
    ) {
        Map<YearMonth, MutableTrend> values = new LinkedHashMap<>();
        YearMonth month = YearMonth.from(from);
        YearMonth last = YearMonth.from(to);
        while (!month.isAfter(last)) {
            values.put(month, new MutableTrend());
            month = month.plusMonths(1);
        }

        jdbc.query("""
                SELECT YEAR(Moment) AS Nam, MONTH(Moment) AS Thang,
                       SUM(Invoiced) AS Invoiced, SUM(Collected) AS Collected, SUM(Completed) AS Completed
                FROM (
                    SELECT NgayLap AS Moment, TongTien AS Invoiced, CAST(0 AS DECIMAL(18,2)) AS Collected, 0 AS Completed
                    FROM HoaDon WHERE NgayLap >= ? AND NgayLap < ?
                    UNION ALL
                    SELECT NgayThanhToan, CAST(0 AS DECIMAL(18,2)), SoTien, 0
                    FROM ThanhToan WHERE NgayThanhToan >= ? AND NgayThanhToan < ?
                    UNION ALL
                    SELECT NgayHoanThanh, CAST(0 AS DECIMAL(18,2)), CAST(0 AS DECIMAL(18,2)), 1
                    FROM PhieuSuaChua WHERE TrangThai = N'HOAN_TAT' AND NgayHoanThanh >= ? AND NgayHoanThanh < ?
                ) SourceData
                GROUP BY YEAR(Moment), MONTH(Moment)
                """, rs -> {
            MutableTrend value = values.get(YearMonth.of(rs.getInt("Nam"), rs.getInt("Thang")));
            if (value != null) {
                value.invoiced = money(rs, "Invoiced");
                value.collected = money(rs, "Collected");
                value.completed = rs.getInt("Completed");
            }
        }, start, end, start, end, start, end);

        return values.entrySet().stream()
                .map(entry -> new ReportResponse.TrendPoint(
                        entry.getKey().toString(), entry.getValue().invoiced,
                        entry.getValue().collected, entry.getValue().completed))
                .toList();
    }

    private List<ReportResponse.PartMovement> partMovements(LocalDateTime start, LocalDateTime end) {
        return jdbc.query("""
                SELECT TOP 10 pt.MaPhuTung, pt.TenPhuTung,
                    COALESCE(SUM(CASE WHEN bd.LoaiBienDong = N'NHAP' THEN CAST(bd.SoLuong AS BIGINT) ELSE 0 END), 0) AS Imported,
                    COALESCE(SUM(CASE WHEN bd.LoaiBienDong = N'XUAT' THEN CAST(bd.SoLuong AS BIGINT) ELSE 0 END), 0) AS Exported,
                    pt.SoLuongTon
                FROM PhuTung pt
                LEFT JOIN BienDongKho bd ON bd.MaPhuTung = pt.MaPhuTung AND bd.ThoiGian >= ? AND bd.ThoiGian < ?
                GROUP BY pt.MaPhuTung, pt.TenPhuTung, pt.SoLuongTon
                ORDER BY SUM(CASE WHEN bd.LoaiBienDong IN (N'NHAP', N'XUAT') THEN CAST(bd.SoLuong AS BIGINT) ELSE 0 END) DESC,
                         pt.TenPhuTung
                """, (rs, rowNum) -> new ReportResponse.PartMovement(
                        rs.getInt("MaPhuTung"), rs.getString("TenPhuTung"), rs.getLong("Imported"),
                        rs.getLong("Exported"), rs.getInt("SoLuongTon")
                ), start, end);
    }

    private List<ReportResponse.TechnicianPerformance> technicianPerformance(LocalDateTime start, LocalDateTime end) {
        return jdbc.query("""
                SELECT nv.MaNhanVien, nv.HoTen,
                    COUNT(pc.MaPhieuSuaChua) AS Assigned,
                    SUM(CASE WHEN sc.TrangThai = N'HOAN_TAT' AND sc.NgayHoanThanh < ? THEN 1 ELSE 0 END) AS Completed,
                    AVG(CASE WHEN sc.TrangThai = N'HOAN_TAT' AND sc.NgayHoanThanh < ? AND sc.NgayBatDau IS NOT NULL
                             THEN CAST(DATEDIFF(MINUTE, sc.NgayBatDau, sc.NgayHoanThanh) AS DECIMAL(18,2)) / 60 END) AS AverageHours
                FROM KyThuatVien ktv
                INNER JOIN NhanVien nv ON nv.MaNhanVien = ktv.MaNhanVien
                INNER JOIN PhanCongKyThuatVien pc ON pc.MaKyThuatVien = ktv.MaNhanVien
                    AND pc.NgayPhanCong >= ? AND pc.NgayPhanCong < ?
                INNER JOIN PhieuSuaChua sc ON sc.MaPhieuSuaChua = pc.MaPhieuSuaChua
                GROUP BY nv.MaNhanVien, nv.HoTen
                ORDER BY Completed DESC, Assigned DESC, nv.HoTen
                """, (rs, rowNum) -> {
                    int assigned = rs.getInt("Assigned");
                    int completed = rs.getInt("Completed");
                    return new ReportResponse.TechnicianPerformance(
                            rs.getInt("MaNhanVien"), rs.getString("HoTen"), assigned, completed,
                            percentage(completed, assigned), decimal(rs, "AverageHours")
                    );
                }, end, end, start, end);
    }

    private static BigDecimal money(ResultSet rs, String column) throws SQLException {
        BigDecimal value = rs.getBigDecimal(column);
        return value == null ? ZERO : value.setScale(2, RoundingMode.HALF_UP);
    }

    private static BigDecimal decimal(ResultSet rs, String column) throws SQLException {
        BigDecimal value = rs.getBigDecimal(column);
        return value == null ? BigDecimal.ZERO : value.setScale(2, RoundingMode.HALF_UP);
    }

    private static BigDecimal percentage(int numerator, int denominator) {
        if (denominator == 0) return BigDecimal.ZERO.setScale(2);
        return BigDecimal.valueOf(numerator)
                .multiply(BigDecimal.valueOf(100))
                .divide(BigDecimal.valueOf(denominator), 2, RoundingMode.HALF_UP);
    }

    private static final class MutableTrend {
        private BigDecimal invoiced = ZERO;
        private BigDecimal collected = ZERO;
        private int completed;
    }
}
