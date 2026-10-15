package com.gara.quanlygara.dto.report;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

public record ReportResponse(
        LocalDate from,
        LocalDate to,
        BillingSummary billing,
        RepairSummary repairs,
        InventorySummary inventory,
        List<StatusCount> vehicleStatuses,
        List<TrendPoint> trends,
        List<PartMovement> partMovements,
        List<TechnicianPerformance> technicianPerformance
) {
    public record BillingSummary(
            BigDecimal invoiced,
            BigDecimal collected,
            BigDecimal outstanding,
            int invoiceCount,
            int paidInvoiceCount
    ) {}

    public record RepairSummary(
            int opened,
            int completed,
            int inProgress,
            BigDecimal completionRate,
            BigDecimal averageHandlingHours
    ) {}

    public record InventorySummary(
            long imported,
            long exported,
            long currentStock,
            int lowStockParts,
            int outOfStockParts
    ) {}

    public record StatusCount(String status, int count) {}

    public record TrendPoint(
            String period,
            BigDecimal invoiced,
            BigDecimal collected,
            int completedRepairs
    ) {}

    public record PartMovement(
            int partId,
            String partName,
            long imported,
            long exported,
            int currentStock
    ) {}

    public record TechnicianPerformance(
            int employeeId,
            String employeeName,
            int assigned,
            int completed,
            BigDecimal completionRate,
            BigDecimal averageHandlingHours
    ) {}
}
