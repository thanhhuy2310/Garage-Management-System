import React, { useState } from "react";
import { Card, Badge, Button, Tabs, Modal, Input, Select, Icons } from "../components/ui";
import { mockStaff, ROLES } from "../data";

const ROLE_PERMISSIONS: Record<string, { group: string; items: { key: string; label: string; read: boolean; write: boolean }[] }[]> = {
  admin: [
    {
      group: "Hệ thống",
      items: [
        { key: "sys_settings", label: "Cài đặt hệ thống", read: true, write: true },
        { key: "sys_accounts", label: "Quản lý tài khoản", read: true, write: true },
        { key: "sys_roles", label: "Phân quyền", read: true, write: true },
        { key: "sys_audit", label: "Nhật ký hệ thống", read: true, write: false },
      ],
    },
    {
      group: "Nghiệp vụ",
      items: [
        { key: "biz_all", label: "Tất cả nghiệp vụ", read: true, write: true },
        { key: "biz_reports", label: "Báo cáo tài chính", read: true, write: false },
      ],
    },
  ],
  manager: [
    {
      group: "Quản lý gara",
      items: [
        { key: "mgr_dashboard", label: "Xem tổng quan", read: true, write: false },
        { key: "mgr_appt", label: "Quản lý lịch hẹn", read: true, write: true },
        { key: "mgr_repair", label: "Quản lý phiếu sửa chữa", read: true, write: true },
        { key: "mgr_quote", label: "Duyệt báo giá", read: true, write: true },
        { key: "mgr_staff", label: "Quản lý nhân viên", read: true, write: true },
        { key: "mgr_report", label: "Báo cáo thống kê", read: true, write: false },
        { key: "mgr_invoice", label: "Xem hóa đơn", read: true, write: false },
      ],
    },
    {
      group: "Kho",
      items: [
        { key: "mgr_inv_view", label: "Xem tồn kho", read: true, write: false },
        { key: "mgr_inv_edit", label: "Nhập/Xuất kho", read: false, write: false },
      ],
    },
  ],
  receptionist: [
    {
      group: "Tiếp nhận",
      items: [
        { key: "rec_receive", label: "Tiếp nhận xe", read: true, write: true },
        { key: "rec_appt", label: "Quản lý lịch hẹn", read: true, write: true },
        { key: "rec_customer", label: "Quản lý khách hàng", read: true, write: true },
        { key: "rec_vehicle", label: "Quản lý xe", read: true, write: true },
        { key: "rec_invoice", label: "Lập hóa đơn", read: true, write: true },
        { key: "rec_payment", label: "Xử lý thanh toán", read: true, write: true },
      ],
    },
  ],
  technician: [
    {
      group: "Kỹ thuật",
      items: [
        { key: "ktv_work", label: "Xem công việc", read: true, write: false },
        { key: "ktv_progress", label: "Cập nhật tiến độ", read: true, write: true },
        { key: "ktv_parts", label: "Yêu cầu phụ tùng", read: true, write: true },
        { key: "ktv_inspect", label: "Ghi kết quả kiểm tra", read: true, write: true },
        { key: "ktv_history", label: "Xem lịch sử xe", read: true, write: false },
      ],
    },
  ],
  warehouse: [
    {
      group: "Kho hàng",
      items: [
        { key: "wh_view", label: "Xem tồn kho", read: true, write: false },
        { key: "wh_import", label: "Nhập kho", read: true, write: true },
        { key: "wh_export", label: "Xuất kho", read: true, write: true },
        { key: "wh_audit", label: "Kiểm kê kho", read: true, write: true },
        { key: "wh_history", label: "Lịch sử biến động", read: true, write: false },
      ],
    },
  ],
  cashier: [
    {
      group: "Thanh toán",
      items: [
        { key: "cas_invoice", label: "Xem hóa đơn", read: true, write: false },
        { key: "cas_pay", label: "Xử lý thanh toán", read: true, write: true },
        { key: "cas_print", label: "In hóa đơn", read: true, write: false },
        { key: "cas_report", label: "Báo cáo thu ngân", read: true, write: false },
      ],
    },
  ],
};

