import React, { useState } from "react";
import { Card, Badge, Button, Modal, Icons, Input, Textarea } from "../components/ui";
import { mockRepairOrders, mockInventory, formatCurrency } from "../mock/data";

const MY_JOBS = mockRepairOrders.filter(r => r.technician === "Trần Văn Khoa");
const INITIAL_ITEMS_DONE = Object.fromEntries(
  MY_JOBS.flatMap((repair) => repair.items.map((item, index) => [`${repair.id}-${index}`, item.done])),
);

function ProgressBar({ done, total }: { done: number; total: number }) {
  const pct = total === 0 ? 0 : Math.round((done / total) * 100);
  return (
    <div>
      <div className="flex justify-between text-xs text-slate-500 mb-1">
        <span>{done}/{total} hạng mục</span>
        <span className="font-semibold text-slate-700">{pct}%</span>
      </div>
      <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
        <div className={`h-full rounded-full transition-all ${pct === 100 ? "bg-success" : "bg-primary"}`} style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

export default function TechnicianView() {
  const [selected, setSelected] = useState(MY_JOBS[0]?.id ?? null);
  const [showPartsModal, setShowPartsModal] = useState(false);
  const [showCompleteModal, setShowCompleteModal] = useState(false);
  const [itemsDone, setItemsDone] = useState<Record<string, boolean>>(INITIAL_ITEMS_DONE);

  const job = MY_JOBS.find(r => r.id === selected);
  const items = job?.items ?? [];
  const doneCount = items.filter((_, i) => itemsDone[`${selected}-${i}`] ?? false).length;

  return (
    <div className="space-y-5">
      {/* Header */}
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center">
        <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary font-bold text-white">K</div>
        <div>
          <h2 className="font-bold text-slate-800">Trần Văn Khoa</h2>
          <p className="text-xs text-slate-500">Kỹ thuật viên · Gara Ô Tô Thành Công</p>
        </div>
        <div className="flex flex-wrap items-center gap-2 sm:ml-auto">
          <div className="px-3 py-1.5 bg-emerald-50 border border-emerald-200 rounded-lg text-xs font-medium text-emerald-700">
            ● Ca sáng: 07:00 – 12:00
          </div>
          <div className="rounded-lg bg-primary-soft px-3 py-1.5 text-xs font-medium text-primary">
            {MY_JOBS.length} công việc hôm nay
          </div>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        {/* Job list */}
        <div className="space-y-3">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Công việc được phân công</p>
          {MY_JOBS.map(r => {
            const myItems = r.items;
            const done = myItems.filter((_, i) => itemsDone[`${r.id}-${i}`]).length;
            return (
              <button key={r.id} type="button" onClick={() => setSelected(r.id)} aria-pressed={selected === r.id}
                className={`w-full cursor-pointer rounded-lg border bg-surface p-4 text-left transition-all hover:border-primary ${selected === r.id ? "border-primary ring-1 ring-primary" : "border-border"}`}>
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <span className="mono text-xs text-slate-400">{r.id}</span>
                    <p className="font-semibold text-slate-800 text-sm mt-0.5">{r.vehicle}</p>
                    <p className="text-xs text-slate-500">{r.customer}</p>
                  </div>
                  <Badge variant={r.status as any} />
                </div>
                <ProgressBar done={done} total={myItems.length} />
              </button>
            );
          })}
          {MY_JOBS.length === 0 && (
            <div className="rounded-lg border border-border bg-surface p-8 text-center text-slate-400">
              <p className="text-sm">Không có công việc được phân công</p>
            </div>
          )}
        </div>

        {/* Job detail */}
        <div className="xl:col-span-2">
          {job ? (
            <Card className="p-5">
              {/* Header */}
              <div className="flex items-start justify-between mb-5">
                <div>
                  <div className="flex items-center gap-3 mb-1">
                    <span className="mono text-sm text-slate-400">{job.id}</span>
                    <Badge variant={job.status as any} />
                  </div>
                  <h2 className="text-xl font-bold text-slate-800">{job.vehicle}</h2>
                  <p className="text-slate-500">{job.customer} · {job.km.toLocaleString("vi-VN")} km</p>
                </div>
                <div className="flex gap-2">
                  <Button variant="secondary" size="sm" icon={Icons.package} onClick={() => setShowPartsModal(true)}>
                    Yêu cầu phụ tùng
                  </Button>
                </div>
              </div>

              {/* Overall progress */}
              <div className="mb-5 rounded-lg bg-surface-subtle p-4">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Tiến độ tổng thể</p>
                <ProgressBar done={doneCount} total={items.length} />
              </div>

              {/* Items checklist */}
              <div className="mb-5">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Hạng mục cần thực hiện</p>
                <div className="space-y-2">
                  {items.map((item, i) => {
                    const key = `${selected}-${i}`;
                    const done = itemsDone[key] ?? false;
                    return (
                      <div key={i}
                        className={`flex items-center gap-4 rounded-lg border p-4 transition-all ${done ? "border-success/20 bg-success-soft" : "border-border bg-surface"}`}>
                        <button
                          onClick={() => setItemsDone(prev => ({ ...prev, [key]: !done }))}
                          className={`flex h-6 w-6 flex-shrink-0 items-center justify-center rounded-md border-2 transition-all ${done ? "border-success bg-success" : "border-slate-300 hover:border-primary"}`}>
                          {done && <svg className="w-3.5 h-3.5 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><path d="m20 6-11 11-5-5"/></svg>}
                        </button>
                        <div className="flex-1">
                          <div className="flex items-center gap-2">
                            <span className={`text-xs px-2 py-0.5 rounded font-medium ${item.type === "service" ? "bg-blue-100 text-blue-700" : "bg-purple-100 text-purple-700"}`}>
                              {item.type === "service" ? "Dịch vụ" : "Phụ tùng"}
                            </span>
                            <span className={`text-sm font-medium ${done ? "text-emerald-700 line-through" : "text-slate-800"}`}>{item.name}</span>
                          </div>
                          {item.type === "parts" && (
                            <p className="text-xs text-slate-400 mt-0.5">
                              SL: {item.qty} · {formatCurrency(item.price)}/cái · {done ? "Đã xác nhận sử dụng/thay thế" : "Chưa xác nhận sử dụng"}
                            </p>
                          )}
                        </div>
                        {done && <span className="text-xs text-emerald-600 font-medium">✓ Đã hoàn tất</span>}
                      </div>
                    );
                  })}
                </div>
              </div>

              {/* Notes */}
              {job.notes && (
                <div className="mb-5 p-3 bg-amber-50 border border-amber-100 rounded-lg">
                  <p className="text-xs font-medium text-amber-800">📌 Ghi chú: {job.notes}</p>
                </div>
              )}

              {/* Technical notes */}
              <div className="mb-5"><Textarea label="Ghi chú kỹ thuật" placeholder="Ghi kết quả kiểm tra, tình trạng phát hiện thêm..." /></div>

              {/* Actions */}
              <div className="flex gap-3 border-t border-border pt-3">
                <Button variant="secondary" onClick={() => {}}>Lưu tiến độ</Button>
                <div className="ml-auto">
                  {doneCount === items.length && items.length > 0 ? (
                    <Button icon={Icons.checkCircle} onClick={() => setShowCompleteModal(true)}>
                      Xác nhận hoàn tất
                    </Button>
                  ) : (
                    <Button disabled variant="outline">
                      Hoàn tất ({doneCount}/{items.length})
                    </Button>
                  )}
                </div>
              </div>
            </Card>
          ) : (
            <Card className="flex items-center justify-center h-64 text-slate-400">
              <p className="text-sm">Chọn một công việc để bắt đầu</p>
            </Card>
          )}
        </div>
      </div>

      {/* Request Parts Modal */}
      <Modal open={showPartsModal} onClose={() => setShowPartsModal(false)} title="Yêu cầu phụ tùng từ kho">
        <div className="space-y-4">
          <div className="rounded-lg bg-primary-soft p-3 text-sm">
            <p className="font-medium text-primary">Phiếu sửa chữa: <span className="mono">{job?.id}</span> – {job?.vehicle}</p>
          </div>
          <p className="text-xs text-slate-500">Chỉ gửi yêu cầu khi công việc thực sự cần phụ tùng; phiếu sửa chữa không bắt buộc phải có phiếu xuất kho.</p>
          <div className="space-y-3">
            {mockInventory.slice(0, 5).map((item) => (
              <div key={item.id} className="flex items-center gap-4 p-3 bg-slate-50 rounded-lg">
                <div className="flex-1">
                  <p className="text-sm font-medium text-slate-800">{item.name}</p>
                  <p className="text-xs text-slate-400">Tồn kho: {item.stock}</p>
                </div>
                <div className="flex items-center gap-2">
                  <Input type="number" min={0} max={item.stock} defaultValue={0} className="h-8 w-16 text-center" />
                  <span className="text-xs text-slate-400">SL</span>
                </div>
                <Badge variant={item.status as any} />
              </div>
            ))}
          </div>
          <Textarea label="Lý do yêu cầu" defaultValue="Thay phụ tùng theo phiếu sửa chữa" />
          <div className="flex gap-3 justify-end">
            <Button variant="outline" onClick={() => setShowPartsModal(false)}>Hủy</Button>
            <Button icon={Icons.send} onClick={() => setShowPartsModal(false)}>Gửi yêu cầu đến kho</Button>
          </div>
        </div>
      </Modal>

      {/* Complete Modal */}
      <Modal open={showCompleteModal} onClose={() => setShowCompleteModal(false)} title="Xác nhận hoàn tất sửa chữa">
        <div className="space-y-4">
          <div className="rounded-lg border border-success/20 bg-success-soft p-4">
            <p className="font-semibold text-emerald-800">Tất cả hạng mục đã hoàn thành!</p>
            <p className="text-xs text-emerald-700 mt-1">Xe {job?.vehicle} sẽ được chuyển sang trạng thái "Hoàn tất sửa chữa".</p>
          </div>
          <Textarea label="Ghi chú bàn giao" defaultValue="Đã hoàn tất tất cả hạng mục. Xe trong tình trạng tốt, sẵn sàng bàn giao." />
          <div className="flex gap-3 justify-end">
            <Button variant="outline" onClick={() => setShowCompleteModal(false)}>Hủy</Button>
            <Button icon={Icons.checkCircle} onClick={() => setShowCompleteModal(false)}>Xác nhận hoàn tất</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
