import React, { useState } from "react";
import { Card, Badge, Button, Modal, Icons, TableContainer } from "../components/ui";
import { baoGia, mockQuotations, calcTotal, formatCurrency } from "../mock/data";

export default function Quotation() {
  const [selected, setSelected] = useState<string | null>(mockQuotations[1].id);
  const [showConfirmModal, setShowConfirmModal] = useState(false);

  const q = mockQuotations.find(x => x.id === selected);
  const quotationRecord = baoGia.find((record) => record.MaBaoGia === selected);
  const total = q ? calcTotal(q.services, q.parts) : 0;

  return (
    <div>
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        {/* List */}
        <div className="space-y-3">
          <div className="flex items-center justify-between mb-2">
            <h2 className="font-semibold text-slate-700">Tất cả báo giá</h2>
            <Button size="sm" icon={Icons.plus}>Tạo mới</Button>
          </div>
          {mockQuotations.map(quote => {
            const t = calcTotal(quote.services, quote.parts);
            return (
              <button key={quote.id} type="button" onClick={() => setSelected(quote.id)} aria-pressed={selected === quote.id}
                className={`w-full cursor-pointer rounded-lg border bg-surface p-4 text-left transition-all hover:border-primary ${selected === quote.id ? "border-primary ring-1 ring-primary" : "border-border"}`}>
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <span className="mono text-xs text-slate-400">{quote.id}</span>
                    <p className="font-semibold text-slate-800 text-sm">{quote.customer}</p>
                    <p className="text-xs text-slate-500">{quote.vehicle}</p>
                  </div>
                  <Badge variant={quote.status as any} />
                </div>
                <div className="flex items-center justify-between mt-2">
                  <span className="text-xs text-slate-500">{quote.created.split("-").reverse().join("/")}</span>
                  <span className="text-sm font-bold text-primary">{formatCurrency(t)}</span>
                </div>
              </button>
            );
          })}
        </div>

        {/* Detail */}
        <div className="xl:col-span-2">
          {q ? (
            <Card className="p-5">
              {/* Header */}
              <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                <div>
                  <div className="flex items-center gap-3 mb-2">
                    <h2 className="text-xl font-bold text-slate-800">Báo giá {q.id}</h2>
                    <Badge variant={q.status as any} />
                  </div>
                  <div className="grid grid-cols-1 gap-4 text-sm sm:grid-cols-2 lg:grid-cols-4">
                    <div>
                      <span className="text-slate-500 text-xs">Phiếu sửa chữa</span>
                      <p className="font-medium mono">{q.repairId}</p>
                    </div>
                    <div>
                      <span className="text-slate-500 text-xs">Khách hàng</span>
                      <p className="font-medium">{q.customer}</p>
                    </div>
                    <div>
                      <span className="text-slate-500 text-xs">Biển số xe</span>
                      <p className="mono font-semibold text-primary">{q.vehicle}</p>
                    </div>
                    <div>
                      <span className="text-slate-500 text-xs">Ngày lập</span>
                      <p className="font-medium">{q.created.split("-").reverse().join("/")}</p>
                    </div>
                  </div>
                </div>
                <div className="flex gap-2">
                  <Button variant="outline" size="sm" icon={Icons.printer}>In</Button>
                  <Button variant="secondary" size="sm" icon={Icons.send}>Gửi KH</Button>
                </div>
              </div>

              {/* Status notice */}
              {q.status === "confirmed" && (
                <div className="mb-4 p-3 bg-emerald-50 border border-emerald-200 rounded-lg flex items-center gap-2">
                  <span className="text-emerald-600">{Icons.checkCircle}</span>
                  <p className="text-sm font-medium text-emerald-800">Đã xác nhận – Có thể tiến hành sửa chữa</p>
                  {quotationRecord?.NgayXacNhan && <span className="ml-auto text-xs text-emerald-700">{new Date(quotationRecord.NgayXacNhan).toLocaleString("vi-VN")}</span>}
                </div>
              )}
              {q.status === "pending" && (
                <div className="mb-4 p-3 bg-amber-50 border border-amber-200 rounded-lg flex items-center gap-2">
                  <span className="text-amber-600">{Icons.info}</span>
                  <p className="text-sm font-medium text-amber-800">Đang chờ khách hàng xác nhận...</p>
                </div>
              )}

              {/* Services */}
              <div className="mb-4">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Dịch vụ</p>
                <TableContainer>
                <table className="w-full data-table">
                  <thead>
                    <tr>
                      <th>Tên dịch vụ</th>
                      <th className="text-right">SL</th>
                      <th className="text-right">Đơn giá</th>
                      <th className="text-right">Thành tiền</th>
                    </tr>
                  </thead>
                  <tbody>
                    {q.services.map((s, i) => (
                      <tr key={i}>
                        <td className="font-medium">{s.name}</td>
                        <td className="text-right">{s.qty}</td>
                        <td className="text-right text-slate-600">{formatCurrency(s.price)}</td>
                        <td className="text-right font-semibold">{formatCurrency(s.qty * s.price)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                </TableContainer>
              </div>

              {/* Parts */}
              <div className="mb-6">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Phụ tùng</p>
                <TableContainer>
                <table className="w-full data-table">
                  <thead>
                    <tr>
                      <th>Tên phụ tùng</th>
                      <th className="text-right">SL</th>
                      <th className="text-right">Đơn giá</th>
                      <th className="text-right">Thành tiền</th>
                    </tr>
                  </thead>
                  <tbody>
                    {q.parts.map((p, i) => (
                      <tr key={i}>
                        <td className="font-medium">{p.name}</td>
                        <td className="text-right">{p.qty}</td>
                        <td className="text-right text-slate-600">{formatCurrency(p.price)}</td>
                        <td className="text-right font-semibold">{formatCurrency(p.qty * p.price)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                </TableContainer>
              </div>

              {/* Total */}
              <div className="border-t border-border pt-4">
                <div className="flex justify-end">
                  <div className="w-72 space-y-2">
                    <div className="flex justify-between text-sm">
                      <span className="text-slate-600">Tổng dịch vụ:</span>
                      <span className="font-medium">{formatCurrency(q.services.reduce((s, x) => s + x.qty * x.price, 0))}</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-slate-600">Tổng phụ tùng:</span>
                      <span className="font-medium">{formatCurrency(q.parts.reduce((s, x) => s + x.qty * x.price, 0))}</span>
                    </div>
                    <div className="flex justify-between border-t border-border pt-2">
                      <span className="font-bold text-slate-800">Tổng cộng:</span>
                      <span className="text-xl font-bold text-primary">{formatCurrency(total)}</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Actions */}
              {q.status === "pending" && (
                <div className="mt-5 flex flex-col gap-3 border-t border-border pt-4 sm:flex-row sm:flex-wrap">
                  <Button variant="outline">Lưu nháp</Button>
                  <Button variant="secondary" icon={Icons.send}>Gửi báo giá</Button>
                  <div className="flex flex-col gap-2 sm:ml-auto sm:flex-row">
                    <Button variant="danger" icon={Icons.xCircle} onClick={() => {}}>Không xác nhận</Button>
                    <Button icon={Icons.checkCircle} onClick={() => setShowConfirmModal(true)}>Xác nhận sửa chữa</Button>
                  </div>
                </div>
              )}
            </Card>
          ) : null}
        </div>
      </div>

      {/* Confirm modal */}
      <Modal open={showConfirmModal} onClose={() => setShowConfirmModal(false)} title="Xác nhận báo giá">
        <div className="space-y-4">
          <div className="p-4 bg-blue-50 border border-blue-200 rounded-lg">
            <p className="font-semibold text-blue-800 text-sm">Xác nhận tiến hành sửa chữa?</p>
            <p className="text-xs text-blue-700 mt-1">Sau khi xác nhận, kỹ thuật viên sẽ bắt đầu thực hiện các hạng mục trong báo giá.</p>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-slate-600">Khách hàng:</span>
            <span className="font-medium">{q?.customer}</span>
          </div>
          <div className="flex justify-between text-sm">
            <span className="text-slate-600">Tổng giá trị:</span>
            <span className="font-bold text-primary">{formatCurrency(total)}</span>
          </div>
          <div className="flex gap-3 pt-2">
            <Button variant="outline" className="flex-1" onClick={() => setShowConfirmModal(false)}>Hủy</Button>
            <Button className="flex-1" onClick={() => setShowConfirmModal(false)}>Xác nhận</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
