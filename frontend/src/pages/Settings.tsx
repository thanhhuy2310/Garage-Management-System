import React, { useState } from "react";
import { Badge, Button, Card, Input, Modal, Select, Tabs, Icons } from "../components/ui";
import { ROLES } from "../data";
import { nhanVien, taiKhoan } from "../mock/schemaData";

const ROLE_PERMISSIONS: Record<string, string[]> = {
  admin: ["Quản lý tài khoản", "Phân quyền tài khoản"],
  manager: ["Quản lý gara", "Duyệt báo giá", "Xem báo cáo", "Quản lý nhân viên"],
  receptionist: ["Quản lý lịch hẹn", "Tiếp nhận xe", "Lập hóa đơn", "Ghi nhận thanh toán"],
  technician: ["Xem phân công", "Cập nhật sửa chữa", "Yêu cầu và xác nhận phụ tùng"],
  warehouse: ["Nhập kho", "Lập phiếu xuất", "Kiểm kê", "Xem biến động kho"],
  customer: ["Đặt lịch", "Xem báo giá", "Xác nhận báo giá", "Xem thông báo"],
};
const ROLE_COLORS: Record<string, string> = { admin: "bg-purple-100 text-purple-700", manager: "bg-blue-100 text-blue-700", receptionist: "bg-emerald-100 text-emerald-700", technician: "bg-orange-100 text-orange-700", warehouse: "bg-amber-100 text-amber-700", customer: "bg-slate-100 text-slate-700" };

export default function Settings() {
  const [tab, setTab] = useState("roles");
  const [role, setRole] = useState("manager");
  const [showAdd, setShowAdd] = useState(false);
  return <div className="p-6 space-y-5">
    <Tabs tabs={[{ key: "roles", label: "Vai trò & quyền" }, { key: "accounts", label: "Tài khoản" }]} active={tab} onChange={setTab} />
    {tab === "roles" && <div className="grid grid-cols-4 gap-4"><div className="space-y-2">{Object.entries(ROLES).map(([key, label]) => <button key={key} onClick={() => setRole(key)} className={`w-full p-3 rounded-xl border text-left ${role === key ? "border-[#1e3a6e] bg-[#e8eef7]" : "bg-white border-[#dde3ec]"}`}><span className={`text-xs px-2 py-1 rounded-lg ${ROLE_COLORS[key]}`}>{label}</span><span className="text-xs text-slate-500 ml-2">{taiKhoan.filter((x) => x.VaiTro === key).length}</span></button>)}</div><Card className="col-span-3 p-5"><div className="flex justify-between mb-5"><div><h3 className="font-semibold">{ROLES[role]}</h3><p className="text-xs text-slate-500">Vai trò được lưu tại TaiKhoan.VaiTro.</p></div><Button size="sm" variant="secondary" icon={Icons.edit}>Chỉnh sửa quyền</Button></div><div className="space-y-2">{(ROLE_PERMISSIONS[role] ?? []).map((permission) => <div key={permission} className="flex items-center gap-2 p-3 bg-slate-50 rounded-lg"><span className="text-emerald-600">{Icons.checkCircle}</span><span className="text-sm">{permission}</span></div>)}</div></Card></div>}
    {tab === "accounts" && <div className="space-y-4"><div className="flex justify-between"><p className="text-sm text-slate-600">{taiKhoan.length} tài khoản</p><Button icon={Icons.plus} onClick={() => setShowAdd(true)}>Tạo tài khoản</Button></div><Card><table className="w-full data-table"><thead><tr><th>Mã tài khoản</th><th>Tên đăng nhập</th><th>Chủ tài khoản</th><th>Liên kết</th><th>Vai trò</th><th>Trạng thái</th><th>Thao tác</th></tr></thead><tbody>{taiKhoan.map((account) => { const employee = nhanVien.find((x) => x.MaNhanVien === account.MaNhanVien); return <tr key={account.MaTaiKhoan}><td className="mono text-xs">{account.MaTaiKhoan}</td><td className="mono">{account.TenDangNhap}</td><td>{employee?.HoTen ?? (account.MaKhachHang ? `Khách hàng ${account.MaKhachHang}` : "—")}</td><td className="mono text-xs">{account.MaNhanVien ?? account.MaKhachHang ?? "—"}</td><td><span className={`text-xs px-2 py-1 rounded-full ${ROLE_COLORS[account.VaiTro]}`}>{ROLES[account.VaiTro]}</span></td><td><Badge variant={account.TrangThai ? "completed" : "cancelled"} label={account.TrangThai ? "Hoạt động" : "Đã khóa"} /></td><td><Button size="sm" variant="outline">{account.TrangThai ? "Khóa" : "Mở khóa"}</Button></td></tr>; })}</tbody></table></Card></div>}
    <Modal open={showAdd} onClose={() => setShowAdd(false)} title="Tạo tài khoản"><div className="space-y-4"><Input label="Tên đăng nhập *" /><Input label="Mật khẩu *" type="password" /><Select label="Vai trò *" options={Object.entries(ROLES).map(([value, label]) => ({ value, label }))} /><Select label="Nhân viên liên kết" options={[{ value: "", label: "Không liên kết nhân viên" }, ...nhanVien.map((x) => ({ value: x.MaNhanVien, label: `${x.MaNhanVien} · ${x.HoTen}` }))]} /><Input label="Mã khách hàng (nếu là khách hàng)" /><p className="text-xs text-slate-500">Mỗi tài khoản chỉ được liên kết với một khách hàng hoặc một nhân viên theo ràng buộc CK_TaiKhoan_DoiTuong.</p><div className="flex justify-end gap-2"><Button variant="outline" onClick={() => setShowAdd(false)}>Hủy</Button><Button onClick={() => setShowAdd(false)}>Tạo tài khoản</Button></div></div></Modal>
  </div>;
}
