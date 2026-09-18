import React, { useState } from "react";
import { Card, Badge, Button, SearchBox, Modal, Input, Select, Icons, Tabs } from "../components/ui";
import { formatCurrency } from "../data";

const SERVICES = [
  { id: "DV001", name: "Bảo dưỡng định kỳ 10.000 km", category: "Bảo dưỡng", price: 180000, duration: 90, status: "active", count: 48 },
  { id: "DV002", name: "Bảo dưỡng định kỳ 30.000 km", category: "Bảo dưỡng", price: 250000, duration: 120, status: "active", count: 32 },
  { id: "DV003", name: "Bảo dưỡng định kỳ 60.000 km", category: "Bảo dưỡng", price: 380000, duration: 180, status: "active", count: 21 },
  { id: "DV004", name: "Kiểm tra và sửa hệ thống phanh", category: "Sửa chữa", price: 200000, duration: 60, status: "active", count: 28 },
  { id: "DV005", name: "Sửa chữa hệ thống điều hòa", category: "Điện – Điều hòa", price: 350000, duration: 120, status: "active", count: 19 },
  { id: "DV006", name: "Chẩn đoán lỗi động cơ (OBD)", category: "Chẩn đoán", price: 150000, duration: 45, status: "active", count: 35 },
  { id: "DV007", name: "Thay lốp xe (1 lốp)", category: "Lốp xe", price: 80000, duration: 30, status: "active", count: 42 },
  { id: "DV008", name: "Cân bằng động & chỉnh góc bánh xe", category: "Lốp xe", price: 160000, duration: 60, status: "active", count: 24 },
  { id: "DV009", name: "Nạp gas điều hòa", category: "Điện – Điều hòa", price: 280000, duration: 60, status: "active", count: 18 },
  { id: "DV010", name: "Vệ sinh buồng đốt", category: "Động cơ", price: 220000, duration: 90, status: "active", count: 15 },
  { id: "DV011", name: "Kiểm tra hệ thống treo", category: "Sửa chữa", price: 120000, duration: 45, status: "active", count: 12 },
  { id: "DV012", name: "Đánh bóng sơn xe", category: "Ngoại thất", price: 1200000, duration: 360, status: "inactive", count: 6 },
];

const CATEGORIES = ["Tất cả", "Bảo dưỡng", "Sửa chữa", "Điện – Điều hòa", "Lốp xe", "Động cơ", "Chẩn đoán", "Ngoại thất"];

