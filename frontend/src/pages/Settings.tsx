import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import { accountsApi, type EmployeeOption, type StaffRole } from "../api/accounts";
import { errorMessage } from "../api/client";
import type { Account } from "../api/types";
import { Badge, Button, Card, Input, Modal, Select, Tabs, Icons } from "../components/ui";
import { ROLES } from "../data";

const ROLE_PERMISSIONS: Record<string, string[]> = {
  admin: ["Quản lý tài khoản", "Phân quyền tài khoản"],
  manager: ["Quản lý gara", "Duyệt báo giá", "Xem báo cáo", "Quản lý nhân viên"],
  receptionist: ["Quản lý lịch hẹn", "Tiếp nhận xe", "Lập hóa đơn", "Ghi nhận thanh toán"],
  technician: ["Xem phân công", "Cập nhật sửa chữa", "Yêu cầu và xác nhận phụ tùng"],
  warehouse: ["Nhập kho", "Lập phiếu xuất", "Kiểm kê", "Xem biến động kho"],
  customer: ["Đặt lịch", "Xem báo giá", "Xác nhận báo giá", "Xem thông báo"],
};

const ROLE_COLORS: Record<string, string> = {
  admin: "bg-primary-soft text-primary",
  manager: "bg-info-soft text-info",
  receptionist: "bg-success-soft text-success",
  technician: "bg-warning-soft text-warning",
  warehouse: "bg-warning-soft text-warning",
  customer: "bg-muted text-muted-foreground",
};

const STAFF_ROLE_OPTIONS: { value: StaffRole; label: string }[] = [
  { value: "RECEPTIONIST", label: "Nhân viên tiếp nhận" },
  { value: "TECHNICIAN", label: "Kỹ thuật viên" },
  { value: "WAREHOUSE", label: "Nhân viên kho" },
  { value: "MANAGER", label: "Quản lý" },
  { value: "ADMIN", label: "Quản trị viên" },
];

const roleKey = (role: string) => role.toLowerCase();
const roleLabel = (role: string) => ROLES[roleKey(role)] ?? role;

