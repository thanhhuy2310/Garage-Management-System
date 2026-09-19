import React, { useState } from "react";
import { Card, Button, SearchBox, Icons } from "../components/ui";
import { formatCurrency, mockRepairOrders, phieuSuaChua } from "../data";

export default function History() {
  const [search, setSearch] = useState("");
  const [selected, setSelected] = useState<string | null>(mockRepairOrders.find((repair) => repair.status === "completed")?.id ?? null);

  const completed = mockRepairOrders.filter(r => r.status === "completed");
  const filtered = completed.filter(r =>
    !search || r.vehicle.includes(search) || r.customer.toLowerCase().includes(search.toLowerCase())
  );
  const detail = filtered.find(r => r.id === selected);
  const completedAt = (repairId: string) => phieuSuaChua.find((item) => item.MaPhieuSuaChua === repairId)?.NgayHoanThanh;

  return (
    <div className="space-y-5">
      <div className="page-toolbar sm:justify-start">
        <SearchBox value={search} onChange={setSearch} placeholder="Biển số, khách hàng..." />
        <input type="date" aria-label="Từ ngày" className="h-10 rounded-md border border-border bg-white px-3 text-sm shadow-sm" />
        <input type="date" aria-label="Đến ngày" className="h-10 rounded-md border border-border bg-white px-3 text-sm shadow-sm" />
        <Button variant="outline" size="sm" icon={Icons.download}>Xuất</Button>
      </div>

      <div className={`grid gap-4 ${selected ? "xl:grid-cols-2" : "grid-cols-1"}`}>
        <Card>
          <table className="w-full data-table">
            <thead>
              <tr>
                <th>Mã phiếu</th>
                <th>Ngày hoàn tất</th>
                <th>Xe</th>
                <th>Khách hàng</th>
                <th className="text-right">Số km</th>
                <th>Kỹ thuật viên</th>
                <th className="text-right">Tổng chi phí</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(r => {
                const total = r.items.reduce((s, i) => s + i.qty * i.price, 0);
                return (
                  <tr key={r.id} className={`cursor-pointer ${selected === r.id ? "bg-info-soft" : ""}`}
                    onClick={() => setSelected(r.id === selected ? null : r.id)}>
                    <td><span className="mono text-xs text-slate-400">{r.id}</span></td>
                    <td className="text-slate-600">{completedAt(r.id) ? new Date(completedAt(r.id)!).toLocaleString("vi-VN") : "—"}</td>
                    <td><span className="mono font-bold text-primary">{r.vehicle}</span></td>
                    <td className="font-medium text-slate-800">{r.customer}</td>
                    <td className="text-right mono text-sm">{r.km.toLocaleString("vi-VN")}</td>
                    <td className="text-slate-600">{r.technician}</td>
                    <td className="text-right font-bold">{formatCurrency(total)}</td>
                    <td><button aria-label={`Xem chi tiết phiếu ${r.id}`} className="flex h-9 w-9 items-center justify-center rounded text-slate-500 hover:bg-slate-100">{Icons.chevronRight}</button></td>
                  </tr>
                );
              })}
              {filtered.length === 0 && (
                <tr><td colSpan={8} className="text-center py-12 text-slate-400 text-sm">Không có kết quả</td></tr>
              )}
            </tbody>
          </table>
        </Card>

        {detail && (
          <Card className="detail-panel h-fit p-5">
            <div className="flex items-center justify-between mb-4">
              <div>
                <div className="flex items-center gap-2 mb-1">
                  <span className="mono text-xs text-slate-400">{detail.id}</span>
                </div>
                <p className="mono text-xl font-bold text-primary">{detail.vehicle}</p>
                <p className="text-slate-500 text-sm">{detail.customer}</p>
              </div>
              <button aria-label="Đóng chi tiết lịch sử" onClick={() => setSelected(null)} className="flex h-9 w-9 items-center justify-center rounded text-slate-500 hover:bg-slate-100">✕</button>
            </div>

            <div className="mb-5 grid grid-cols-1 gap-3 sm:grid-cols-2">
              <div className="rounded-lg bg-surface-subtle p-3 text-sm"><p className="text-xs text-muted-foreground">Ngày hoàn thành</p><p className="font-semibold">{completedAt(detail.id) ? new Date(completedAt(detail.id)!).toLocaleString("vi-VN") : "—"}</p></div>
              <div className="rounded-lg bg-surface-subtle p-3 text-sm"><p className="text-xs text-muted-foreground">Số km</p><p className="mono font-semibold">{detail.km.toLocaleString("vi-VN")}</p></div>
              <div className="rounded-lg bg-surface-subtle p-3 text-sm"><p className="text-xs text-muted-foreground">Kỹ thuật viên</p><p className="font-semibold">{detail.technician}</p></div>
              <div className="rounded-lg bg-surface-subtle p-3 text-sm"><p className="text-xs text-slate-400">Tổng chi phí</p><p className="font-bold text-primary">{formatCurrency(detail.items.reduce((s, i) => s + i.qty * i.price, 0))}</p></div>
            </div>

            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Hạng mục đã làm</p>
            <div className="space-y-2">
              {detail.items.map((item, i) => (
                <div key={i} className="flex items-center justify-between rounded-lg bg-surface-subtle p-3">
                  <div className="flex items-center gap-2">
                    <span className={`rounded px-2 py-0.5 text-xs font-medium ${item.type === "service" ? "bg-info-soft text-info" : "bg-primary-soft text-primary"}`}>
                      {item.type === "service" ? "DV" : "PT"}
                    </span>
                    <span className="text-sm font-medium text-slate-700">{item.name}</span>
                  </div>
                  <span className="text-sm font-semibold text-slate-800">{formatCurrency(item.qty * item.price)}</span>
                </div>
              ))}
            </div>

            <div className="flex gap-2 mt-5">
              <Button variant="outline" size="sm" icon={Icons.printer} className="flex-1">In hóa đơn</Button>
            </div>
          </Card>
        )}
      </div>
    </div>
  );
}
