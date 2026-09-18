import React, { useState } from "react";
import { Card, Button, Badge, Input, Select, Modal, Tabs, SearchBox, Pagination, StatCard, EmptyState, TimelineItem, Icons } from "../components/ui";

export default function DesignSystem() {
  const [modalOpen, setModalOpen] = useState(false);
  const [activeTab, setActiveTab] = useState("buttons");
  const [page, setPage] = useState(1);
  const [search, setSearch] = useState("");

  return (
    <div className="p-6 space-y-8 max-w-5xl">
      <div>
        <h2 className="text-2xl font-black text-slate-800 mb-1">Design System</h2>
        <p className="text-slate-500 text-sm">Thư viện component dùng chung cho hệ thống Gara Ô Tô Thành Công</p>
      </div>

      {/* Buttons */}
      <section>
        <h3 className="font-semibold text-slate-700 mb-4 pb-2 border-b border-[#dde3ec]">Buttons</h3>
        <div className="space-y-4">
          <div className="flex flex-wrap gap-3 items-center">
            <Button variant="primary">Primary</Button>
            <Button variant="secondary">Secondary</Button>
            <Button variant="outline">Outline</Button>
            <Button variant="ghost">Ghost</Button>
            <Button variant="danger">Danger</Button>
            <Button variant="accent">Accent</Button>
          </div>
          <div className="flex flex-wrap gap-3 items-center">
            <Button size="sm">Nhỏ</Button>
            <Button size="md">Vừa</Button>
            <Button size="lg">Lớn</Button>
            <Button icon={Icons.plus}>Có Icon</Button>
            <Button icon={Icons.printer} variant="outline">In phiếu</Button>
            <Button icon={Icons.send} variant="secondary">Gửi</Button>
          </div>
        </div>
      </section>

      {/* Badges */}
      <section>
        <h3 className="font-semibold text-slate-700 mb-4 pb-2 border-b border-[#dde3ec]">Status Badges</h3>
        <div className="flex flex-wrap gap-3">
          <Badge variant="pending" />
          <Badge variant="confirmed" />
          <Badge variant="arrived" />
          <Badge variant="completed" />
          <Badge variant="cancelled" />
          <Badge variant="in_progress" />
          <Badge variant="waiting_parts" />
          <Badge variant="draft" />
          <Badge variant="rejected" />
          <Badge variant="paid" />
          <Badge variant="unpaid" />
          <Badge variant="ok" />
          <Badge variant="low" />
          <Badge variant="out" />
        </div>
      </section>

      {/* Inputs */}
      <section>
        <h3 className="font-semibold text-slate-700 mb-4 pb-2 border-b border-[#dde3ec]">Form Controls</h3>
        <div className="grid grid-cols-3 gap-4">
          <Input label="Input thường" placeholder="Nhập nội dung..." />
          <Input label="Có icon" placeholder="Tìm kiếm..." icon={Icons.search} />
          <Input label="Có lỗi" placeholder="Nhập số điện thoại" error="Số điện thoại không hợp lệ" />
          <Select label="Select box" options={[
            { value: "", label: "-- Chọn --" },
            { value: "1", label: "Tùy chọn 1" },
            { value: "2", label: "Tùy chọn 2" },
          ]} />
          <SearchBox value={search} onChange={setSearch} placeholder="Tìm kiếm..." />
          <div className="flex items-end"><Input label="Ngày" type="date" /></div>
        </div>
      </section>

      {/* Tabs */}
      <section>
        <h3 className="font-semibold text-slate-700 mb-4 pb-2 border-b border-[#dde3ec]">Tabs</h3>
        <Tabs
          tabs={[
            { key: "buttons", label: "Buttons" },
            { key: "forms", label: "Forms", count: 3 },
            { key: "data", label: "Data Display" },
            { key: "feedback", label: "Feedback" },
          ]}
          active={activeTab}
          onChange={setActiveTab}
        />
      </section>

      {/* Stat Cards */}
      <section>
        <h3 className="font-semibold text-slate-700 mb-4 pb-2 border-b border-[#dde3ec]">Statistic Cards</h3>
        <div className="grid grid-cols-4 gap-4">
          <StatCard label="Xe tiếp nhận" value="4" icon={Icons.truck} color="navy" trend="+1 hôm qua" trendUp />
          <StatCard label="Đang sửa chữa" value="3" icon={Icons.wrench} color="blue" />
          <StatCard label="Doanh thu" value="3.5M" icon={Icons.creditCard} color="green" trend="+12%" trendUp />
          <StatCard label="Phụ tùng hết" value="1" icon={Icons.alertTriangle} color="red" trend="-1 so hôm qua" trendUp={false} />
        </div>
      </section>

      {/* Table */}
      <section>
        <h3 className="font-semibold text-slate-700 mb-4 pb-2 border-b border-[#dde3ec]">Table</h3>
        <Card>
          <table className="w-full data-table">
            <thead>
              <tr>
                <th>Mã</th>
                <th>Tên</th>
                <th>Vai trò</th>
                <th>Trạng thái</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {[
                { id: "NV001", name: "Nguyễn Hữu Bảo", role: "Quản lý", status: "completed" as const },
                { id: "NV002", name: "Trần Văn Khoa", role: "Kỹ thuật viên", status: "confirmed" as const },
                { id: "NV003", name: "Lê Quang Hưng", role: "Kỹ thuật viên", status: "confirmed" as const },
              ].map(row => (
                <tr key={row.id}>
                  <td><span className="mono text-xs text-slate-400">{row.id}</span></td>
                  <td className="font-medium">{row.name}</td>
                  <td className="text-slate-600">{row.role}</td>
                  <td><Badge variant={row.status} label={row.status === "completed" ? "Đang làm" : "Hoạt động"} /></td>
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
      </section>

      {/* Pagination */}
      <section>
        <h3 className="font-semibold text-slate-700 mb-4 pb-2 border-b border-[#dde3ec]">Pagination</h3>
        <Pagination page={page} total={50} perPage={8} onChange={setPage} />
      </section>

      {/* Timeline */}
      <section>
        <h3 className="font-semibold text-slate-700 mb-4 pb-2 border-b border-[#dde3ec]">Timeline</h3>
        <div className="max-w-sm relative">
          <div className="absolute left-[17px] top-9 w-0.5 bg-slate-200" style={{ height: "calc(100% - 2.5rem)" }} />
          <TimelineItem label="Tiếp nhận xe" time="15/09 08:05" note="Nhân viên: Phạm Minh Tuấn" done />
          <TimelineItem label="Báo giá đã xác nhận" time="15/09 11:30" done />
          <TimelineItem label="Đang sửa chữa" time="15/09 14:00" note="KTV: Trần Văn Khoa đang thực hiện" done={false} active />
          <TimelineItem label="Hoàn tất" done={false} />
          <TimelineItem label="Bàn giao xe" done={false} />
        </div>
      </section>

      {/* Color palette */}
      <section>
        <h3 className="font-semibold text-slate-700 mb-4 pb-2 border-b border-[#dde3ec]">Color Palette</h3>
        <div className="grid grid-cols-8 gap-3">
          {[
            { name: "Primary Navy", hex: "#1e3a6e" },
            { name: "Primary Light", hex: "#3b6fd4" },
            { name: "Secondary", hex: "#e8eef7" },
            { name: "Accent Amber", hex: "#f59e0b" },
            { name: "Success", hex: "#10b981" },
            { name: "Warning", hex: "#f97316" },
            { name: "Danger", hex: "#ef4444" },
            { name: "Muted", hex: "#64748b" },
          ].map(c => (
            <div key={c.name} className="text-center">
              <div className="w-full h-12 rounded-xl border border-[#dde3ec] mb-1.5" style={{ background: c.hex }} />
              <p className="text-[10px] font-medium text-slate-600 leading-tight">{c.name}</p>
              <p className="text-[9px] mono text-slate-400">{c.hex}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Empty + Modal */}
      <section>
        <h3 className="font-semibold text-slate-700 mb-4 pb-2 border-b border-[#dde3ec]">Feedback States</h3>
        <div className="grid grid-cols-2 gap-4">
          <Card><EmptyState message="Không có dữ liệu để hiển thị" /></Card>
          <Card className="p-5">
            <Button onClick={() => setModalOpen(true)}>Mở Modal</Button>
            <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="Modal xác nhận">
              <p className="text-sm text-slate-600 mb-4">Đây là modal xác nhận hành động. Bạn có chắc chắn muốn tiếp tục?</p>
              <div className="flex gap-3 justify-end">
                <Button variant="outline" onClick={() => setModalOpen(false)}>Hủy</Button>
                <Button onClick={() => setModalOpen(false)}>Xác nhận</Button>
              </div>
            </Modal>
          </Card>
        </div>
      </section>
    </div>
  );
}
