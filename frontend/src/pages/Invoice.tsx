import React, { useMemo, useState } from "react";
import { Badge, Button, Card, Input, Modal, Icons } from "../components/ui";
import { baoGia, chiTietBaoGia, formatCurrency, khachHang, phieuSuaChua, phieuTiepNhan, xe } from "../data";
import { hoaDon, thanhToan } from "../mock/schemaData";

const toDate = (value: string) => new Date(value).toLocaleString("vi-VN");

export default function Invoice() {
  const [selectedId, setSelectedId] = useState(hoaDon[1]?.MaHoaDon ?? hoaDon[0].MaHoaDon);
  const [showPay, setShowPay] = useState(false);
  const [method, setMethod] = useState<"cash" | "transfer">("transfer");
  const [localPayments, setLocalPayments] = useState(thanhToan);
  const invoice = hoaDon.find((item) => item.MaHoaDon === selectedId)!;
  const repair = phieuSuaChua.find((item) => item.MaPhieuSuaChua === invoice.MaPhieuSuaChua);
  const reception = phieuTiepNhan.find((item) => item.MaTiepNhan === repair?.MaTiepNhan);
  const vehicle = xe.find((item) => item.MaXe === reception?.MaXe);
  const customer = khachHang.find((item) => item.MaKhachHang === vehicle?.MaKhachHang);
  const quote = baoGia.find((item) => item.MaPhieuSuaChua === invoice.MaPhieuSuaChua);
  const lines = chiTietBaoGia.filter((item) => item.MaBaoGia === quote?.MaBaoGia);
  const payments = localPayments.filter((item) => item.MaHoaDon === invoice.MaHoaDon);
  const paidAmount = payments.reduce((sum, item) => sum + item.SoTien, 0);
  const remaining = Math.max(invoice.TongTien - paidAmount, 0);
  const status = remaining === 0 ? "paid" : "unpaid";
  const nextPaymentId = useMemo(() => `TT${String(localPayments.length + 1).padStart(3, "0")}`, [localPayments.length]);

  const confirmPayment = () => {
    if (remaining <= 0) return;
    setLocalPayments((items) => [...items, { MaThanhToan: nextPaymentId, MaHoaDon: invoice.MaHoaDon, NgayThanhToan: "2026-09-18T09:00:00", SoTien: remaining, PhuongThuc: method }]);
    setShowPay(false);
  };

  return <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
    <div className="space-y-3">
      <div className="flex justify-between items-center"><h2 className="font-semibold">Hóa đơn</h2><Button size="sm" icon={Icons.plus}>Lập hóa đơn</Button></div>
      {hoaDon.map((item) => {
        const paid = localPayments.filter((p) => p.MaHoaDon === item.MaHoaDon).reduce((sum, p) => sum + p.SoTien, 0);
        return <button key={item.MaHoaDon} onClick={() => setSelectedId(item.MaHoaDon)} aria-pressed={selectedId === item.MaHoaDon} className={`w-full rounded-lg border bg-surface p-4 text-left ${selectedId === item.MaHoaDon ? "border-primary ring-1 ring-primary" : "border-border"}`}><div className="flex justify-between"><span className="mono text-xs">{item.MaHoaDon}</span><Badge variant={paid >= item.TongTien ? "paid" : "unpaid"} /></div><p className="mt-2 font-semibold">{item.MaPhieuSuaChua}</p><p className="text-xs text-slate-500">{toDate(item.NgayLap)}</p><p className="mt-2 font-bold text-primary">{formatCurrency(item.TongTien)}</p></button>;
      })}
    </div>

    <Card className="p-5 xl:col-span-2">
      <div className="receipt-header"><div><div className="flex flex-wrap items-center gap-3"><h2 className="text-xl font-bold">HÓA ĐƠN {invoice.MaHoaDon}</h2><Badge variant={status} /></div><p className="text-sm text-slate-500">Ngày lập: {toDate(invoice.NgayLap)}</p></div><Button variant="outline" icon={Icons.printer}>In hóa đơn</Button></div>
      <div className="mb-5 grid grid-cols-1 gap-3 sm:grid-cols-3"><div className="p-3 bg-slate-50 rounded-lg"><p className="text-xs text-slate-500">Khách hàng</p><p className="font-semibold">{customer?.HoTen ?? "—"}</p></div><div className="p-3 bg-slate-50 rounded-lg"><p className="text-xs text-slate-500">Biển số</p><p className="font-semibold">{vehicle?.BienSo ?? "—"}</p></div><div className="p-3 bg-slate-50 rounded-lg"><p className="text-xs text-slate-500">Phiếu sửa chữa</p><p className="font-semibold mono">{invoice.MaPhieuSuaChua}</p></div></div>
      <table className="w-full data-table"><thead><tr><th>Nội dung</th><th>Loại</th><th className="text-right">Số lượng</th><th className="text-right">Đơn giá</th><th className="text-right">Thành tiền</th></tr></thead><tbody>{lines.map((line) => <tr key={line.MaChiTietBaoGia}><td>{line.NoiDung}</td><td>{line.MaDichVu ? "Dịch vụ" : "Phụ tùng"}</td><td className="text-right">{line.SoLuong}</td><td className="text-right">{formatCurrency(line.DonGia)}</td><td className="text-right font-semibold">{formatCurrency(line.SoLuong * line.DonGia)}</td></tr>)}</tbody></table>
      <div className="mt-4 flex justify-end"><div className="w-full space-y-2 text-sm sm:w-80"><div className="flex justify-between"><span>Tổng tiền hóa đơn</span><strong>{formatCurrency(invoice.TongTien)}</strong></div><div className="flex justify-between"><span>Đã thanh toán</span><span>{formatCurrency(paidAmount)}</span></div><div className="flex justify-between border-t border-border pt-2 text-lg"><strong>Còn lại</strong><strong className="text-primary">{formatCurrency(remaining)}</strong></div></div></div>
      {payments.length > 0 && <div className="mt-5"><p className="text-xs uppercase font-semibold text-slate-500 mb-2">Các lần thanh toán</p>{payments.map((payment) => <div key={payment.MaThanhToan} className="flex justify-between p-3 bg-emerald-50 rounded-lg text-sm"><span>{payment.MaThanhToan} · {toDate(payment.NgayThanhToan)} · {payment.PhuongThuc === "transfer" ? "Chuyển khoản" : "Tiền mặt"}</span><strong>{formatCurrency(payment.SoTien)}</strong></div>)}</div>}
      {remaining > 0 && <Button className="w-full mt-5 justify-center" onClick={() => setShowPay(true)}>Ghi nhận thanh toán</Button>}
    </Card>

    <Modal open={showPay} onClose={() => setShowPay(false)} title="Ghi nhận thanh toán">
      <div className="space-y-4"><Input label="Mã hóa đơn" value={invoice.MaHoaDon} readOnly /><Input label="Ngày thanh toán" type="datetime-local" defaultValue="2026-09-18T09:00" /><Input label="Số tiền" type="number" value={remaining} readOnly /><div><p className="mb-2 text-xs font-medium text-slate-600">Phương thức</p><div className="grid grid-cols-2 gap-2">{(["cash", "transfer"] as const).map((value) => <button key={value} onClick={() => setMethod(value)} className={`rounded-lg border p-3 ${method === value ? "border-primary bg-primary-soft text-primary" : "border-border"}`}>{value === "cash" ? "Tiền mặt" : "Chuyển khoản"}</button>)}</div></div><p className="text-xs text-slate-500">sp_GhiNhanThanhToan cho phép nhiều lần thanh toán và cập nhật trạng thái hóa đơn theo tổng đã trả.</p><div className="flex justify-end gap-2"><Button variant="outline" onClick={() => setShowPay(false)}>Hủy</Button><Button onClick={confirmPayment}>Xác nhận</Button></div></div>
    </Modal>
  </div>;
}
