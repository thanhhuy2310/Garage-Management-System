import React, { useState } from "react";
import { Card, Button, Badge, Modal, Input, Select, Icons } from "../components/ui";
import { mockStaff, ROLES } from "../data";

const PERMISSIONS: Record<string, string[]> = {
  admin: ["Tất cả quyền", "Quản lý tài khoản", "Xem báo cáo tài chính", "Cài đặt hệ thống"],
  manager: ["Xem tổng quan", "Quản lý lịch hẹn", "Quản lý phiếu SC", "Duyệt báo giá", "Xem báo cáo", "Quản lý nhân viên"],
  technician: ["Xem công việc", "Cập nhật tiến độ", "Yêu cầu phụ tùng", "Ghi kết quả kiểm tra"],
  receptionist: ["Tiếp nhận xe", "Lập phiếu tiếp nhận", "Quản lý lịch hẹn", "Quản lý khách hàng", "Lập hóa đơn"],
  warehouse: ["Nhập kho", "Xuất kho", "Kiểm kê", "Xem tồn kho"],
};

export default function Staff() {
  const [showAdd, setShowAdd] = useState(false);
  const [selected, setSelected] = useState<string | null>(mockStaff[0]?.id ?? null);

  const detail = mockStaff.find(s => s.id === selected);

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h2 className="font-semibold text-slate-700">Danh sách nhân viên ({mockStaff.length})</h2>
        <Button icon={Icons.plus} onClick={() => setShowAdd(true)}>Thêm nhân viên</Button>
      </div>

      <div className={`grid gap-4 ${selected ? "xl:grid-cols-3" : "grid-cols-1"}`}>
        <div className={selected ? "xl:col-span-2" : ""}>
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-3">
            {mockStaff.map(s => (
              <button key={s.id} type="button" onClick={() => setSelected(s.id === selected ? null : s.id)} aria-pressed={selected === s.id}
                className={`w-full rounded-lg border bg-white p-4 text-left transition-all hover:border-primary sm:p-5 ${selected === s.id ? "border-primary ring-1 ring-primary" : "border-border"}`}>
                <div className="flex items-start gap-3 mb-3">
                  <div className="w-10 h-10 rounded-lg bg-blue-600 flex items-center justify-center text-white font-bold flex-shrink-0">
                    {s.name.charAt(0)}
                  </div>
                  <div>
                    <p className="font-semibold text-slate-800">{s.name}</p>
                    <p className="text-xs mono text-slate-400">{s.id}</p>
                  </div>
                </div>
                <div className="flex items-center justify-between">
                  <span className="rounded-full bg-primary-soft px-2 py-1 text-xs font-medium text-primary">{ROLES[s.role]}</span>
                  <Badge variant={s.status === "active" ? "completed" : "cancelled"} label={s.status === "active" ? "Đang làm" : "Nghỉ việc"} />
                </div>
                <div className="mt-3 text-xs text-slate-500 mono">{s.phone}</div>
              </button>
            ))}
          </div>
        </div>

        {/* Detail / Permissions panel */}
        {detail && (
          <Card className="p-4 sm:p-5">
            <div className="flex items-start justify-between mb-4">
              <div className="flex items-center gap-3">
                <div className="w-12 h-12 rounded-lg bg-blue-600 flex items-center justify-center text-white font-bold text-lg">
                  {detail.name.charAt(0)}
                </div>
                <div>
                  <h3 className="font-bold text-slate-800">{detail.name}</h3>
                  <p className="text-xs text-slate-500">{ROLES[detail.role]}</p>
                </div>
              </div>
              <button aria-label="Đóng thông tin nhân viên" onClick={() => setSelected(null)} className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100">{Icons.close}</button>
            </div>

            <div className="space-y-2 text-sm mb-5">
              <div className="flex items-center gap-2 text-slate-600">
                <span className="text-slate-400 w-4">{Icons.users}</span>
                <span className="mono">{detail.phone}</span>
              </div>
              <div className="flex items-center gap-2 text-slate-600">
                <span className="text-slate-400 w-4">{Icons.send}</span>
                <span>{detail.email}</span>
              </div>
              <div className="flex items-center gap-2 text-slate-600">
                <span className="text-slate-400 w-4">{Icons.calendar}</span>
                <span>{detail.title}</span>
              </div>
            </div>

            <div className="mb-5">
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Phân quyền</p>
              <div className="space-y-2">
                {(PERMISSIONS[detail.role] || []).map(p => (
                  <div key={p} className="flex items-center gap-2 text-sm">
                    <span className="text-success">{Icons.checkCircle}</span>
                    <span className="text-slate-700">{p}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="flex gap-2">
              <Button variant="outline" size="sm" className="flex-1" icon={Icons.edit}>Chỉnh sửa</Button>
              <Button variant="secondary" size="sm" className="flex-1">Đổi mật khẩu</Button>
            </div>
          </Card>
        )}
      </div>

      <Modal open={showAdd} onClose={() => setShowAdd(false)} title="Thêm nhân viên mới">
        <div className="space-y-4">
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input label="Họ và tên *" placeholder="Nguyễn Văn A" />
            <Input label="Số điện thoại *" placeholder="0901234567" />
          </div>
          <Input label="Email" placeholder="email@garage.vn" type="email" />
          <Input label="Chức vụ *" placeholder="Ví dụ: Nhân viên kho" />
          <Select label="Vai trò *" options={Object.entries(ROLES).map(([k, v]) => ({ value: k, label: v }))} />
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input label="Tên đăng nhập *" placeholder="username" />
            <Input label="Mật khẩu *" type="password" placeholder="••••••••" />
          </div>
          <div className="flex gap-3 pt-2 justify-end">
            <Button variant="outline" onClick={() => setShowAdd(false)}>Hủy</Button>
            <Button>Tạo tài khoản</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
