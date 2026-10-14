// TV3-TUAN9
package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.history.HistoryDetailResponse;
import com.gara.quanlygara.dto.history.HistoryItemResponse;
import com.gara.quanlygara.dto.history.HistoryPageResponse;
import com.gara.quanlygara.dto.history.HistoryVehicleResponse;
import com.gara.quanlygara.exception.BadRequestException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.RepairHistoryRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Date;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * Lịch sử sửa chữa/bảo dưỡng của khách hàng (chỉ đọc). customerId luôn do controller lấy từ JWT,
 * KHÔNG nhận từ client; mọi truy vấn đều lọc theo xe thuộc khách hàng đó.
 */
@Service
public class RepairHistoryService {

    public static final String MAINTENANCE = "BAO_DUONG";
    public static final String REPAIR = "SUA_CHUA";
    public static final String MIXED = "BAO_DUONG_SUA_CHUA";

    public static final int MAX_PAGE_SIZE = 50;

    private static final int SUMMARY_SERVICES = 3;

    private final RepairHistoryRepository repository;

    public RepairHistoryService(RepairHistoryRepository repository) {
        this.repository = repository;
    }

    /**
     * Một trang lịch sử, mới nhất trước. vehicleId null = mọi xe của khách hàng; xe không thuộc khách hàng => 404
     * (không tiết lộ xe có tồn tại hay không). totalElements/totalPages cho biết đầy đủ số lượt, không cắt âm thầm.
     */
    @Transactional(readOnly = true)
    public HistoryPageResponse getHistory(Integer customerId, Integer vehicleId, int page, int size) {
        if (vehicleId != null) {
            if (vehicleId <= 0) throw new BadRequestException("Mã xe không hợp lệ.");
            if (repository.countOwnedVehicle(vehicleId, customerId) == 0) {
                throw new ResourceNotFoundException("Không tìm thấy xe.");
            }
        }
        int pageIndex = Math.max(page, 0);
        int pageSize = Math.min(Math.max(size, 1), MAX_PAGE_SIZE);
        int vehicleFilter = vehicleId == null ? 0 : vehicleId;

        long total = repository.countHistory(customerId, vehicleFilter);
        int totalPages = (int) ((total + pageSize - 1) / pageSize);
        long offset = (long) pageIndex * pageSize;

        List<HistoryItemResponse> items = List.of();
        if (offset < total) {
            items = build(repository.findHistoryRows(customerId, vehicleFilter, 0, (int) offset, pageSize))
                    .stream().map(Built::item).toList();
        }
        return new HistoryPageResponse(items, pageIndex, pageSize, total, totalPages);
    }

    /** Toàn bộ xe có lịch sử của khách hàng (không phụ thuộc trang đang xem). */
    @Transactional(readOnly = true)
    public List<HistoryVehicleResponse> getVehicles(Integer customerId) {
        return repository.findHistoryVehicles(customerId).stream()
                .map(row -> new HistoryVehicleResponse(
                        toInt(row[0]), toText(row[1]), toText(row[2]), toText(row[3]), toInt(row[4])))
                .toList();
    }

    /** Phiếu không tồn tại, chưa hoàn tất hoặc của khách hàng khác đều trả 404 giống nhau. */
    @Transactional(readOnly = true)
    public HistoryDetailResponse getDetail(Integer customerId, Integer repairOrderId) {
        List<Built> built = build(repository.findHistoryRows(customerId, 0, repairOrderId, 0, 1));
        if (built.isEmpty()) {
            throw new ResourceNotFoundException("Không tìm thấy lịch sử sửa chữa.");
        }
        Built entry = built.get(0);
        BigDecimal serviceTotal = entry.services().stream().map(HistoryDetailResponse.ServiceLine::lineTotal)
                .reduce(BigDecimal.ZERO.setScale(2), BigDecimal::add);
        BigDecimal partsTotal = entry.parts().stream().map(HistoryDetailResponse.PartLine::lineTotal)
                .reduce(BigDecimal.ZERO.setScale(2), BigDecimal::add);
        return new HistoryDetailResponse(entry.item(), entry.services(), entry.parts(), serviceTotal, partsTotal);
    }

    private record Built(
            HistoryItemResponse item,
            List<HistoryDetailResponse.ServiceLine> services,
            List<HistoryDetailResponse.PartLine> parts
    ) {
    }