export default function Settings() {
  const [tab, setTab] = useState("roles");
  const [role, setRole] = useState("manager");
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [employees, setEmployees] = useState<EmployeeOption[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [showAdd, setShowAdd] = useState(false);
  const [createError, setCreateError] = useState("");
  const [saving, setSaving] = useState(false);
  const [busyAccountId, setBusyAccountId] = useState<number | null>(null);
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [staffRole, setStaffRole] = useState<StaffRole>("RECEPTIONIST");
  const [employeeId, setEmployeeId] = useState("");

  const loadAccountData = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const [accountRows, employeeRows] = await Promise.all([
        accountsApi.list(),
        accountsApi.staffOptions(),
      ]);
      setAccounts(accountRows);
      setEmployees(employeeRows);
    } catch (loadError) {
      setError(errorMessage(loadError, "Không thể tải dữ liệu tài khoản từ máy chủ."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadAccountData();
  }, [loadAccountData]);

  const availableEmployees = useMemo(
    () => employees.filter((employee) => !employee.hasAccount),
    [employees],
  );

  const employeeById = useMemo(
    () => new Map(employees.map((employee) => [employee.id, employee])),
    [employees],
  );

  const resetCreateForm = () => {
    setUsername("");
    setPassword("");
    setStaffRole("RECEPTIONIST");
    setEmployeeId("");
  };

  const handleCreate = async (event: FormEvent) => {
    event.preventDefault();
    setCreateError("");
    setSuccess("");
    const selectedEmployeeId = Number(employeeId);

    if (!username.trim() || !password || !selectedEmployeeId) {
      setCreateError("Vui lòng nhập tên đăng nhập, mật khẩu và chọn nhân viên.");
      return;
    }
    if (password.length < 8 || password.length > 72) {
      setCreateError("Mật khẩu ban đầu phải có từ 8 đến 72 ký tự.");
      return;
    }

    const selectedEmployee = employeeById.get(selectedEmployeeId);
    if (staffRole === "TECHNICIAN" && !selectedEmployee?.technician) {
      setCreateError("Nhân viên này chưa được khai báo là kỹ thuật viên.");
      return;
    }

    setSaving(true);
    try {
      const created = await accountsApi.create({
        username: username.trim(),
        password,
        role: staffRole,
        active: true,
        customerId: null,
        employeeId: selectedEmployeeId,
      });
      setAccounts((current) => [...current, created].sort((a, b) => a.id - b.id));
      setEmployees((current) => current.map((employee) =>
        employee.id === selectedEmployeeId ? { ...employee, hasAccount: true } : employee,
      ));
      setSuccess(`Đã tạo tài khoản ${created.username}.`);
      setShowAdd(false);
      resetCreateForm();
    } catch (createError) {
      setCreateError(errorMessage(createError, "Không thể tạo tài khoản nhân viên."));
    } finally {
      setSaving(false);
    }
  };

  const handleStatusChange = async (account: Account) => {
    setBusyAccountId(account.id);
    setError("");
    setSuccess("");
    try {
      const updated = await accountsApi.changeStatus(account.id, !account.active);
      setAccounts((current) => current.map((item) => item.id === updated.id ? updated : item));
      setSuccess(updated.active ? "Đã mở khóa tài khoản." : "Đã khóa tài khoản.");
    } catch (statusError) {
      setError(errorMessage(statusError, "Không thể cập nhật trạng thái tài khoản."));
    } finally {
      setBusyAccountId(null);
    }
  };

  const handleRoleChange = async (account: Account, nextRole: StaffRole) => {
    if (account.role === nextRole) return;
    setBusyAccountId(account.id);
    setError("");
    setSuccess("");
    try {
      const updated = await accountsApi.changeRole(account.id, nextRole);
      setAccounts((current) => current.map((item) => item.id === updated.id ? updated : item));
      setSuccess(`Đã cập nhật vai trò của ${updated.username}.`);
    } catch (roleError) {
      setError(errorMessage(roleError, "Không thể cập nhật vai trò tài khoản."));
    } finally {
      setBusyAccountId(null);
    }
  };

  return (
    <div className="space-y-6">
      <Tabs
        tabs={[{ key: "roles", label: "Vai trò & quyền" }, { key: "accounts", label: "Tài khoản" }]}
        active={tab}
        onChange={setTab}
      />

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}

      {tab === "roles" && (
        <div className="grid grid-cols-1 gap-4 xl:grid-cols-4">
          <div className="grid grid-cols-1 gap-2 sm:grid-cols-2 xl:block xl:space-y-2">
            {Object.entries(ROLES).map(([key, label]) => (
              <button
                key={key}
                type="button"
                onClick={() => setRole(key)}
                aria-pressed={role === key}
                className={`min-h-11 w-full rounded-lg border p-3 text-left transition-all ${role === key ? "border-primary bg-primary-soft ring-1 ring-primary" : "border-border bg-surface hover:border-primary/50"}`}
              >
                <span className={`rounded-lg px-2 py-1 text-xs ${ROLE_COLORS[key]}`}>{label}</span>
                <span className="ml-2 text-xs text-muted-foreground">
                  {accounts.filter((account) => roleKey(account.role) === key).length}
                </span>
              </button>
            ))}
          </div>
          <Card className="p-5 xl:col-span-3">
            <div className="mb-5">
              <h3 className="font-semibold">{ROLES[role]}</h3>
              <p className="text-xs text-muted-foreground">Vai trò được backend kiểm soát theo TaiKhoan.VaiTro.</p>
            </div>
            <div className="space-y-2">
              {(ROLE_PERMISSIONS[role] ?? []).map((permission) => (
                <div key={permission} className="flex items-center gap-2 rounded-lg bg-surface-subtle p-3">
                  <span className="text-success" aria-hidden="true">{Icons.checkCircle}</span>
                  <span className="text-sm">{permission}</span>
                </div>
              ))}
            </div>
          </Card>
        </div>
      )}

      {tab === "accounts" && (
        <div className="space-y-4">
          <div className="page-toolbar">
            <p className="text-sm text-slate-600">
              {loading ? "Đang tải tài khoản..." : `${accounts.length} tài khoản từ cơ sở dữ liệu`}
            </p>
            <div className="flex flex-wrap gap-2">
              <Button variant="outline" onClick={() => void loadAccountData()} disabled={loading}>Tải lại</Button>
              <Button icon={Icons.plus} onClick={() => { setCreateError(""); setShowAdd(true); }}>Tạo tài khoản nhân viên</Button>
            </div>
          </div>

          <Card>
            <div className="space-y-3 p-3 md:hidden">
              {!loading && accounts.length === 0 && (
                <p className="py-8 text-center text-sm text-muted-foreground">Chưa có tài khoản.</p>
              )}
              {accounts.map((account) => {
                const employee = account.employeeId ? employeeById.get(account.employeeId) : undefined;
                const isCustomer = account.role === "CUSTOMER";
                return (
                  <article key={account.id} className="space-y-3 rounded-lg border border-border bg-surface p-4">
                    <div className="flex items-start justify-between gap-3">
                      <div className="min-w-0">
                        <p className="mono truncate font-semibold text-foreground">{account.username}</p>
                        <p className="mt-1 text-xs text-muted-foreground">
                          {employee?.fullName ?? (account.customerId ? `Khách hàng #${account.customerId}` : "Chưa liên kết")}
                        </p>
                      </div>
                      <Badge variant={account.active ? "completed" : "cancelled"} label={account.active ? "Hoạt động" : "Đã khóa"} />
                    </div>
                    {isCustomer ? (
                      <span className={`inline-flex rounded-full px-2 py-1 text-xs ${ROLE_COLORS.customer}`}>{roleLabel(account.role)}</span>
                    ) : (
                      <Select
                        label="Vai trò"
                        aria-label={`Vai trò của ${account.username}`}
                        value={account.role}
                        disabled={busyAccountId === account.id}
                        onChange={(event) => void handleRoleChange(account, event.target.value as StaffRole)}
                        options={STAFF_ROLE_OPTIONS}
                      />
                    )}
                    <Button
                      className="w-full"
                      size="sm"
                      variant="outline"
                      disabled={busyAccountId === account.id}
                      onClick={() => void handleStatusChange(account)}
                    >
                      {busyAccountId === account.id ? "Đang lưu..." : account.active ? "Khóa tài khoản" : "Mở khóa tài khoản"}
                    </Button>
                  </article>
                );
              })}
            </div>

            <table className="hidden w-full data-table md:table">
              <thead>
                <tr>
                  <th>Mã</th>
                  <th>Tên đăng nhập</th>
                  <th>Chủ tài khoản</th>
                  <th>Vai trò</th>
                  <th>Trạng thái</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {!loading && accounts.length === 0 && (
                  <tr><td colSpan={6} className="py-10 text-center text-sm text-muted-foreground">Chưa có tài khoản.</td></tr>
                )}
                {accounts.map((account) => {
                  const employee = account.employeeId ? employeeById.get(account.employeeId) : undefined;
                  const isCustomer = account.role === "CUSTOMER";
                  return (
                    <tr key={account.id}>
                      <td className="mono text-xs">{account.id}</td>
                      <td className="mono">{account.username}</td>
                      <td>
                        {employee?.fullName ?? (account.customerId ? `Khách hàng #${account.customerId}` : "—")}
                        <span className="mt-0.5 block text-xs text-muted-foreground">
                          {employee ? `Nhân viên #${employee.id}` : account.customerId ? "Tài khoản khách hàng" : "Chưa liên kết"}
                        </span>
                      </td>
                      <td>
                        {isCustomer ? (
                          <span className={`rounded-full px-2 py-1 text-xs ${ROLE_COLORS.customer}`}>{roleLabel(account.role)}</span>
                        ) : (
                          <select
                            aria-label={`Vai trò của ${account.username}`}
                            value={account.role}
                            disabled={busyAccountId === account.id}
                            onChange={(event) => void handleRoleChange(account, event.target.value as StaffRole)}
                            className="min-h-11 rounded-md border border-border bg-surface px-2 text-sm focus:border-ring focus:ring-2 focus:ring-ring/15 disabled:cursor-wait disabled:opacity-60"
                          >
                            {STAFF_ROLE_OPTIONS.map((option) => (
                              <option key={option.value} value={option.value}>{option.label}</option>
                            ))}
                          </select>
                        )}
                      </td>
                      <td>
                        <Badge variant={account.active ? "completed" : "cancelled"} label={account.active ? "Hoạt động" : "Đã khóa"} />
                      </td>
                      <td>
                        <Button
                          size="sm"
                          variant="outline"
                          disabled={busyAccountId === account.id}
                          onClick={() => void handleStatusChange(account)}
                        >
                          {busyAccountId === account.id ? "Đang lưu..." : account.active ? "Khóa" : "Mở khóa"}
                        </Button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </Card>
        </div>
      )}

      <Modal open={showAdd} onClose={() => setShowAdd(false)} title="Tạo tài khoản nhân viên">
        <form className="space-y-4" onSubmit={handleCreate}>
          <Select
            label="Nhân viên *"
            value={employeeId}
            onChange={(event) => setEmployeeId(event.target.value)}
            options={[
              { value: "", label: availableEmployees.length ? "Chọn nhân viên" : "Không còn nhân viên chưa có tài khoản" },
              ...availableEmployees.map((employee) => ({
                value: String(employee.id),
                label: `${employee.id} · ${employee.fullName} · ${employee.position}`,
              })),
            ]}
            helperText="Mỗi nhân viên chỉ được liên kết với một tài khoản."
            required
          />
          <Select
            label="Vai trò nhân viên *"
            value={staffRole}
            onChange={(event) => setStaffRole(event.target.value as StaffRole)}
            options={STAFF_ROLE_OPTIONS}
            helperText="Tài khoản CUSTOMER chỉ được tạo tại trang đăng ký công khai."
            required
          />
          <Input
            label="Tên đăng nhập *"
            value={username}
            onChange={(event) => setUsername(event.target.value)}
            autoComplete="off"
            maxLength={100}
            required
          />
          <Input
            label="Mật khẩu ban đầu *"
            type="password"
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            autoComplete="new-password"
            minLength={8}
            maxLength={72}
            helperText="Từ 8 đến 72 ký tự."
            required
          />
          {createError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{createError}</p>}
          <div className="flex justify-end gap-2 pt-2">
            <Button type="button" variant="outline" onClick={() => setShowAdd(false)} disabled={saving}>Hủy</Button>
            <Button type="submit" disabled={saving || availableEmployees.length === 0}>
              {saving ? "Đang tạo..." : "Tạo tài khoản"}
            </Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
