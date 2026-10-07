package com.gara.quanlygara.service;

import com.gara.quanlygara.dto.billing.BillingRequests;
import com.gara.quanlygara.dto.billing.InvoiceResponse;
import com.gara.quanlygara.entity.Invoice;
import com.gara.quanlygara.entity.Payment;
import com.gara.quanlygara.exception.ConflictException;
import com.gara.quanlygara.exception.ResourceNotFoundException;
import com.gara.quanlygara.repository.InvoiceRepository;
import com.gara.quanlygara.repository.PaymentRepository;
import com.gara.quanlygara.repository.RepairOrderRepository;
import com.gara.quanlygara.repository.ReceivingBankAccountRepository;
import com.gara.quanlygara.exception.BadRequestException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Locale;

@Service
@Transactional(readOnly = true)
public class BillingService {
    private final InvoiceRepository invoices;
    private final PaymentRepository payments;
    private final RepairOrderRepository orders;
    private final JdbcTemplate jdbc;
    private final ReceivingBankAccountRepository banks;
    public BillingService(InvoiceRepository invoices, PaymentRepository payments,
                          RepairOrderRepository orders, JdbcTemplate jdbc, ReceivingBankAccountRepository banks) {
        this.invoices = invoices;
        this.payments = payments;
        this.orders = orders;
        this.jdbc = jdbc;
        this.banks = banks;
    }

    public List<InvoiceResponse> getAll() {
        return jdbc.query("""
                SELECT h.*, x.BienSo, k.HoTen, COALESCE(p.DaTra, 0) AS DaTra
                FROM HoaDon h JOIN PhieuSuaChua s ON s.MaPhieuSuaChua = h.MaPhieuSuaChua
                JOIN PhieuTiepNhan t ON t.MaTiepNhan = s.MaTiepNhan
                JOIN Xe x ON x.MaXe = t.MaXe JOIN KhachHang k ON k.MaKhachHang = x.MaKhachHang
                LEFT JOIN (SELECT MaHoaDon, SUM(SoTien) AS DaTra FROM ThanhToan GROUP BY MaHoaDon) p
                    ON p.MaHoaDon = h.MaHoaDon
                ORDER BY h.NgayLap DESC, h.MaHoaDon DESC
                """, (rs, row) -> new InvoiceResponse(rs.getInt("MaHoaDon"), rs.getInt("MaPhieuSuaChua"),
                rs.getTimestamp("NgayLap").toLocalDateTime(), rs.getString("TrangThai"),
                rs.getBigDecimal("TongTien"), rs.getBigDecimal("DaTra"),
                rs.getBigDecimal("TongTien").subtract(rs.getBigDecimal("DaTra")),
                rs.getString("BienSo"), rs.getString("HoTen")));
    }

    public InvoiceResponse.Detail getById(Integer id) {
        Invoice invoice = invoices.findById(id).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hóa đơn."));
        var vehicle = orders.findOverviews(invoice.getRepairOrderId(), 0).stream().findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa của hóa đơn."));
        BigDecimal paid = payments.totalPaid(id);
        return new InvoiceResponse.Detail(new InvoiceResponse(id, invoice.getRepairOrderId(), invoice.getCreatedAt(),
                invoice.getStatus(), invoice.getTotal(), paid, invoice.getTotal().subtract(paid),
                vehicle.getLicensePlate(), vehicle.getCustomerName()), lines(invoice.getRepairOrderId()),
                payments.findByInvoiceIdOrderByPaidAtDescIdDesc(id));
    }

