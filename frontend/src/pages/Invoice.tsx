import React, { useState } from "react";
import { Card, Badge, Button, Modal, Icons } from "../components/ui";
import { mockInvoices, calcTotal, formatCurrency } from "../data";

export default function Invoice() {
  const [selected, setSelected] = useState(mockInvoices[1].id);
  const [showPayModal, setShowPayModal] = useState(false);
  const [payMethod, setPayMethod] = useState<"cash" | "transfer">("transfer");
  const [paid, setPaid] = useState(false);

  const inv = mockInvoices.find(i => i.id === selected);
  const total = inv ? calcTotal(inv.services, inv.parts) : 0;
  const isUnpaid = inv?.status === "unpaid" && !paid;

  return (
    <div className="p-6">
      <div className="grid grid-cols-3 gap-4">
        {/* List */}
        <div className="space-y-3">
          <div className="flex items-center justify-between mb-2">
            <h2 className="font-semibold text-slate-700">Hóa đơn</h2>
            <Button size="sm" icon={Icons.plus}>Lập hóa đơn</Button>
          </div>
          {mockInvoices.map(i => {
            const t = calcTotal(i.services, i.parts);
            return (
              <div key={i.id} onClick={() => { setSelected(i.id); setPaid(false); }}
                className={`bg-white rounded-xl border p-4 cursor-pointer transition-all hover:border-[#1e3a6e] ${selected === i.id ? "border-[#1e3a6e] ring-1 ring-[#1e3a6e]" : "border-[#dde3ec]"}`}>
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <span className="mono text-xs text-slate-400">{i.id}</span>
                    <p className="font-semibold text-slate-800 text-sm">{i.customer}</p>
                    <p className="text-xs text-slate-500">{i.vehicle}</p>
                  </div>
                  <Badge variant={(i.status === "paid" || (selected === i.id && paid)) ? "paid" : "unpaid"} />
                </div>
                <div className="flex items-center justify-between mt-2">
                  <span className="text-xs text-slate-500">{i.created.split("-").reverse().join("/")}</span>
                  <span className="font-bold text-[#1e3a6e] text-sm">{formatCurrency(t)}</span>
                </div>
              </div>
            );
          })}
        </div>

        {/* Detail */}
        <div className="col-span-2">
          {inv && (
            <Card className="p-6">
              {/* Invoice header */}
              <div className="flex items-start justify-between mb-6">
                <div>
                  <div className="flex items-center gap-3 mb-1">
                    <h2 className="text-2xl font-bold text-slate-800">HÓA ĐƠN {inv.id}</h2>
                    <Badge variant={(inv.status === "paid" || paid) ? "paid" : "unpaid"} />
                  </div>
                  <p className="text-slate-500 text-sm">Gara Ô Tô Thành Công · 123 Lê Văn Sỹ, Q.3, TP.HCM</p>
                </div>
                <Button variant="outline" size="sm" icon={Icons.printer}>In hóa đơn</Button>
              </div>

              {/* Customer & vehicle info */}
              <div className="grid grid-cols-3 gap-4 mb-6">
                <div className="p-4 bg-slate-50 rounded-xl">
                  <p className="text-xs text-slate-500 mb-1">Khách hàng</p>
                  <p className="font-semibold text-slate-800">{inv.customer}</p>
                </div>
                <div className="p-4 bg-slate-50 rounded-xl">
                  <p className="text-xs text-slate-500 mb-1">Biển số xe</p>
                  <p className="font-mono font-bold text-[#1e3a6e]">{inv.vehicle}</p>
                </div>
                <div className="p-4 bg-slate-50 rounded-xl">
                  <p className="text-xs text-slate-500 mb-1">Phiếu sửa chữa</p>
                  <p className="font-mono text-sm text-blue-600">{inv.repairId}</p>
                </div>
              </div>

              {/* Services */}
              {inv.services.length > 0 && (
                <div className="mb-4">
                  <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Dịch vụ</p>
                  <table className="w-full data-table">
                    <thead>
                      <tr><th>Tên dịch vụ</th><th className="text-right">SL</th><th className="text-right">Đơn giá</th><th className="text-right">Thành tiền</th></tr>
                    </thead>
                    <tbody>
                      {inv.services.map((s, i) => (
                        <tr key={i}>
                          <td className="font-medium">{s.name}</td>
                          <td className="text-right">{s.qty}</td>
                          <td className="text-right text-slate-600">{formatCurrency(s.price)}</td>
                          <td className="text-right font-semibold">{formatCurrency(s.qty * s.price)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {/* Parts */}
              {inv.parts.length > 0 && (
                <div className="mb-6">
                  <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Phụ tùng</p>
                  <table className="w-full data-table">
                    <thead>
                      <tr><th>Tên phụ tùng</th><th className="text-right">SL</th><th className="text-right">Đơn giá</th><th className="text-right">Thành tiền</th></tr>
                    </thead>
                    <tbody>
                      {inv.parts.map((p, i) => (
                        <tr key={i}>
                          <td className="font-medium">{p.name}</td>
                          <td className="text-right">{p.qty}</td>
                          <td className="text-right text-slate-600">{formatCurrency(p.price)}</td>
                          <td className="text-right font-semibold">{formatCurrency(p.qty * p.price)}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}

              {/* Total */}
              <div className="border-t border-[#dde3ec] pt-4 flex justify-end">
                <div className="w-72 space-y-2">
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-600">Tổng dịch vụ:</span>
                    <span>{formatCurrency(inv.services.reduce((s, x) => s + x.qty * x.price, 0))}</span>
                  </div>
                  <div className="flex justify-between text-sm">
                    <span className="text-slate-600">Tổng phụ tùng:</span>
                    <span>{formatCurrency(inv.parts.reduce((s, x) => s + x.qty * x.price, 0))}</span>
                  </div>
                  <div className="flex justify-between pt-2 border-t border-[#dde3ec]">
                    <span className="font-bold text-slate-800 text-base">Tổng cộng:</span>
                    <span className="text-2xl font-bold text-[#1e3a6e]">{formatCurrency(total)}</span>
                  </div>
                </div>
              </div>

              {/* Payment status */}
              {(inv.status === "paid" || paid) ? (
                <div className="mt-6 p-4 bg-emerald-50 border border-emerald-200 rounded-xl flex items-center gap-3">
                  <span className="text-emerald-600 text-xl">{Icons.checkCircle}</span>
                  <div>
                    <p className="font-semibold text-emerald-800">Đã thanh toán</p>
                    <p className="text-xs text-emerald-700">
                      {inv.paidAt ? `Ngày ${inv.paidAt.split("-").reverse().join("/")} · ` : ""}
                      {inv.paymentMethod === "transfer" ? "Chuyển khoản" : "Tiền mặt"}
                    </p>
                  </div>
                </div>
              ) : (
                <div className="mt-6 flex gap-3">
                  <Button className="flex-1" variant="primary" onClick={() => setShowPayModal(true)}>
                    Thanh toán
                  </Button>
                  <Button variant="outline" icon={Icons.printer}>In hóa đơn</Button>
                </div>
              )}
            </Card>
          )}
        </div>
      </div>

      {/* Payment modal */}
      <Modal open={showPayModal} onClose={() => setShowPayModal(false)} title="Thanh toán hóa đơn">
        <div className="space-y-5">
          <div className="p-4 bg-[#e8eef7] rounded-xl flex items-center justify-between">
            <span className="text-slate-600 font-medium">Tổng thanh toán</span>
            <span className="text-2xl font-bold text-[#1e3a6e]">{formatCurrency(total)}</span>
          </div>

          <div>
            <p className="text-xs font-medium text-slate-600 mb-2">Phương thức thanh toán</p>
            <div className="grid grid-cols-2 gap-3">
              {(["cash", "transfer"] as const).map(m => (
                <button key={m} onClick={() => setPayMethod(m)}
                  className={`p-4 rounded-xl border-2 text-left transition-all ${payMethod === m ? "border-[#1e3a6e] bg-[#e8eef7]" : "border-[#dde3ec] hover:border-slate-300"}`}>
                  <div className="text-2xl mb-1">{m === "cash" ? "💵" : "🏦"}</div>
                  <p className="font-semibold text-slate-700 text-sm">{m === "cash" ? "Tiền mặt" : "Chuyển khoản"}</p>
                  {m === "transfer" && <p className="text-xs text-slate-400 mt-0.5">ACB · 1234567890</p>}
                </button>
              ))}
            </div>
          </div>

          {payMethod === "transfer" && (
            <div className="p-4 bg-slate-50 rounded-xl text-center border border-dashed border-slate-300">
              <p className="text-xs text-slate-500 mb-1">Mã QR chuyển khoản</p>
              <div className="w-32 h-32 bg-slate-200 rounded-lg mx-auto flex items-center justify-center text-slate-400 text-xs">QR Code</div>
              <p className="text-xs text-slate-500 mt-1">ACB · Gara Ô Tô Thành Công · 1234567890</p>
            </div>
          )}

          <div className="flex gap-3">
            <button onClick={() => setShowPayModal(false)} className="flex-1 h-10 rounded-lg border border-[#dde3ec] text-slate-600 text-sm font-medium hover:bg-slate-50">Hủy</button>
            <button onClick={() => { setShowPayModal(false); setPaid(true); }}
              className="flex-1 h-10 rounded-lg bg-emerald-600 text-white text-sm font-semibold hover:bg-emerald-700 transition-all">
              Xác nhận thanh toán
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
