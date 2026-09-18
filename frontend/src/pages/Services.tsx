import { useMemo, useState } from "react";
import { Button, Card, Icons, Input, Modal, SearchBox, Select } from "../components/ui";
import { dichVu, formatCurrency } from "../mock/data";

export default function Services() {
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("Tất cả");
  const [showAdd, setShowAdd] = useState(false);
  const [selected, setSelected] = useState<string | null>(null);

  const categories = useMemo(
    () => ["Tất cả", ...Array.from(new Set(dichVu.map((service) => service.LoaiDichVu).filter(Boolean))) as string[]],
    [],
  );
  const keyword = search.trim().toLowerCase();
  const filtered = dichVu.filter((service) =>
    (category === "Tất cả" || service.LoaiDichVu === category)
    && (!keyword || service.TenDichVu.toLowerCase().includes(keyword)),
  );
  const detail = dichVu.find((service) => service.MaDichVu === selected);
  const averagePrice = dichVu.length
    ? dichVu.reduce((sum, service) => sum + service.DonGia, 0) / dichVu.length
    : 0;

  return (
    <div className="space-y-5">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        {[
          { label: "Tổng dịch vụ", value: dichVu.length, icon: "🔧" },
          { label: "Nhóm dịch vụ", value: categories.length - 1, icon: "📋" },
          { label: "Đơn giá trung bình", value: formatCurrency(averagePrice), icon: "💰" },
        ].map((item) => (
          <Card key={item.label} className="flex items-center gap-3 p-4">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-[#e8eef7] text-xl">{item.icon}</div>
            <div><p className="text-xs text-slate-500">{item.label}</p><p className="text-xl font-bold text-slate-800">{item.value}</p></div>
          </Card>
        ))}
      </div>

      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex flex-wrap items-center gap-3">
          <SearchBox value={search} onChange={setSearch} placeholder="Tên dịch vụ..." />
          <div className="flex flex-wrap gap-1.5">
            {categories.map((item) => (
              <button key={item} type="button" onClick={() => setCategory(item)} className={`rounded-full border px-3 py-1.5 text-xs font-medium ${category === item ? "border-[#1e3a6e] bg-[#1e3a6e] text-white" : "border-[#dde3ec] bg-white text-slate-600 hover:border-[#1e3a6e]"}`}>{item}</button>
            ))}
          </div>
        </div>
        <Button icon={Icons.plus} onClick={() => setShowAdd(true)}>Thêm dịch vụ</Button>
      </div>

      <div className={`grid gap-4 ${selected ? "xl:grid-cols-3" : "grid-cols-1"}`}>
        <div className={selected ? "xl:col-span-2" : ""}>
          <Card className="overflow-x-auto">
            <table className="data-table w-full min-w-[720px]">
              <thead><tr><th>Mã DV</th><th>Tên dịch vụ</th><th>Loại dịch vụ</th><th className="text-right">Đơn giá</th><th>Mô tả</th><th>Thao tác</th></tr></thead>
              <tbody>
                {filtered.map((service) => (
                  <tr key={service.MaDichVu} onClick={() => setSelected(service.MaDichVu === selected ? null : service.MaDichVu)} className={`cursor-pointer ${selected === service.MaDichVu ? "bg-blue-50" : ""}`}>
                    <td><span className="mono text-xs text-slate-400">{service.MaDichVu}</span></td>
                    <td className="font-medium text-slate-800">{service.TenDichVu}</td>
                    <td><span className="rounded-full bg-[#e8eef7] px-2 py-1 text-xs font-medium text-[#1e3a6e]">{service.LoaiDichVu || "—"}</span></td>
                    <td className="mono text-right font-semibold">{formatCurrency(service.DonGia)}</td>
                    <td className="max-w-[240px] truncate text-slate-500">{service.MoTa || "—"}</td>
                    <td><button type="button" aria-label={`Sửa ${service.TenDichVu}`} className="rounded p-1.5 text-slate-500 hover:bg-slate-100">{Icons.edit}</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
            {filtered.length === 0 && <p className="py-10 text-center text-sm text-slate-400">Không tìm thấy dịch vụ.</p>}
          </Card>
        </div>

        {detail && (
          <Card className="h-fit space-y-4 p-5">
            <div className="flex items-start justify-between">
              <div><span className="mono text-xs text-slate-400">{detail.MaDichVu}</span><h3 className="mt-1 font-bold leading-tight text-slate-800">{detail.TenDichVu}</h3></div>
              <button type="button" onClick={() => setSelected(null)} aria-label="Đóng chi tiết" className="flex h-9 w-9 items-center justify-center rounded text-slate-500 hover:bg-slate-100">✕</button>
            </div>
            <div className="rounded-xl bg-slate-50 p-3"><p className="text-xs text-slate-400">Loại dịch vụ</p><p className="font-semibold">{detail.LoaiDichVu || "Chưa phân loại"}</p></div>
            <div className="rounded-xl bg-slate-50 p-3"><p className="text-xs text-slate-400">Đơn giá</p><p className="font-bold text-[#1e3a6e]">{formatCurrency(detail.DonGia)}</p></div>
            <div><p className="mb-1 text-xs text-slate-400">Mô tả</p><p className="text-sm leading-relaxed text-slate-600">{detail.MoTa || "Chưa có mô tả"}</p></div>
            <Button variant="secondary" size="sm" className="w-full" icon={Icons.edit}>Chỉnh sửa</Button>
          </Card>
        )}
      </div>

      <Modal open={showAdd} onClose={() => setShowAdd(false)} title="Thêm dịch vụ mới">
        <div className="space-y-4">
          <Input label="Tên dịch vụ *" placeholder="Ví dụ: Bảo dưỡng định kỳ" />
          <Select label="Loại dịch vụ" options={[{ value: "", label: "-- Chọn loại --" }, ...categories.filter((item) => item !== "Tất cả").map((item) => ({ value: item, label: item }))]} />
          <Input label="Đơn giá (VNĐ) *" type="number" min="0" placeholder="250000" />
          <div><label className="mb-1 block text-xs font-medium text-slate-600">Mô tả</label><textarea className="h-20 w-full resize-none rounded-lg border border-[#dde3ec] px-3 py-2 text-sm focus:border-[#3b6fd4] focus:outline-none" /></div>
          <div className="flex justify-end gap-3 pt-2"><Button variant="outline" onClick={() => setShowAdd(false)}>Hủy</Button><Button onClick={() => setShowAdd(false)}>Lưu dịch vụ</Button></div>
        </div>
      </Modal>
    </div>
  );
}
