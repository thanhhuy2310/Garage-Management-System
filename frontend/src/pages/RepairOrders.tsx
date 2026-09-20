import React, { useState } from "react";
import { Card, Badge, Button, SearchBox, Modal, Icons, Select, TableContainer } from "../components/ui";
import { mockRepairOrders, formatCurrency, phieuTiepNhan, xe } from "../mock/data";

const STATUS_MAP: Record<string, string> = {
  pending: "Chờ xử lý",
  in_progress: "Đang sửa chữa",
  waiting_parts: "Chờ phụ tùng",
  inspecting: "Đang kiểm tra",
  completed: "Hoàn tất",
};

function RepairTimeline({ status }: { status: string }) {
  const steps = [
    { key: "received", label: "Tiếp nhận", time: "15/09 08:00" },
    { key: "quoted", label: "Báo giá", time: "15/09 10:30" },
    { key: "in_progress", label: "Đang sửa", time: "15/09 14:00" },
    { key: "completed", label: "Hoàn tất", time: null },
    { key: "payment", label: "Thanh toán", time: null },
    { key: "delivered", label: "Bàn giao", time: null },
  ];
  const doneIdx = status === "in_progress" ? 2 : status === "waiting_parts" ? 2 : status === "completed" ? 3 : 0;

  return (
    <div className="flex min-w-[620px] items-center gap-0">
      {steps.map((s, i) => (
        <React.Fragment key={s.key}>
          <div className="flex flex-col items-center gap-1 flex-shrink-0">
            <div className={`w-7 h-7 rounded-full flex items-center justify-center border-2 text-xs font-bold ${
              i < doneIdx ? "border-success bg-success text-white" :
              i === doneIdx ? "bg-primary border-primary text-primary-foreground" :
              "bg-white border-slate-300 text-slate-400"
            }`}>
              {i < doneIdx ? "✓" : i + 1}
            </div>
            <p className={`text-center text-xs font-medium leading-tight ${i <= doneIdx ? "text-slate-700" : "text-slate-400"}`}>{s.label}</p>
            {s.time && i < doneIdx + 1 && <p className="mono text-xs text-slate-400">{s.time}</p>}
          </div>
          {i < steps.length - 1 && (
            <div className={`mx-1 mb-5 h-0.5 flex-1 ${i < doneIdx ? "bg-success" : "bg-border"}`} />
          )}
        </React.Fragment>
      ))}
    </div>
  );
}