export default function Services() {
  const [search, setSearch] = useState("");
  const [category, setCategory] = useState("Tất cả");
  const [showAdd, setShowAdd] = useState(false);
  const [selected, setSelected] = useState<string | null>(null);

  const filtered = SERVICES.filter(s => {
    const matchCat = category === "Tất cả" || s.category === category;
    const matchSearch = !search || s.name.toLowerCase().includes(search.toLowerCase());
    return matchCat && matchSearch;
  });

  const detail = SERVICES.find(s => s.id === selected);
  const totalRevenue = SERVICES.reduce((sum, s) => sum + s.count * s.price, 0);

  return (
    <div className="p-6 space-y-5">
      {/* Summary cards */}
      <div className="grid grid-cols-4 gap-4">
        {[
          { label: "Tổng dịch vụ", value: SERVICES.length, icon: "🔧", color: "bg-[#e8eef7] text-[#1e3a6e]" },
          { label: "Đang hoạt động", value: SERVICES.filter(s => s.status === "active").length, icon: "✅", color: "bg-emerald-50 text-emerald-700" },
          { label: "Lượt dùng tháng này", value: SERVICES.reduce((s, x) => s + x.count, 0), icon: "📊", color: "bg-blue-50 text-blue-700" },
          { label: "Doanh thu dịch vụ", value: `${(totalRevenue / 1000000).toFixed(1)}M`, icon: "💰", color: "bg-amber-50 text-amber-700" },
        ].map(c => (
          <div key={c.label} className="bg-white rounded-xl border border-[#dde3ec] card-shadow p-4 flex items-center gap-3">
            <div className={`w-10 h-10 rounded-xl flex items-center justify-center text-xl ${c.color}`}>{c.icon}</div>
            <div>
              <p className="text-xs text-slate-500">{c.label}</p>
              <p className="text-xl font-bold text-slate-800">{c.value}</p>
            </div>
          </div>
        ))}
      </div>

      {/* Toolbar */}
      <div className="flex items-center justify-between gap-4 flex-wrap">
        <div className="flex items-center gap-3 flex-wrap">
          <SearchBox value={search} onChange={setSearch} placeholder="Tên dịch vụ..." />
          <div className="flex gap-1.5 flex-wrap">
            {CATEGORIES.map(cat => (
              <button key={cat} onClick={() => setCategory(cat)}
                className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-all ${category === cat ? "bg-[#1e3a6e] text-white border-[#1e3a6e]" : "bg-white text-slate-600 border-[#dde3ec] hover:border-[#1e3a6e]"}`}>
                {cat}
              </button>
            ))}
          </div>
        </div>
        <Button icon={Icons.plus} onClick={() => setShowAdd(true)}>Thêm dịch vụ</Button>
      </div>

      <div className={`grid gap-4 ${selected ? "grid-cols-3" : "grid-cols-1"}`}>
        {/* Table */}
        <div className={selected ? "col-span-2" : ""}>
          <Card>
            <table className="w-full data-table">
              <thead>
                <tr>
                  <th>Mã DV</th>
                  <th>Tên dịch vụ</th>
                  <th>Danh mục</th>
                  <th className="text-right">Đơn giá</th>
                  <th className="text-right">Thời gian (phút)</th>
                  <th className="text-right">Lượt dùng</th>
                  <th>Trạng thái</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(s => (
                  <tr key={s.id} className={`cursor-pointer ${selected === s.id ? "bg-blue-50" : ""}`}
                    onClick={() => setSelected(s.id === selected ? null : s.id)}>
                    <td><span className="mono text-xs text-slate-400">{s.id}</span></td>
                    <td><span className="font-medium text-slate-800">{s.name}</span></td>
                    <td>
                      <span className="text-xs bg-[#e8eef7] text-[#1e3a6e] px-2 py-1 rounded-full font-medium">{s.category}</span>
                    </td>
                    <td className="text-right font-semibold mono text-sm">{formatCurrency(s.price)}</td>
                    <td className="text-right text-slate-600">{s.duration}</td>
                    <td className="text-right">
                      <div className="flex items-center justify-end gap-2">
                        <div className="w-16 h-1.5 bg-slate-100 rounded-full overflow-hidden">
                          <div className="h-full bg-[#1e3a6e] rounded-full" style={{ width: `${Math.min(100, (s.count / 50) * 100)}%` }} />
                        </div>
                        <span className="text-sm font-semibold text-slate-700 w-6 text-right">{s.count}</span>
                      </div>
                    </td>
                    <td>
                      <Badge variant={s.status === "active" ? "completed" : "cancelled"}
                        label={s.status === "active" ? "Đang dùng" : "Tạm dừng"} />
                    </td>
                    <td>
                      <div className="flex gap-1">
                        <button className="p-1.5 hover:bg-slate-100 rounded text-slate-500">{Icons.edit}</button>
                        <button className={`p-1.5 hover:bg-slate-100 rounded text-xs font-medium px-2 ${s.status === "active" ? "text-amber-600" : "text-emerald-600"}`}>
                          {s.status === "active" ? "Tạm dừng" : "Kích hoạt"}
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
                {filtered.length === 0 && (
                  <tr><td colSpan={8} className="text-center py-12 text-slate-400 text-sm">Không tìm thấy dịch vụ</td></tr>
                )}
              </tbody>
            </table>
            <div className="px-4 py-3 border-t border-[#dde3ec] text-xs text-slate-500">
              Hiển thị {filtered.length} / {SERVICES.length} dịch vụ
            </div>
          </Card>
        </div>

        {/* Detail panel */}
        {detail && (
          <Card className="p-5 h-fit space-y-5">
            <div className="flex items-start justify-between">
              <div>
                <span className="mono text-xs text-slate-400">{detail.id}</span>
                <h3 className="font-bold text-slate-800 mt-1 leading-tight">{detail.name}</h3>
              </div>
              <button onClick={() => setSelected(null)} className="p-1 hover:bg-slate-100 rounded text-slate-400">✕</button>
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="p-3 bg-slate-50 rounded-xl">
                <p className="text-xs text-slate-400 mb-1">Danh mục</p>
                <span className="text-xs bg-[#e8eef7] text-[#1e3a6e] px-2 py-1 rounded-full font-medium">{detail.category}</span>
              </div>
              <div className="p-3 bg-slate-50 rounded-xl">
                <p className="text-xs text-slate-400 mb-1">Trạng thái</p>
                <Badge variant={detail.status === "active" ? "completed" : "cancelled"}
                  label={detail.status === "active" ? "Đang hoạt động" : "Tạm dừng"} />
              </div>
              <div className="p-3 bg-slate-50 rounded-xl">
                <p className="text-xs text-slate-400 mb-1">Đơn giá</p>
                <p className="font-bold text-[#1e3a6e]">{formatCurrency(detail.price)}</p>
              </div>
              <div className="p-3 bg-slate-50 rounded-xl">
                <p className="text-xs text-slate-400 mb-1">Thời gian</p>
                <p className="font-semibold text-slate-800">{detail.duration} phút</p>
              </div>
            </div>

            <div className="p-4 bg-[#e8eef7] rounded-xl">
              <p className="text-xs text-slate-500 mb-1">Lượt sử dụng tháng 9/2024</p>
              <p className="text-2xl font-black text-[#1e3a6e]">{detail.count} lượt</p>
              <p className="text-xs text-slate-500 mt-1">Doanh thu: <strong className="text-[#1e3a6e]">{formatCurrency(detail.count * detail.price)}</strong></p>
            </div>

            {/* Usage bar */}
            <div>
              <div className="flex justify-between text-xs text-slate-500 mb-1.5">
                <span>Tỷ lệ so với dịch vụ phổ biến nhất</span>
                <span className="font-semibold">{Math.round((detail.count / 48) * 100)}%</span>
              </div>
              <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
                <div className="h-full bg-[#1e3a6e] rounded-full transition-all" style={{ width: `${Math.min(100, (detail.count / 48) * 100)}%` }} />
              </div>
            </div>

            <div className="flex gap-2">
              <Button variant="secondary" size="sm" className="flex-1" icon={Icons.edit}>Chỉnh sửa</Button>
              <Button variant={detail.status === "active" ? "outline" : "primary"} size="sm" className="flex-1">
                {detail.status === "active" ? "Tạm dừng" : "Kích hoạt"}
              </Button>
            </div>
          </Card>
        )}
      </div>

      {/* Add Service Modal */}
      <Modal open={showAdd} onClose={() => setShowAdd(false)} title="Thêm dịch vụ mới">
        <div className="space-y-4">
          <Input label="Tên dịch vụ *" placeholder="Ví dụ: Bảo dưỡng định kỳ 45.000 km" />
          <div className="grid grid-cols-2 gap-4">
            <Select label="Danh mục *" options={CATEGORIES.filter(c => c !== "Tất cả").map(c => ({ value: c, label: c }))} />
            <Input label="Đơn giá (VNĐ) *" placeholder="250000" type="number" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Thời gian ước tính (phút)" placeholder="90" type="number" />
            <Select label="Trạng thái" options={[{ value: "active", label: "Đang hoạt động" }, { value: "inactive", label: "Tạm dừng" }]} />
          </div>
          <div>
            <label className="text-xs font-medium text-slate-600 block mb-1">Mô tả dịch vụ</label>
            <textarea className="w-full border border-[#dde3ec] rounded-lg text-sm px-3 py-2 h-20 resize-none focus:border-[#3b6fd4] focus:outline-none" placeholder="Mô tả chi tiết dịch vụ..." />
          </div>
          <div className="flex gap-3 justify-end pt-2">
            <Button variant="outline" onClick={() => setShowAdd(false)}>Hủy</Button>
            <Button onClick={() => setShowAdd(false)}>Lưu dịch vụ</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
