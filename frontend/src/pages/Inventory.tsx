import React, { useState } from "react";
import { Card, Badge, Button, SearchBox, Tabs, Modal, Input, Select, Icons } from "../components/ui";
import { mockInventory, formatCurrency } from "../data";

const TABS = [
  { key: "stock", label: "Tồn kho" },
  { key: "import", label: "Nhập kho" },
  { key: "export", label: "Xuất kho" },
  { key: "audit", label: "Kiểm kê" },
];

const HISTORY = [
  { date: "17/09 09:30", part: "Lọc dầu Toyota", type: "Xuất", before: 15, change: -3, after: 12, staff: "Trần Văn Khoa", ref: "PSC002" },
  { date: "16/09 14:00", part: "Dầu nhớt Castrol 5W-30", type: "Xuất", before: 52, change: -4, after: 48, staff: "Trần Văn Khoa", ref: "PSC001" },
  { date: "15/09 08:00", part: "Dầu nhớt Castrol 5W-30", type: "Nhập", before: 32, change: 20, after: 52, staff: "Đỗ Văn Nam", ref: "PNK005" },
  { date: "14/09 10:30", part: "Bugi NGK Platinum", type: "Xuất", before: 36, change: -4, after: 32, staff: "Lê Quang Hưng", ref: "PSC003" },
  { date: "12/09 09:00", part: "Lọc gió động cơ", type: "Nhập", before: 3, change: 5, after: 8, staff: "Đỗ Văn Nam", ref: "PNK004" },
];

// Mock import form items
const importItems = [
  { id: "PT001", name: "Dầu nhớt Castrol 5W-30 (1L)", qty: 20, price: 85000 },
  { id: "PT002", name: "Lọc dầu Toyota", qty: 10, price: 95000 },
];

// Mock export items
const exportItems = mockInventory.slice(0, 4);

// Mock audit data
const auditItems = mockInventory.map(i => ({
  ...i,
  actual: i.status === "ok" ? i.stock : i.status === "low" ? i.stock - 2 : 0,
  diff: i.status === "ok" ? 0 : i.status === "low" ? -2 : 0,
}));