const ROLE_COLORS: Record<string, string> = {
  admin: "bg-purple-100 text-purple-700",
  manager: "bg-blue-100 text-blue-700",
  receptionist: "bg-emerald-100 text-emerald-700",
  technician: "bg-orange-100 text-orange-700",
  warehouse: "bg-amber-100 text-amber-700",
  cashier: "bg-pink-100 text-pink-700",
};

export default function Settings() {
  const [tab, setTab] = useState("roles");
  const [selectedRole, setSelectedRole] = useState("manager");
  const [showAddUser, setShowAddUser] = useState(false);

  return (
    <div className="p-6 space-y-5">
      <Tabs
        tabs={[
          { key: "roles", label: "Phân quyền vai trò" },
          { key: "accounts", label: "Tài khoản" },
          { key: "system", label: "Cài đặt hệ thống" },
        ]}
        active={tab}
        onChange={setTab}
      />

      {tab === "roles" && (
        <div className="grid grid-cols-4 gap-4">
          {/* Role list */}
          <div className="space-y-2">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Vai trò hệ thống</p>
            {Object.entries(ROLES).map(([key, label]) => (
              <button key={key} onClick={() => setSelectedRole(key)}
                className={`w-full flex items-center gap-3 p-3 rounded-xl border transition-all text-left ${selectedRole === key ? "border-[#1e3a6e] bg-[#e8eef7]" : "border-[#dde3ec] bg-white hover:border-slate-300"}`}>
                <span className={`text-xs px-2 py-1 rounded-lg font-semibold ${ROLE_COLORS[key] || "bg-slate-100 text-slate-600"}`}>{label}</span>
                <span className="text-xs text-slate-500">{mockStaff.filter(s => s.role === key).length} người</span>
                {selectedRole === key && <span className="ml-auto text-[#1e3a6e] text-sm">›</span>}
              </button>
            ))}
          </div>

          {/* Permission matrix */}
          <div className="col-span-3">
            <Card className="p-5">
              <div className="flex items-center justify-between mb-5">
                <div className="flex items-center gap-3">
                  <span className={`px-3 py-1.5 rounded-lg text-sm font-bold ${ROLE_COLORS[selectedRole] || "bg-slate-100"}`}>
                    {ROLES[selectedRole]}
                  </span>
                  <div className="flex items-center gap-3 text-sm text-slate-500">
                    <span className="flex items-center gap-1"><span className="w-3 h-3 bg-emerald-400 rounded-sm inline-block" /> Có quyền</span>
                    <span className="flex items-center gap-1"><span className="w-3 h-3 bg-slate-200 rounded-sm inline-block" /> Không có</span>
                  </div>
                </div>
                <Button size="sm" variant="secondary" icon={Icons.edit}>Chỉnh sửa quyền</Button>
              </div>

              {(ROLE_PERMISSIONS[selectedRole] || []).map(group => (
                <div key={group.group} className="mb-5">
                  <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">{group.group}</p>
                  <table className="w-full">
                    <thead>
                      <tr>
                        <th className="text-left pb-2 text-xs text-slate-500 font-medium">Chức năng</th>
                        <th className="text-center pb-2 text-xs text-slate-500 font-medium w-24">Xem</th>
                        <th className="text-center pb-2 text-xs text-slate-500 font-medium w-24">Thao tác</th>
                      </tr>
                    </thead>
                    <tbody>
                      {group.items.map(item => (
                        <tr key={item.key} className="border-b border-[#f1f5f9] last:border-0">
                          <td className="py-2.5 text-sm text-slate-700">{item.label}</td>
                          <td className="py-2.5 text-center">
                            {item.read
                              ? <span className="inline-flex items-center justify-center w-6 h-6 bg-emerald-100 text-emerald-600 rounded-md text-xs">✓</span>
                              : <span className="inline-flex items-center justify-center w-6 h-6 bg-slate-100 text-slate-300 rounded-md text-xs">–</span>
                            }
                          </td>
                          <td className="py-2.5 text-center">
                            {item.write
                              ? <span className="inline-flex items-center justify-center w-6 h-6 bg-emerald-100 text-emerald-600 rounded-md text-xs">✓</span>
                              : <span className="inline-flex items-center justify-center w-6 h-6 bg-slate-100 text-slate-300 rounded-md text-xs">–</span>
                            }
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ))}
            </Card>
          </div>
        </div>
      )}

      {tab === "accounts" && (
        <div className="space-y-4">
          <div className="flex justify-between items-center">
            <p className="text-sm text-slate-600">{mockStaff.length} tài khoản</p>
            <Button icon={Icons.plus} onClick={() => setShowAddUser(true)}>Tạo tài khoản</Button>
          </div>
          <Card>
            <table className="w-full data-table">
              <thead>
                <tr>
                  <th>Nhân viên</th>
                  <th>Tên đăng nhập</th>
                  <th>Email</th>
                  <th>Vai trò</th>
                  <th>Trạng thái</th>
                  <th>Đăng nhập cuối</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {mockStaff.map((s, i) => {
                  const lastLogins = ["17/09 08:32", "17/09 07:55", "16/09 17:20", "17/09 09:01", "16/09 08:44", "17/09 08:10", "16/09 15:30", "17/09 08:00"];
                  return (
                    <tr key={s.id}>
                      <td>
                        <div className="flex items-center gap-2">
                          <div className="w-7 h-7 bg-gradient-to-br from-blue-400 to-indigo-600 rounded-full flex items-center justify-center text-white text-xs font-bold">{s.name.charAt(0)}</div>
                          <span className="font-medium text-slate-800">{s.name}</span>
                        </div>
                      </td>
                      <td><span className="mono text-sm text-slate-600">{s.id.toLowerCase().replace("nv", "user")}</span></td>
                      <td className="text-slate-500 text-sm">{s.email}</td>
                      <td>
                        <span className={`text-xs px-2 py-1 rounded-full font-medium ${ROLE_COLORS[s.role] || "bg-slate-100 text-slate-600"}`}>
                          {ROLES[s.role]}
                        </span>
                      </td>
                      <td><Badge variant="completed" label="Đang hoạt động" /></td>
                      <td className="text-sm text-slate-500 mono">{lastLogins[i]}</td>
                      <td>
                        <div className="flex gap-1">
                          <button className="p-1.5 hover:bg-slate-100 rounded text-slate-500">{Icons.edit}</button>
                          <button className="px-2 py-1 text-xs bg-slate-100 rounded text-slate-600 hover:bg-slate-200 transition-all">Đổi mật khẩu</button>
                          <button className="px-2 py-1 text-xs bg-red-50 rounded text-red-600 hover:bg-red-100 transition-all">Khóa</button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </Card>
        </div>
      )}

      {tab === "system" && (
        <div className="grid grid-cols-2 gap-4 max-w-4xl">
          <Card className="p-5">
            <h3 className="font-semibold text-slate-800 mb-4">Thông tin gara</h3>
            <div className="space-y-4">
              <Input label="Tên gara" defaultValue="Gara Ô Tô Thành Công" />
              <Input label="Địa chỉ" defaultValue="123 Lê Văn Sỹ, Phường 13, Q.3, TP.HCM" />
              <div className="grid grid-cols-2 gap-3">
                <Input label="Điện thoại" defaultValue="028 3456 7890" />
                <Input label="Email" defaultValue="info@garathanhcong.vn" />
              </div>
              <Input label="Mã số thuế" defaultValue="0312345678" />
              <Button>Lưu thông tin</Button>
            </div>
          </Card>

          <Card className="p-5">
            <h3 className="font-semibold text-slate-800 mb-4">Cài đặt thông báo</h3>
            <div className="space-y-3">
              {[
                { label: "Thông báo lịch hẹn mới", enabled: true },
                { label: "Thông báo khách hủy lịch", enabled: true },
                { label: "Thông báo phụ tùng sắp hết", enabled: true },
                { label: "Nhắc lịch bảo dưỡng cho khách", enabled: true },
                { label: "Thông báo thanh toán", enabled: true },
                { label: "Báo cáo cuối ngày (email)", enabled: false },
              ].map(setting => (
                <div key={setting.label} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                  <span className="text-sm text-slate-700">{setting.label}</span>
                  <div className={`relative w-10 h-5 rounded-full transition-all cursor-pointer ${setting.enabled ? "bg-[#1e3a6e]" : "bg-slate-300"}`}>
                    <div className={`absolute top-0.5 w-4 h-4 bg-white rounded-full shadow transition-all ${setting.enabled ? "left-5" : "left-0.5"}`} />
                  </div>
                </div>
              ))}
            </div>
          </Card>

          <Card className="p-5">
            <h3 className="font-semibold text-slate-800 mb-4">Cài đặt kho</h3>
            <div className="space-y-4">
              <Input label="Ngưỡng cảnh báo tồn kho (%)" defaultValue="30" type="number" />
              <Input label="Email nhận cảnh báo kho" defaultValue="kho@garathanhcong.vn" />
              <div>
                <label className="text-xs font-medium text-slate-600 block mb-1">Tần suất kiểm kê</label>
                <select className="w-full h-9 border border-[#dde3ec] rounded-lg px-3 text-sm">
                  <option>Hàng tuần</option>
                  <option>Hàng tháng</option>
                  <option>Hàng quý</option>
                </select>
              </div>
              <Button>Lưu cài đặt</Button>
            </div>
          </Card>

          <Card className="p-5">
            <h3 className="font-semibold text-slate-800 mb-4">Tài khoản ngân hàng</h3>
            <div className="space-y-3">
              {[
                { bank: "ACB", name: "Gara Ô Tô Thành Công", number: "1234567890" },
                { bank: "Vietcombank", name: "Nguyễn Hữu Bảo", number: "9876543210" },
              ].map(acc => (
                <div key={acc.number} className="p-3 bg-slate-50 rounded-xl flex items-center justify-between">
                  <div>
                    <p className="font-semibold text-slate-800 text-sm">{acc.bank}</p>
                    <p className="text-xs text-slate-500">{acc.name}</p>
                    <p className="font-mono text-xs text-slate-600 mt-0.5">{acc.number}</p>
                  </div>
                  <div className="flex gap-1">
                    <button className="p-1.5 hover:bg-slate-100 rounded text-slate-500">{Icons.edit}</button>
                  </div>
                </div>
              ))}
              <Button variant="secondary" size="sm" icon={Icons.plus}>Thêm tài khoản</Button>
            </div>
          </Card>
        </div>
      )}

      <Modal open={showAddUser} onClose={() => setShowAddUser(false)} title="Tạo tài khoản mới">
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <Input label="Họ và tên *" placeholder="Nguyễn Văn A" />
            <Input label="Số điện thoại" placeholder="0901234567" />
          </div>
          <Input label="Email *" type="email" placeholder="email@garage.vn" />
          <div className="grid grid-cols-2 gap-4">
            <Select label="Vai trò *" options={Object.entries(ROLES).map(([k, v]) => ({ value: k, label: v }))} />
            <Input label="Tên đăng nhập *" placeholder="user123" />
          </div>
          <div className="grid grid-cols-2 gap-4">
            <Input label="Mật khẩu *" type="password" placeholder="••••••••" />
            <Input label="Xác nhận mật khẩu *" type="password" placeholder="••••••••" />
          </div>
          <div className="flex gap-3 justify-end pt-2">
            <Button variant="outline" onClick={() => setShowAddUser(false)}>Hủy</Button>
            <Button onClick={() => setShowAddUser(false)}>Tạo tài khoản</Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