export default function RepairOrders() {
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<string | null>(mockRepairOrders[0]?.id ?? null);
  const [showCreate, setShowCreate] = useState(false);

  const selectedOrder = mockRepairOrders.find(r => r.id === selected);

  const filtered = mockRepairOrders.filter(r =>
    !search || r.vehicle.includes(search) || r.customer.toLowerCase().includes(search.toLowerCase()) || r.id.includes(search)
  );

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <SearchBox value={search} onChange={setSearch} placeholder="Tìm mã phiếu, biển số, khách hàng..." />
        <Button icon={Icons.plus} onClick={() => setShowCreate(true)}>Tạo phiếu mới</Button>
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        {/* List */}
        <div className="space-y-3">
          {filtered.map(r => {
            const total = r.items.reduce((sum, i) => sum + i.qty * i.price, 0);
            const isActive = selected === r.id;
            return (
              <button key={r.id} type="button" onClick={() => setSelected(r.id)} aria-pressed={isActive}
                className={`w-full rounded-lg border bg-white p-4 text-left transition-all hover:border-primary ${isActive ? "border-primary ring-1 ring-primary" : "border-border"}`}>
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <span className="mono text-xs text-slate-400">{r.id}</span>
                    <p className="font-semibold text-slate-800 text-sm mt-0.5">{r.vehicle}</p>
                    <p className="text-xs text-slate-500">{r.customer}</p>
                  </div>
                  <Badge variant={r.status as any} />
                </div>
                <div className="flex items-center justify-between mt-3">
                  <span className="text-xs text-slate-500">{r.technician}</span>
                  <span className="text-sm font-bold text-primary">{formatCurrency(total)}</span>
                </div>
              </button>
            );
          })}
        </div>

        {/* Detail */}
        <div className="xl:col-span-2">
          {selectedOrder ? (
            <Card className="p-4 sm:p-5 lg:p-6">
              {/* Header */}
              <div className="mb-6 flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
                <div>
                  <div className="flex items-center gap-3 mb-1">
                    <span className="mono text-sm text-slate-400">{selectedOrder.id}</span>
                    <Badge variant={selectedOrder.status as any} />
                  </div>
                  <h2 className="text-xl font-bold text-slate-800">{selectedOrder.vehicle}</h2>
                  <p className="text-slate-500">{selectedOrder.customer} · KM hiện tại: {selectedOrder.km.toLocaleString("vi-VN")} km</p>
                </div>
                <div className="flex gap-2">
                  <Button variant="outline" size="sm" icon={Icons.printer}>In phiếu</Button>
                  <Button size="sm" icon={Icons.edit}>Chỉnh sửa</Button>
                </div>
              </div>

              {/* Timeline */}
              <div className="mb-6 overflow-x-auto rounded-lg bg-surface-subtle p-4">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-4">Tiến độ xử lý</p>
                <RepairTimeline status={selectedOrder.status} />
              </div>

              {/* Info */}
              <div className="mb-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
                <div className="rounded-lg bg-surface-subtle p-3">
                  <p className="text-xs text-slate-500 mb-1">Phiếu tiếp nhận</p>
                  <p className="font-semibold text-sm mono">{selectedOrder.receptionId}</p>
                </div>
                <div className="rounded-lg bg-surface-subtle p-3">
                  <p className="text-xs text-slate-500 mb-1">Ngày lập</p>
                  <p className="font-semibold text-sm">{selectedOrder.created.split("-").reverse().join("/")}</p>
                </div>
                <div className="rounded-lg bg-surface-subtle p-3">
                  <p className="text-xs text-slate-500 mb-1">Kỹ thuật viên</p>
                  <p className="font-semibold text-sm">{selectedOrder.technician}</p>
                </div>
                <div className="rounded-lg bg-surface-subtle p-3">
                  <p className="text-xs text-slate-500 mb-1">Ngày bắt đầu</p>
                  <p className="font-semibold text-sm">{selectedOrder.started.split("-").reverse().join("/")}</p>
                </div>
              </div>

              {/* Items */}
              <div className="mb-4">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Hạng mục sửa chữa</p>
                <TableContainer>
                <table className="w-full data-table">
                  <thead>
                    <tr>
                      <th>Loại</th>
                      <th>Nội dung</th>
                      <th className="text-right">SL</th>
                      <th className="text-right">Đơn giá</th>
                      <th className="text-right">Thành tiền</th>
                      <th>Trạng thái</th>
                    </tr>
                  </thead>
                  <tbody>
                    {selectedOrder.items.map((item, i) => (
                      <tr key={i}>
                        <td>
                          <span className={`rounded px-2 py-0.5 text-xs font-medium ${item.type === "service" ? "bg-info-soft text-info" : "bg-primary-soft text-primary"}`}>
                            {item.type === "service" ? "Dịch vụ" : "Phụ tùng"}
                          </span>
                        </td>
                        <td className="font-medium text-slate-700">{item.name}</td>
                        <td className="text-right">{item.qty}</td>
                        <td className="text-right text-slate-600">{formatCurrency(item.price)}</td>
                        <td className="text-right font-semibold">{formatCurrency(item.qty * item.price)}</td>
                        <td>
                          {item.done
                            ? <span className="flex items-center gap-1 text-xs text-success">{Icons.checkCircle} Xong</span>
                            : <span className="flex items-center gap-1 text-xs text-warning">{Icons.info} Chờ</span>
                          }
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                </TableContainer>
              </div>

              {/* Total */}
              <div className="flex justify-end">
                <div className="rounded-lg bg-primary px-6 py-3 text-primary-foreground">
                  <span className="text-sm opacity-80">Tổng cộng</span>
                  <p className="text-xl font-bold">
                    {formatCurrency(selectedOrder.items.reduce((s, i) => s + i.qty * i.price, 0))}
                  </p>
                </div>
              </div>

              {/* Notes */}
              {selectedOrder.notes && (
                <div className="mt-4 rounded-lg border border-warning/25 bg-warning-soft p-3">
                  <p className="text-xs font-medium text-warning">{Icons.info} Ghi chú: {selectedOrder.notes}</p>
                </div>
              )}

              {/* Actions */}
              {selectedOrder.status === "in_progress" && (
                <div className="mt-4 flex flex-col gap-3 sm:flex-row sm:flex-wrap">
                  <Button variant="accent" icon={Icons.package}>Yêu cầu phụ tùng</Button>
                  <Button variant="secondary">Cập nhật tiến độ</Button>
                  <Button variant="primary" icon={Icons.checkCircle}>Hoàn tất sửa chữa</Button>
                </div>
              )}
            </Card>
          ) : (
            <Card className="flex items-center justify-center h-64">
              <div className="text-center text-slate-400">
                <span className="mb-2 flex justify-center text-primary" aria-hidden="true">{Icons.fileText}</span>
                <p className="text-sm">Chọn một phiếu sửa chữa để xem chi tiết</p>
              </div>
            </Card>
          )}
        </div>
      </div>

      <Modal open={showCreate} onClose={() => setShowCreate(false)} title="Lập phiếu sửa chữa">
        <div className="space-y-4">
          <div className="rounded-lg border border-info/25 bg-info-soft p-3 text-xs text-info">
            Kiểm tra xe là bước bắt buộc trước khi lập phiếu sửa chữa.
          </div>
          <Select label="Phiếu tiếp nhận *" options={[
            { value: "", label: "-- Chọn phiếu tiếp nhận --" },
            ...phieuTiepNhan.map((reception) => {
              const vehicle = xe.find((item) => item.MaXe === reception.MaXe);
              return { value: reception.MaTiepNhan, label: `${reception.MaTiepNhan} – ${vehicle?.BienSo ?? reception.MaXe}` };
            }),
          ]} />
          <Select label="Trạng thái ban đầu" options={[{ value: "pending", label: "Chờ xử lý" }]} />
          <div className="flex justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setShowCreate(false)}>Hủy</Button>
            <Button onClick={() => setShowCreate(false)}>Lập phiếu sửa chữa</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