export default function Inventory() {
  const [tab, setTab] = useState("stock");
  const [search, setSearch] = useState("");

  const filtered = mockInventory.filter(i =>
    !search || i.name.toLowerCase().includes(search.toLowerCase()) || i.id.includes(search)
  );

  return (
    <div className="p-6 space-y-5">
      <div className="flex items-center justify-between">
        <Tabs tabs={TABS} active={tab} onChange={setTab} />
        <div className="flex gap-2">
          {tab === "import" && <Button icon={Icons.plus}>Tạo phiếu nhập kho</Button>}
          {tab === "export" && <Button icon={Icons.plus}>Tạo phiếu xuất kho</Button>}
          {tab === "audit" && <Button variant="accent">Bắt đầu kiểm kê</Button>}
        </div>
      </div>

      {tab === "stock" && (
        <>
          <div className="flex items-center gap-3">
            <SearchBox value={search} onChange={setSearch} placeholder="Mã, tên phụ tùng..." />
            <Select options={[{ value: "all", label: "Tất cả trạng thái" }, { value: "ok", label: "Còn hàng" }, { value: "low", label: "Sắp hết" }, { value: "out", label: "Hết hàng" }]} className="w-40" />
          </div>

          {/* Alert */}
          {mockInventory.filter(i => i.status !== "ok").length > 0 && (
            <div className="p-4 bg-amber-50 border border-amber-200 rounded-xl flex items-center gap-3">
              <span className="text-amber-500">{Icons.alertTriangle}</span>
              <p className="text-sm text-amber-800">
                <strong>{mockInventory.filter(i => i.status !== "ok").length} mặt hàng</strong> sắp hết hoặc hết hàng cần đặt thêm.
              </p>
              <Button variant="accent" size="sm" className="ml-auto">Tạo yêu cầu nhập</Button>
            </div>
          )}

          <Card>
            <table className="w-full data-table">
              <thead>
                <tr>
                  <th>Mã PT</th>
                  <th>Tên phụ tùng</th>
                  <th>Hãng</th>
                  <th>ĐVT</th>
                  <th className="text-right">Đơn giá</th>
                  <th className="text-right">Tồn hiện tại</th>
                  <th className="text-right">Tồn tối thiểu</th>
                  <th>Trạng thái</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(item => (
                  <tr key={item.id}>
                    <td><span className="mono text-xs text-slate-400">{item.id}</span></td>
                    <td><span className="font-medium text-slate-800">{item.name}</span></td>
                    <td className="text-slate-600">{item.brand}</td>
                    <td className="text-slate-600">{item.unit}</td>
                    <td className="text-right font-mono text-sm">{formatCurrency(item.price)}</td>
                    <td className="text-right">
                      <span className={`font-bold text-sm ${item.status === "ok" ? "text-slate-800" : item.status === "low" ? "text-amber-600" : "text-red-600"}`}>
                        {item.stock}
                      </span>
                    </td>
                    <td className="text-right text-slate-500 text-sm">{item.minStock}</td>
                    <td><Badge variant={item.status as any} /></td>
                    <td>
                      <div className="flex gap-1">
                        <button className="p-1.5 hover:bg-slate-100 rounded text-slate-500">{Icons.eye}</button>
                        <button className="p-1.5 hover:bg-slate-100 rounded text-slate-500">{Icons.edit}</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>

          {/* History */}
          <Card className="p-5">
            <h3 className="font-semibold text-slate-800 text-sm mb-4">Lịch sử biến động kho (gần nhất)</h3>
            <table className="w-full data-table">
              <thead>
                <tr>
                  <th>Ngày giờ</th>
                  <th>Phụ tùng</th>
                  <th>Loại</th>
                  <th className="text-right">Trước</th>
                  <th className="text-right">Thay đổi</th>
                  <th className="text-right">Sau</th>
                  <th>Người thực hiện</th>
                  <th>Phiếu</th>
                </tr>
              </thead>
              <tbody>
                {HISTORY.map((h, i) => (
                  <tr key={i}>
                    <td className="mono text-xs text-slate-500">{h.date}</td>
                    <td className="font-medium text-slate-700">{h.part}</td>
                    <td>
                      <span className={`text-xs px-2 py-0.5 rounded font-medium ${h.type === "Nhập" ? "bg-emerald-50 text-emerald-700" : "bg-blue-50 text-blue-700"}`}>
                        {h.type}
                      </span>
                    </td>
                    <td className="text-right text-slate-600">{h.before}</td>
                    <td className="text-right">
                      <span className={`font-bold ${h.change > 0 ? "text-emerald-600" : "text-red-500"}`}>
                        {h.change > 0 ? "+" : ""}{h.change}
                      </span>
                    </td>
                    <td className="text-right font-semibold text-slate-800">{h.after}</td>
                    <td className="text-slate-600 text-sm">{h.staff}</td>
                    <td><span className="mono text-xs text-blue-600 hover:underline cursor-pointer">{h.ref}</span></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </Card>
        </>
      )}

      {tab === "import" && (
        <Card className="p-6">
          <div className="grid grid-cols-3 gap-4 mb-6">
            <Input label="Mã phiếu" defaultValue="PNK006" />
            <Input label="Ngày nhập" type="date" defaultValue="2024-09-17" />
            <Select label="Nhà cung cấp" options={[
              { value: "ncc1", label: "Công ty PT Minh Phúc" },
              { value: "ncc2", label: "Đại lý Toyota chính hãng" },
              { value: "ncc3", label: "Kho phụ tùng Thành Đô" },
            ]} />
          </div>

          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Chi tiết phiếu nhập</p>
          <table className="w-full data-table mb-4">
            <thead>
              <tr>
                <th>Mã PT</th>
                <th>Tên phụ tùng</th>
                <th className="text-right">Số lượng</th>
                <th className="text-right">Đơn giá</th>
                <th className="text-right">Thành tiền</th>
                <th></th>
              </tr>
            </thead>
            <tbody>
              {importItems.map((item, i) => (
                <tr key={i}>
                  <td className="mono text-xs text-slate-400">{item.id}</td>
                  <td className="font-medium">{item.name}</td>
                  <td className="text-right"><input type="number" defaultValue={item.qty} className="w-20 border border-[#dde3ec] rounded px-2 py-1 text-sm text-right" /></td>
                  <td className="text-right">{formatCurrency(item.price)}</td>
                  <td className="text-right font-semibold">{formatCurrency(item.qty * item.price)}</td>
                  <td><button className="p-1 text-red-400 hover:text-red-600">{Icons.xCircle}</button></td>
                </tr>
              ))}
            </tbody>
          </table>
          <Button variant="secondary" size="sm" icon={Icons.plus}>Thêm dòng</Button>

          <div className="flex justify-between items-center mt-4 pt-4 border-t border-[#dde3ec]">
            <span className="font-bold text-slate-700">Tổng cộng: <span className="text-[#1e3a6e]">{formatCurrency(importItems.reduce((s, i) => s + i.qty * i.price, 0))}</span></span>
            <div className="flex gap-2">
              <Button variant="outline" icon={Icons.printer}>In phiếu</Button>
              <Button variant="secondary">Lưu phiếu</Button>
              <Button icon={Icons.checkCircle}>Xác nhận nhập kho</Button>
            </div>
          </div>
        </Card>
      )}

      {tab === "export" && (
        <Card className="p-6">
          <div className="grid grid-cols-3 gap-4 mb-6">
            <Input label="Mã phiếu" defaultValue="PXK008" />
            <Select label="Phiếu sửa chữa" options={[
              { value: "PSC001", label: "PSC001 – 51G-123.45" },
              { value: "PSC002", label: "PSC002 – 51B-789.01" },
            ]} />
            <Select label="Kỹ thuật viên" options={[
              { value: "NV002", label: "Trần Văn Khoa" },
              { value: "NV003", label: "Nguyễn Thành Long" },
            ]} />
          </div>

          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Phụ tùng xuất kho</p>
          <table className="w-full data-table mb-4">
            <thead>
              <tr>
                <th>Tên phụ tùng</th>
                <th className="text-right">Tồn kho</th>
                <th className="text-right">Yêu cầu</th>
                <th className="text-right">Xuất thực tế</th>
                <th>Tình trạng</th>
              </tr>
            </thead>
            <tbody>
              {exportItems.map((item, i) => {
                const reqQty = i === 0 ? 4 : i === 1 ? 3 : 1;
                const over = reqQty > item.stock;
                return (
                  <tr key={item.id}>
                    <td className="font-medium">{item.name}</td>
                    <td className="text-right">{item.stock}</td>
                    <td className="text-right">{reqQty}</td>
                    <td className="text-right">
                      <input type="number" defaultValue={over ? item.stock : reqQty}
                        className={`w-20 border rounded px-2 py-1 text-sm text-right ${over ? "border-red-400 bg-red-50" : "border-[#dde3ec]"}`} />
                    </td>
                    <td>
                      {over ? (
                        <span className="text-xs text-red-600 flex items-center gap-1">{Icons.alertTriangle} Không đủ hàng</span>
                      ) : (
                        <span className="text-xs text-emerald-600 flex items-center gap-1">{Icons.checkCircle} Đủ hàng</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>

          <div className="flex justify-end gap-2 mt-4">
            <Button variant="outline">Lưu phiếu</Button>
            <Button icon={Icons.checkCircle}>Xác nhận xuất kho</Button>
          </div>
        </Card>
      )}

      {tab === "audit" && (
        <Card>
          <div className="flex items-center justify-between p-4 border-b border-[#dde3ec]">
            <p className="text-sm font-semibold text-slate-700">Kiểm kê ngày 17/09/2024</p>
            <Button size="sm">Lưu kết quả kiểm kê</Button>
          </div>
          <table className="w-full data-table">
            <thead>
              <tr>
                <th>Mã PT</th>
                <th>Tên phụ tùng</th>
                <th className="text-right">Tồn hệ thống</th>
                <th className="text-right">Tồn thực tế</th>
                <th className="text-right">Chênh lệch</th>
                <th>Kết quả</th>
                <th>Ghi chú</th>
              </tr>
            </thead>
            <tbody>
              {auditItems.map(item => (
                <tr key={item.id}>
                  <td className="mono text-xs text-slate-400">{item.id}</td>
                  <td className="font-medium text-slate-700">{item.name}</td>
                  <td className="text-right">{item.stock}</td>
                  <td className="text-right">
                    <input type="number" defaultValue={item.actual} className="w-20 border border-[#dde3ec] rounded px-2 py-1 text-sm text-right" />
                  </td>
                  <td className="text-right">
                    <span className={`font-bold ${item.diff === 0 ? "text-emerald-600" : item.diff > 0 ? "text-orange-600" : "text-red-600"}`}>
                      {item.diff > 0 ? "+" : ""}{item.diff}
                    </span>
                  </td>
                  <td>
                    {item.diff === 0
                      ? <span className="text-xs px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 font-medium">Khớp</span>
                      : item.diff > 0
                        ? <span className="text-xs px-2 py-0.5 rounded bg-orange-50 text-orange-700 font-medium">Thừa</span>
                        : <span className="text-xs px-2 py-0.5 rounded bg-red-50 text-red-600 font-medium">Thiếu</span>
                    }
                  </td>
                  <td><input className="border border-[#dde3ec] rounded px-2 py-1 text-xs w-24" placeholder="Ghi chú..." /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      )}
    </div>
  );
}