    @Transactional
    public InvoiceResponse.Detail create(Integer orderId) {
        var order = orders.findForUpdate(orderId).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy phiếu sửa chữa."));
        if (!"HOAN_TAT".equals(order.getStatus())) throw new ConflictException("Chỉ lập hóa đơn khi sửa chữa đã hoàn tất.");
        if (invoices.existsByRepairOrderId(orderId)) throw new ConflictException("Phiếu sửa chữa đã có hóa đơn.");
        var lines = lines(orderId);
        if (lines.isEmpty()) throw new ConflictException("Phiếu chưa có chi tiết dịch vụ hoặc phụ tùng.");
        BigDecimal total = lines.stream().map(l -> l.unitPrice().multiply(BigDecimal.valueOf(l.quantity())))
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        if (total.precision() - total.scale() > 16) throw new ConflictException("Tổng hóa đơn vượt giới hạn cho phép.");
        Invoice invoice = new Invoice();
        invoice.setRepairOrderId(orderId);
        invoice.setCreatedAt(now());
        invoice.setTotal(total);
        invoice.setStatus(total.signum() == 0 ? "DA_THANH_TOAN" : "CHUA_THANH_TOAN");
        invoices.saveAndFlush(invoice);
        return getById(invoice.getId());
    }

    @Transactional
    public InvoiceResponse.Detail recordPayment(Integer id, BillingRequests.RecordPayment request) {
        // Serialize collection on the invoice before calculating its outstanding balance.
        Invoice invoice = invoices.findForUpdate(id).orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy hóa đơn."));
        String requestId = request.requestId().toLowerCase(Locale.ROOT);
        var existing = payments.findByRequestId(requestId);
        if (existing.isPresent()) {
            Payment payment = existing.get();
            if (!payment.getInvoiceId().equals(id) || payment.getAmount().compareTo(request.amount()) != 0
                    || !payment.getMethod().equals(request.method())
                    || !java.util.Objects.equals(payment.getBankAccountId(), request.bankAccountId())) {
                throw new ConflictException("Mã yêu cầu đã được sử dụng cho một thanh toán khác.");
            }
            return getById(id);
        }
        BigDecimal remaining = invoice.getTotal().subtract(payments.totalPaid(id));
        if (request.bankAccountId() != null) {
            if (!"CHUYEN_KHOAN".equals(request.method())) throw new BadRequestException("Tiền mặt không dùng tài khoản ngân hàng.");
            if (!banks.findById(request.bankAccountId()).map(b -> b.isActive()).orElse(false)) {
                throw new ConflictException("Tài khoản nhận tiền không còn hoạt động. Vui lòng kiểm tra lại.");
            }
        }
        if (request.amount().compareTo(remaining) > 0) {
            throw new ConflictException("Số tiền vượt quá số còn phải thanh toán. Vui lòng tải lại hóa đơn.");
        }
        Payment payment = new Payment();
        payment.setInvoiceId(id);
        payment.setAmount(request.amount());
        payment.setMethod(request.method());
        payment.setRequestId(requestId);
        payment.setBankAccountId(request.bankAccountId());
        payment.setPaidAt(now());
        payments.saveAndFlush(payment);
        invoice.setStatus(remaining.compareTo(request.amount()) == 0 ? "DA_THANH_TOAN" : "CHUA_THANH_TOAN");
        invoices.saveAndFlush(invoice);
        return getById(id);
    }

    private List<InvoiceResponse.Line> lines(Integer orderId) {
        // Use prices stored on the repair order, never the current catalog price or client totals.
        return jdbc.query("""
                SELECT 'DICH_VU' AS Loai, d.MaDichVu AS Ma, d.TenDichVu AS Ten, c.SoLuong, c.DonGia
                FROM ChiTietDichVu c JOIN DichVu d ON d.MaDichVu = c.MaDichVu WHERE c.MaPhieuSuaChua = ?
                UNION ALL
                SELECT 'PHU_TUNG' AS Loai, p.MaPhuTung AS Ma, p.TenPhuTung AS Ten, c.SoLuong, c.DonGia
                FROM ChiTietPhuTung c JOIN PhuTung p ON p.MaPhuTung = c.MaPhuTung WHERE c.MaPhieuSuaChua = ?
                """, (rs, row) -> new InvoiceResponse.Line(rs.getString("Loai"), rs.getInt("Ma"),
                rs.getString("Ten"), rs.getInt("SoLuong"), rs.getBigDecimal("DonGia")), orderId, orderId);
    }

    private LocalDateTime now() { return LocalDateTime.now(ZoneId.of("Asia/Ho_Chi_Minh")).withNano(0); }
}
