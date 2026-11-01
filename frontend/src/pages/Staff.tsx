import React, { useCallback, useEffect, useState } from "react";
import { Card, Button, Badge, Modal, Input, Icons } from "../components/ui";
import { employeesApi, type Employee, type EmployeeInput } from "../api/employees";
import { errorMessage } from "../api/client";
import type { BackendRole } from "../api/types";

const ROLE_LABELS: Record<BackendRole, string> = {
  ADMIN: "Quản trị viên", MANAGER: "Quản lý", RECEPTIONIST: "Cố vấn dịch vụ",
  TECHNICIAN: "Kỹ thuật viên", WAREHOUSE: "Nhân viên kho", CUSTOMER: "Khách hàng",
};
const empty: EmployeeInput = { fullName: "", phone: "", email: "", position: "", technician: false };

export default function Staff() {
  const [staff, setStaff] = useState<Employee[]>([]);
  const [selected, setSelected] = useState<number | null>(null);
  const [editing, setEditing] = useState<number | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [input, setInput] = useState<EmployeeInput>(empty);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [formError, setFormError] = useState("");
  const [notice, setNotice] = useState("");
  const [search, setSearch] = useState("");
  const load = useCallback(async () => {
    setLoading(true); setError("");
    try { setStaff(await employeesApi.list()); }
    catch (e) { setError(errorMessage(e)); }
    finally { setLoading(false); }
  }, []);
  useEffect(() => { void load(); }, [load]);
  const detail = staff.find(s => s.id === selected);
  const filtered = staff.filter(s => `${s.fullName} ${s.phone ?? ""} ${s.position}`.toLocaleLowerCase("vi").includes(search.toLocaleLowerCase("vi")));
  function open(employee?: Employee) {
    setEditing(employee?.id ?? null);
    setInput(employee ? { fullName: employee.fullName, phone: employee.phone ?? "", email: employee.email ?? "", position: employee.position, technician: employee.technician } : empty);
    setFormError(""); setNotice(""); setShowForm(true);
  }
  async function save(event: React.FormEvent) {
    event.preventDefault(); if (saving) return;
    setSaving(true); setFormError("");
    try {
      const result = editing === null ? await employeesApi.create(input) : await employeesApi.update(editing, input);
      const saved = await employeesApi.get(result.id);
      setStaff(await employeesApi.list()); setSelected(saved.id); setShowForm(false);
      setNotice(editing === null ? "Đã thêm nhân viên." : "Đã cập nhật nhân viên.");
    } catch (e) { setFormError(errorMessage(e)); }
    finally { setSaving(false); }
  }
  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <h2 className="font-semibold text-slate-700">Danh sách nhân viên ({staff.length})</h2>
        <Button icon={Icons.plus} onClick={() => open()}>Thêm nhân viên</Button>
      </div>
      {error && <div role="alert" className="rounded-lg bg-red-50 p-3 text-red-700">{error}<Button variant="outline" onClick={() => void load()}>Thử lại</Button></div>}
      {notice && <p role="status" className="text-green-700">{notice}</p>}
      <Input label="Tìm nhân viên" placeholder="Họ tên, số điện thoại, chức vụ" value={search} onChange={e => setSearch(e.target.value)} />
      {loading ? <p role="status">Đang tải nhân viên…</p> : !error && filtered.length === 0 ? <p>Không tìm thấy nhân viên.</p> : (
        <div className={`grid gap-4 ${detail ? "xl:grid-cols-3" : "grid-cols-1"}`}>
          <div className={detail ? "xl:col-span-2" : ""}>
            <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-3">
              {filtered.map(s => (
                <button key={s.id} type="button" onClick={() => setSelected(s.id === selected ? null : s.id)} aria-pressed={selected === s.id}
                  className={`w-full rounded-lg border bg-white p-4 text-left transition-all hover:border-primary sm:p-5 ${selected === s.id ? "border-primary ring-1 ring-primary" : "border-border"}`}>
                  <div className="flex items-start gap-3 mb-3">
                    <div className="w-10 h-10 rounded-lg bg-blue-600 flex items-center justify-center text-white font-bold flex-shrink-0">{s.fullName.charAt(0)}</div>
                    <div><p className="font-semibold text-slate-800">{s.fullName}</p><p className="text-xs mono text-slate-400">NV{s.id}</p></div>
                  </div>
                  <div className="flex flex-wrap items-center gap-2 justify-between">
                    <span className="rounded-full bg-primary-soft px-2 py-1 text-xs font-medium text-primary">{s.position}</span>
                    {s.technician && <Badge variant="completed" label="Kỹ thuật viên" />}
                  </div>
                  <div className="mt-3 text-xs text-slate-500 mono">{s.phone || "Chưa có số điện thoại"}</div>
                </button>
              ))}
            </div>
          </div>
          {detail && (
            <Card className="p-4 sm:p-5">
              <div className="flex items-start justify-between mb-4">
                <div><h3 className="font-bold text-slate-800">{detail.fullName}</h3><p className="text-xs text-slate-500">{detail.position}</p></div>
                <button aria-label="Đóng thông tin nhân viên" onClick={() => setSelected(null)} className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100">{Icons.close}</button>
              </div>
              <div className="space-y-2 text-sm mb-5">
                <p>{detail.phone || "Chưa có số điện thoại"}</p><p>{detail.email || "Chưa có email"}</p>
                <p>{detail.technician ? "Đã khai báo kỹ thuật viên" : "Nhân viên"}</p>
              </div>
              <div className="space-y-2 text-sm mb-5">
                <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Tài khoản hệ thống</p>
                <p>{detail.username || "Chưa có tài khoản"}</p>
                {detail.accountRole && <p>Vai trò: {ROLE_LABELS[detail.accountRole]}</p>}
                {detail.accountActive !== null && <Badge variant={detail.accountActive ? "completed" : "cancelled"} label={detail.accountActive ? "Tài khoản đang hoạt động" : "Tài khoản đã khóa"} />}
                <p className="text-xs text-slate-500">Quản trị viên quản lý tài khoản, mật khẩu và phân quyền tại màn Quản trị tài khoản.</p>
              </div>
              <Button variant="outline" size="sm" icon={Icons.edit} onClick={() => open(detail)}>Chỉnh sửa</Button>
            </Card>
          )}
        </div>
      )}
      <Modal open={showForm} onClose={() => { if (!saving) setShowForm(false); }} title={editing === null ? "Thêm nhân viên mới" : "Chỉnh sửa nhân viên"}>
        <form className="space-y-4" onSubmit={save}>
          {formError && <p role="alert" className="text-red-700">{formError}</p>}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input label="Họ và tên *" required maxLength={100} value={input.fullName} onChange={e => setInput({ ...input, fullName: e.target.value })} />
            <Input label="Số điện thoại" maxLength={20} value={input.phone} onChange={e => setInput({ ...input, phone: e.target.value })} />
          </div>
          <Input label="Email" type="email" maxLength={150} value={input.email} onChange={e => setInput({ ...input, email: e.target.value })} />
          <Input label="Chức vụ *" required maxLength={100} value={input.position} onChange={e => setInput({ ...input, position: e.target.value })} />
          <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={input.technician} onChange={e => setInput({ ...input, technician: e.target.checked })} />Khai báo kỹ thuật viên</label>
          <div className="flex gap-3 pt-2 justify-end">
            <Button type="button" variant="outline" disabled={saving} onClick={() => setShowForm(false)}>Hủy</Button>
            <Button type="submit" disabled={saving}>{saving ? "Đang lưu…" : "Lưu nhân viên"}</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