    private List<Built> build(List<Object[]> rows) {
        if (rows.isEmpty()) return List.of();
        List<Integer> orderIds = rows.stream().map(row -> toInt(row[0])).toList();

        Map<Integer, List<HistoryDetailResponse.ServiceLine>> services = new HashMap<>();
        for (Object[] row : repository.findServiceLines(orderIds)) {
            BigDecimal unitPrice = toDecimal(row[5]);
            int quantity = toInt(row[4]);
            services.computeIfAbsent(toInt(row[0]), key -> new ArrayList<>()).add(new HistoryDetailResponse.ServiceLine(
                    toInt(row[1]), toText(row[2]), toText(row[3]), quantity, unitPrice, lineTotal(unitPrice, quantity)));
        }
        Map<Integer, List<HistoryDetailResponse.PartLine>> parts = new HashMap<>();
        for (Object[] row : repository.findPartLines(orderIds)) {
            BigDecimal unitPrice = toDecimal(row[4]);
            int quantity = toInt(row[3]);
            parts.computeIfAbsent(toInt(row[0]), key -> new ArrayList<>()).add(new HistoryDetailResponse.PartLine(
                    toInt(row[1]), toText(row[2]), quantity, unitPrice, lineTotal(unitPrice, quantity)));
        }

        List<Built> result = new ArrayList<>();
        for (Object[] row : rows) {
            Integer orderId = toInt(row[0]);
            List<HistoryDetailResponse.ServiceLine> serviceLines = services.getOrDefault(orderId, List.of());
            List<HistoryDetailResponse.PartLine> partLines = parts.getOrDefault(orderId, List.of());
            String resultText = toText(row[8]);
            HistoryItemResponse item = new HistoryItemResponse(
                    orderId, toInt(row[1]), toText(row[2]), toText(row[3]), toText(row[4]),
                    toDateTime(row[5]), toDateTime(row[6]), toDateTime(row[7]),
                    category(serviceLines), summary(serviceLines, partLines, resultText),
                    serviceLines.size(), partLines.size(), toDecimal(row[9]), resultText);
            result.add(new Built(item, serviceLines, partLines));
        }
        return result;
    }

    /** Toàn bộ dịch vụ là BAO_DUONG => bảo dưỡng; có cả BAO_DUONG và loại khác => hỗn hợp; còn lại => sửa chữa. */
    static String category(List<HistoryDetailResponse.ServiceLine> services) {
        long maintenance = services.stream().filter(line -> MAINTENANCE.equalsIgnoreCase(line.type())).count();
        if (maintenance == 0) return REPAIR;
        return maintenance == services.size() ? MAINTENANCE : MIXED;
    }

    private static String summary(
            List<HistoryDetailResponse.ServiceLine> services, List<HistoryDetailResponse.PartLine> parts, String result
    ) {
        if (!services.isEmpty()) {
            String names = services.stream().limit(SUMMARY_SERVICES)
                    .map(HistoryDetailResponse.ServiceLine::name).collect(Collectors.joining(", "));
            int more = services.size() - SUMMARY_SERVICES;
            return more > 0 ? names + " và " + more + " hạng mục khác" : names;
        }
        if (!parts.isEmpty()) {
            return "Thay phụ tùng: " + parts.stream().limit(SUMMARY_SERVICES)
                    .map(HistoryDetailResponse.PartLine::name).collect(Collectors.joining(", "));
        }
        return result.isEmpty() ? "Không có hạng mục chi tiết" : result;
    }

    private static BigDecimal lineTotal(BigDecimal unitPrice, int quantity) {
        return unitPrice.multiply(BigDecimal.valueOf(quantity)).setScale(2, RoundingMode.HALF_UP);
    }

    // ---- Chuyển kiểu tường minh từ kết quả native (JDBC có thể trả Integer/Long/BigDecimal, Timestamp/LocalDateTime) ----

    static int toInt(Object value) {
        return value == null ? 0 : ((Number) value).intValue();
    }

    static BigDecimal toDecimal(Object value) {
        if (value == null) return BigDecimal.ZERO.setScale(2);
        BigDecimal decimal = value instanceof BigDecimal big ? big : new BigDecimal(value.toString());
        return decimal.setScale(2, RoundingMode.HALF_UP);
    }

    static String toText(Object value) {
        return value == null ? "" : value.toString();
    }

    static LocalDateTime toDateTime(Object value) {
        if (value == null) return null;
        if (value instanceof LocalDateTime dateTime) return dateTime;
        if (value instanceof Timestamp timestamp) return timestamp.toLocalDateTime();
        if (value instanceof Date date) return new Timestamp(date.getTime()).toLocalDateTime();
        return LocalDateTime.parse(value.toString().replace(' ', 'T'));
    }
}
