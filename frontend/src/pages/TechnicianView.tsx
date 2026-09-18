import React, { useState } from "react";
import { Card, Badge, Button, Modal, Icons } from "../components/ui";
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
        <div className={`h-full rounded-full transition-all ${pct === 100 ? "bg-emerald-500" : "bg-[#1e3a6e]"}`} style={{ width: `${pct}%` }} />
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
    <div className="p-6 space-y-5">
      {/* Header */}
      <div className="flex items-center gap-4">
        <div className="w-10 h-10 bg-gradient-to-br from-blue-400 to-indigo-600 rounded-xl flex items-center justify-center text-white font-bold">K</div>
        <div>
          <h2 className="font-bold text-slate-800">Trần Văn Khoa</h2>
          <p className="text-xs text-slate-500">Kỹ thuật viên · Gara Ô Tô Thành Công</p>
        </div>
        <div className="ml-auto flex items-center gap-2">
          <div className="px-3 py-1.5 bg-emerald-50 border border-emerald-200 rounded-lg text-xs font-medium text-emerald-700">
            ● Ca sáng: 07:00 – 12:00
          </div>
          <div className="px-3 py-1.5 bg-[#e8eef7] rounded-lg text-xs font-medium text-[#1e3a6e]">
            {MY_JOBS.length} công việc hôm nay
          </div>
        </div>
      </div>

      <div className="grid grid-cols-3 gap-4">
        {/* Job list */}
        <div className="space-y-3">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Công việc được phân công</p>
          {MY_JOBS.map(r => {
            const myItems = r.items;
            const done = myItems.filter((_, i) => itemsDone[`${r.id}-${i}`]).length;
            return (
              <div key={r.id} onClick={() => setSelected(r.id)}
                className={`bg-white rounded-xl border p-4 cursor-pointer transition-all hover:border-[#1e3a6e] ${selected === r.id ? "border-[#1e3a6e] ring-1 ring-[#1e3a6e]" : "border-[#dde3ec]"}`}>
                <div className="flex items-start justify-between mb-2">
                  <div>
                    <span className="mono text-xs text-slate-400">{r.id}</span>
                    <p className="font-semibold text-slate-800 text-sm mt-0.5">{r.vehicle}</p>
                    <p className="text-xs text-slate-500">{r.customer}</p>
                  </div>
                  <Badge variant={r.status as any} />
                </div>
                <ProgressBar done={done} total={myItems.length} />
              </div>
            );
          })}
          {MY_JOBS.length === 0 && (
            <div className="bg-white rounded-xl border border-[#dde3ec] p-8 text-center text-slate-400">
              <p className="text-sm">Không có công việc được phân công</p>
            </div>
          )}
        </div>

        {/* Job detail */}
        <div className="col-span-2">
          {job ? (
            <Card className="p-6">
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
              <div className="mb-5 p-4 bg-slate-50 rounded-xl">
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
                        className={`flex items-center gap-4 p-4 rounded-xl border transition-all ${done ? "bg-emerald-50 border-emerald-200" : "bg-white border-[#dde3ec]"}`}>
                        <button
                          onClick={() => setItemsDone(prev => ({ ...prev, [key]: !done }))}
                          className={`w-6 h-6 rounded-lg border-2 flex items-center justify-center flex-shrink-0 transition-all ${done ? "bg-emerald-500 border-emerald-500" : "border-slate-300 hover:border-[#1e3a6e]"}`}>
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
              <div className="mb-5">
                <label className="text-xs font-semibold text-slate-500 uppercase tracking-wide block mb-2">Ghi chú kỹ thuật</label>
                <textarea
                  className="w-full border border-[#dde3ec] rounded-xl text-sm px-3 py-2 h-20 resize-none focus:border-[#3b6fd4] focus:outline-none"
                  placeholder="Ghi kết quả kiểm tra, tình trạng phát hiện thêm..."
                />
              </div>

              {/* Actions */}
              <div className="flex gap-3 pt-3 border-t border-[#dde3ec]">
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
          <div className="p-3 bg-[#e8eef7] rounded-lg text-sm">
            <p className="font-medium text-[#1e3a6e]">Phiếu sửa chữa: <span className="mono">{job?.id}</span> – {job?.vehicle}</p>
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
                  <input type="number" min={0} max={item.stock} defaultValue={0}
                    className="w-16 h-8 border border-[#dde3ec] rounded-lg px-2 text-sm text-center" />
                  <span className="text-xs text-slate-400">SL</span>
                </div>
                <Badge variant={item.status as any} />
              </div>
            ))}
          </div>
          <div>
            <label className="text-xs font-medium text-slate-600 block mb-1">Lý do yêu cầu</label>
            <textarea className="w-full border border-[#dde3ec] rounded-lg text-sm px-3 py-2 h-16 resize-none focus:border-[#3b6fd4] focus:outline-none"
              defaultValue="Thay phụ tùng theo phiếu sửa chữa" />
          </div>
          <div className="flex gap-3 justify-end">
            <Button variant="outline" onClick={() => setShowPartsModal(false)}>Hủy</Button>
            <Button icon={Icons.send} onClick={() => setShowPartsModal(false)}>Gửi yêu cầu đến kho</Button>
          </div>
        </div>
      </Modal>

      {/* Complete Modal */}
      <Modal open={showCompleteModal} onClose={() => setShowCompleteModal(false)} title="Xác nhận hoàn tất sửa chữa">
        <div className="space-y-4">
          <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl">
            <p className="font-semibold text-emerald-800">Tất cả hạng mục đã hoàn thành!</p>
            <p className="text-xs text-emerald-700 mt-1">Xe {job?.vehicle} sẽ được chuyển sang trạng thái "Hoàn tất sửa chữa".</p>
          </div>
          <div>
            <label className="text-xs font-medium text-slate-600 block mb-1">Ghi chú bàn giao</label>
            <textarea className="w-full border border-[#dde3ec] rounded-lg text-sm px-3 py-2 h-20 resize-none focus:border-[#3b6fd4] focus:outline-none"
              defaultValue="Đã hoàn tất tất cả hạng mục. Xe trong tình trạng tốt, sẵn sàng bàn giao." />
          </div>
          <div className="flex gap-3 justify-end">
            <Button variant="outline" onClick={() => setShowCompleteModal(false)}>Hủy</Button>
            <Button icon={Icons.checkCircle} onClick={() => setShowCompleteModal(false)}>Xác nhận hoàn tất</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
