import React, { useState } from "react";
import { Card, Badge, Button, SearchBox, Tabs, Modal, Input, Select, Textarea, Icons } from "../components/ui";
import { dichVu, khachHang, mockAppointments, xe } from "../mock/data";

const STATUS_TABS = [
  { key: "all", label: "Tất cả" },
  { key: "pending", label: "Chờ xác nhận" },
  { key: "confirmed", label: "Đã xác nhận" },
  { key: "arrived", label: "Đã đến" },
  { key: "completed", label: "Hoàn tất" },
  { key: "cancelled", label: "Đã hủy" },
];

const VIEW_TABS = [
  { key: "list", label: "Danh sách" },
  { key: "calendar", label: "Lịch" },
];

const CALENDAR_DAYS = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];

// Simple calendar grid for week 16-22 Sep 2024
const WEEK_DATES = [
  { d: 16, date: "2026-09-16" },
  { d: 17, date: "2026-09-17" },
  { d: 18, date: "2026-09-18" },
  { d: 19, date: "2026-09-19" },
  { d: 20, date: "2026-09-20" },
  { d: 21, date: "2026-09-21" },
  { d: 22, date: "2026-09-22" },
];

export default function Appointments() {
  const [view, setView] = useState("list");
  const [statusFilter, setStatusFilter] = useState("all");
  const [search, setSearch] = useState("");
  const [showAddModal, setShowAddModal] = useState(false);
  const [showConflictModal, setShowConflictModal] = useState(false);
  const [selectedCustomerId, setSelectedCustomerId] = useState("");

  const filtered = mockAppointments.filter(a => {
    const matchStatus = statusFilter === "all" || a.status === statusFilter;
    const matchSearch = !search || a.customer.toLowerCase().includes(search.toLowerCase()) || a.vehicle.includes(search);
    return matchStatus && matchSearch;
  });

  return (
    <div className="space-y-5">
      {/* Toolbar */}
      <div className="page-toolbar">
        <div className="flex w-full flex-col gap-3 sm:flex-row sm:flex-wrap sm:items-center lg:w-auto">
          <Tabs tabs={VIEW_TABS} active={view} onChange={setView} />
          <SearchBox value={search} onChange={setSearch} placeholder="Tìm khách, biển số..." />
          <Select
            options={[
              { value: "all_date", label: "Tất cả ngày" },
              { value: "today", label: "Hôm nay" },
              { value: "week", label: "Tuần này" },
            ]}
            className="w-36"
          />
        </div>
        <Button icon={Icons.plus} onClick={() => setShowAddModal(true)}>Thêm lịch hẹn</Button>
      </div>

      {/* Status tabs */}
      <div className="flex gap-2 flex-wrap">
        {STATUS_TABS.map(tab => (
          <button key={tab.key} onClick={() => setStatusFilter(tab.key)}
            className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${statusFilter === tab.key ? "border-primary bg-primary text-primary-foreground" : "border-border bg-surface text-muted-foreground hover:border-primary hover:text-primary"}`}>
            {tab.label}
            <span className={`ml-1.5 rounded-full px-1.5 py-0.5 text-xs font-bold ${statusFilter === tab.key ? "bg-white/20 text-white" : "bg-muted text-muted-foreground"}`}>
              {tab.key === "all" ? mockAppointments.length : mockAppointments.filter(a => a.status === tab.key).length}
            </span>
          </button>
        ))}
      </div>

      {view === "list" ? (
        <Card>
          <table className="w-full data-table">
            <thead>
              <tr>
                <th>Mã</th>
                <th>Khách hàng</th>
                <th>Biển số</th>
                <th>Dịch vụ</th>
                <th>Ngày</th>
                <th>Giờ</th>
                <th>Trạng thái</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(a => (
                <tr key={a.id} className="cursor-pointer">
                  <td><span className="mono text-xs text-slate-500">{a.id}</span></td>
                  <td><span className="font-medium text-slate-800">{a.customer}</span></td>
                  <td><span className="mono text-sm font-semibold text-primary">{a.vehicle}</span></td>
                  <td><span className="text-slate-600">{a.service}</span></td>
                  <td><span className="text-slate-600">{a.date.split("-").reverse().join("/")}</span></td>
                  <td><span className="mono text-sm font-semibold">{a.time}</span></td>
                  <td><Badge variant={a.status as any} /></td>
                  <td>
                    <div className="flex items-center gap-1">
                      <button aria-label={`Xem lịch hẹn ${a.id}`} className="flex h-9 w-9 items-center justify-center rounded-md text-slate-500 hover:bg-slate-100"><span>{Icons.eye}</span></button>
                      <button aria-label={`Sửa lịch hẹn ${a.id}`} className="flex h-9 w-9 items-center justify-center rounded-md text-slate-500 hover:bg-slate-100"><span>{Icons.edit}</span></button>
                      {a.status === "pending" && (
                        <button className="px-2 py-1 bg-emerald-50 text-emerald-700 rounded text-xs font-medium hover:bg-emerald-100 transition-all">Xác nhận</button>
                      )}
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      ) : (
        /* Calendar View */
        <Card className="overflow-x-auto p-5">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-3">
              <button aria-label="Tuần trước" className="flex h-9 w-9 items-center justify-center rounded-lg border text-slate-500 hover:bg-slate-50">‹</button>
              <h3 className="font-semibold text-slate-800">Tuần 16 – 22 tháng 9, 2026</h3>
              <button aria-label="Tuần sau" className="flex h-9 w-9 items-center justify-center rounded-lg border text-slate-500 hover:bg-slate-50">›</button>
            </div>
            <button className="rounded-md bg-primary-soft px-3 py-1.5 text-xs font-medium text-primary hover:bg-secondary">Hôm nay</button>
          </div>

          <div className="grid min-w-[720px] grid-cols-7 gap-2">
            {CALENDAR_DAYS.map((d, i) => (
              <div key={d}>
                <div className={`mb-2 rounded-lg py-2 text-center ${i === 1 ? "bg-primary" : ""}`}>
                  <p className={`text-xs ${i === 1 ? "text-white/70" : "text-slate-400"}`}>{d}</p>
                  <p className={`font-bold text-sm ${i === 1 ? "text-white" : "text-slate-700"}`}>{WEEK_DATES[i].d}</p>
                </div>
                <div className="space-y-1 min-h-[120px]">
                  {mockAppointments.filter(a => a.date === WEEK_DATES[i].date).map(a => (
                    <div key={a.id}
                      className={`cursor-pointer rounded-md px-2 py-1.5 text-xs transition-all hover:opacity-90 ${a.status === "confirmed" ? "bg-info-soft text-info" : a.status === "arrived" ? "bg-indigo-100 text-indigo-800" : a.status === "pending" ? "bg-warning-soft text-warning" : a.status === "cancelled" ? "bg-danger-soft text-danger line-through" : "bg-success-soft text-success"}`}>
                      <p className="font-semibold">{a.time}</p>
                      <p className="truncate">{a.customer}</p>
                    </div>
                  ))}
                </div>
              </div>
            ))}
          </div>
        </Card>
      )}

      {/* Add Appointment Modal */}
      <Modal open={showAddModal} onClose={() => setShowAddModal(false)} title="Thêm lịch hẹn mới" width="max-w-2xl">
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Select label="Khách hàng" value={selectedCustomerId} onChange={(event) => setSelectedCustomerId(event.target.value)} options={[
              { value: "", label: "-- Chọn khách hàng --" },
              ...khachHang.map((customer) => ({ value: customer.MaKhachHang, label: customer.HoTen })),
            ]} />
            <Select label="Xe" options={[
              { value: "", label: "-- Chọn xe --" },
              ...xe
                .filter((vehicle) => !selectedCustomerId || vehicle.MaKhachHang === selectedCustomerId)
                .map((vehicle) => ({ value: vehicle.MaXe, label: `${vehicle.BienSo} (${vehicle.HangXe} ${vehicle.DongXe})` })),
            ]} />
          </div>
          <Select label="Dịch vụ" options={[
            { value: "", label: "-- Chọn dịch vụ --" },
            ...dichVu.map((service) => ({ value: service.MaDichVu, label: service.TenDichVu })),
          ]} />
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input label="Ngày hẹn" type="date" />
            <Input label="Giờ hẹn" type="time" />
          </div>
          <Textarea label="Ghi chú" placeholder="Ghi chú thêm..." />
          <div className="flex items-center justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setShowAddModal(false)}>Hủy</Button>
            <Button onClick={() => { setShowAddModal(false); setShowConflictModal(true); }}>Lưu lịch hẹn</Button>
          </div>
        </div>
      </Modal>

      {/* Time Conflict Modal */}
      <Modal open={showConflictModal} onClose={() => setShowConflictModal(false)} title="Thời gian không phù hợp">
        <div className="space-y-4">
          <div className="p-4 bg-amber-50 border border-amber-200 rounded-lg flex items-start gap-3">
            <span className="text-amber-500 mt-0.5">{Icons.alertTriangle}</span>
            <div>
              <p className="font-semibold text-amber-800 text-sm">Khung giờ đã chọn không còn trống</p>
              <p className="mt-1 text-xs text-amber-700">Thứ Ba 17/09/2026 lúc 08:00 đã được đặt bởi khách hàng khác.</p>
            </div>
          </div>
          <div>
            <p className="text-sm font-medium text-slate-700 mb-3">Đề xuất thời gian thay thế:</p>
            <div className="space-y-2">
              {["10:30", "13:00", "15:30"].map(time => (
                <button key={time}
                  className="flex w-full items-center justify-between rounded-lg border border-border bg-surface-subtle p-3 text-left transition-all hover:border-primary hover:bg-primary-soft">
                  <div>
                    <p className="text-sm font-semibold text-slate-800">Thứ Ba 17/09/2026 lúc {time}</p>
                    <p className="text-xs text-slate-500">Còn trống</p>
                  </div>
                  <span className="text-xs font-medium text-primary">{Icons.chevronRight}</span>
                </button>
              ))}
            </div>
          </div>
          <div className="flex items-center justify-end gap-3 pt-2">
            <Button variant="outline" onClick={() => setShowConflictModal(false)}>Chọn lại</Button>
            <Button variant="accent">Gửi đề xuất cho khách</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
