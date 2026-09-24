import { FormEvent, useCallback, useEffect, useMemo, useState } from "react";
import { customersApi, type Customer, type CustomerPayload } from "../api/customers";
import { errorMessage } from "../api/client";
import { Button, Card, Icons, Input, Modal, Pagination, SearchBox } from "../components/ui";

const EMPTY_FORM: CustomerPayload = { fullName: "", phone: "", email: "", address: "" };
const PER_PAGE = 8;

export default function Customers() {
  const [customers, setCustomers] = useState<Customer[]>([]);
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  const [selectedId, setSelectedId] = useState<number | null>(null);
  const [editing, setEditing] = useState<Customer | null>(null);
  const [form, setForm] = useState<CustomerPayload>(EMPTY_FORM);
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");
  const [formError, setFormError] = useState("");
  const [success, setSuccess] = useState("");

  const loadCustomers = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      setCustomers(await customersApi.list());
    } catch (loadError) {
      setError(errorMessage(loadError, "Không thể tải danh sách khách hàng."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    void loadCustomers();
  }, [loadCustomers]);

  const filtered = useMemo(() => {
    const keyword = search.trim().toLocaleLowerCase("vi");
    if (!keyword) return customers;
    return customers.filter((customer) =>
      customer.fullName.toLocaleLowerCase("vi").includes(keyword)
      || customer.phone.includes(keyword)
      || customer.email?.toLocaleLowerCase("vi").includes(keyword),
    );
  }, [customers, search]);

  const paged = filtered.slice((page - 1) * PER_PAGE, page * PER_PAGE);
  const selected = customers.find((customer) => customer.id === selectedId) ?? null;

  const updateField = (field: keyof CustomerPayload, value: string) => {
    setForm((current) => ({ ...current, [field]: value }));
  };

  const openCreate = () => {
    setEditing(null);
    setForm(EMPTY_FORM);
    setFormError("");
    setShowForm(true);
  };

  const openEdit = (customer: Customer) => {
    setEditing(customer);
    setForm({
      fullName: customer.fullName,
      phone: customer.phone,
      email: customer.email ?? "",
      address: customer.address ?? "",
    });
    setFormError("");
    setShowForm(true);
  };

  const handleSave = async (event: FormEvent) => {
    event.preventDefault();
    setFormError("");
    setSuccess("");
    if (!form.fullName.trim() || !form.phone.trim()) {
      setFormError("Vui lòng nhập họ tên và số điện thoại.");
      return;
    }

    setSaving(true);
    try {
      const payload = {
        fullName: form.fullName.trim(),
        phone: form.phone.trim(),
        email: form.email.trim(),
        address: form.address.trim(),
      };
      const saved = editing
        ? await customersApi.update(editing.id, payload)
        : await customersApi.create(payload);

      setCustomers((current) => editing
        ? current.map((customer) => customer.id === saved.id ? saved : customer)
        : [saved, ...current]);
      setSelectedId(saved.id);
      setShowForm(false);
      setSuccess(editing ? "Đã cập nhật thông tin khách hàng." : "Đã thêm khách hàng mới.");
    } catch (saveError) {
      setFormError(errorMessage(saveError, "Không thể lưu thông tin khách hàng."));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <SearchBox value={search} onChange={(value) => { setSearch(value); setPage(1); }} placeholder="Tên, số điện thoại, email..." />
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => void loadCustomers()} disabled={loading}>Tải lại</Button>
          <Button icon={Icons.plus} onClick={openCreate}>Thêm khách hàng</Button>
        </div>
      </div>

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}

      <div className={`grid gap-4 ${selected ? "xl:grid-cols-3" : "grid-cols-1"}`}>
        <Card className={selected ? "xl:col-span-2" : ""}>
          <div className="space-y-3 p-3 md:hidden">
            {loading && <p className="py-8 text-center text-sm text-muted-foreground">Đang tải khách hàng...</p>}
            {!loading && paged.length === 0 && <p className="py-8 text-center text-sm text-muted-foreground">Không tìm thấy khách hàng phù hợp.</p>}
            {paged.map((customer) => (
              <article key={customer.id} className={`rounded-lg border p-4 ${selectedId === customer.id ? "border-primary bg-primary-soft/40" : "border-border bg-surface"}`}>
                <button type="button" className="w-full text-left" onClick={() => setSelectedId(customer.id === selectedId ? null : customer.id)}>
                  <div className="flex items-start gap-3">
                    <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full bg-primary font-bold text-white" aria-hidden="true">{customer.fullName.charAt(0)}</div>
                    <div className="min-w-0 flex-1">
                      <p className="font-semibold text-foreground">{customer.fullName}</p>
                      <p className="mt-1 text-sm text-muted-foreground">{customer.phone}</p>
                      <p className="mt-1 truncate text-sm text-muted-foreground">{customer.email || "Chưa cập nhật email"}</p>
                    </div>
                  </div>
                </button>
                <Button className="mt-3 w-full" size="sm" variant="outline" icon={Icons.edit} onClick={() => openEdit(customer)}>Chỉnh sửa</Button>
              </article>
            ))}
          </div>

          <table className="hidden w-full data-table md:table">
            <thead><tr><th>Mã KH</th><th>Họ tên</th><th>Số điện thoại</th><th>Email</th><th>Địa chỉ</th><th>Thao tác</th></tr></thead>
            <tbody>
              {loading && <tr><td colSpan={6} className="py-10 text-center text-sm text-muted-foreground">Đang tải khách hàng...</td></tr>}
              {!loading && paged.length === 0 && <tr><td colSpan={6} className="py-10 text-center text-sm text-muted-foreground">Không tìm thấy khách hàng phù hợp.</td></tr>}
              {paged.map((customer) => (
                <tr key={customer.id} aria-selected={selectedId === customer.id} className={selectedId === customer.id ? "bg-info-soft" : ""}>
                  <td className="mono text-xs text-muted-foreground">KH{String(customer.id).padStart(3, "0")}</td>
                  <td><button type="button" className="min-h-11 text-left font-semibold text-foreground hover:text-primary" onClick={() => setSelectedId(customer.id === selectedId ? null : customer.id)}>{customer.fullName}</button></td>
                  <td className="mono text-sm">{customer.phone}</td>
                  <td className="text-muted-foreground">{customer.email || "—"}</td>
                  <td className="max-w-[220px] truncate text-muted-foreground" title={customer.address ?? undefined}>{customer.address || "—"}</td>
                  <td><Button size="sm" variant="ghost" icon={Icons.edit} onClick={() => openEdit(customer)}>Sửa</Button></td>
                </tr>
              ))}
            </tbody>
          </table>

          <div className="flex flex-col gap-3 border-t border-border px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
            <p className="text-xs text-muted-foreground">{filtered.length} khách hàng</p>
            <Pagination page={page} total={filtered.length} perPage={PER_PAGE} onChange={setPage} />
          </div>
        </Card>

        {selected && (
          <Card className="detail-panel p-4 sm:p-5">
            <div className="mb-5 flex items-start justify-between gap-3">
              <div className="flex min-w-0 items-center gap-3">
                <div className="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-full bg-primary text-lg font-bold text-white" aria-hidden="true">{selected.fullName.charAt(0)}</div>
                <div className="min-w-0"><h3 className="font-bold text-foreground">{selected.fullName}</h3><p className="mono text-xs text-muted-foreground">KH{String(selected.id).padStart(3, "0")}</p></div>
              </div>
              <button type="button" aria-label="Đóng thông tin khách hàng" onClick={() => setSelectedId(null)} className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-md text-muted-foreground hover:bg-muted">{Icons.close}</button>
            </div>
            <dl className="space-y-4 text-sm">
              <div><dt className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Số điện thoại</dt><dd className="mono mt-1 text-foreground">{selected.phone}</dd></div>
              <div><dt className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Email</dt><dd className="mt-1 break-words text-foreground">{selected.email || "Chưa cập nhật"}</dd></div>
              <div><dt className="text-xs font-semibold uppercase tracking-wide text-muted-foreground">Địa chỉ</dt><dd className="mt-1 text-foreground">{selected.address || "Chưa cập nhật"}</dd></div>
            </dl>
            <Button className="mt-6 w-full" variant="outline" icon={Icons.edit} onClick={() => openEdit(selected)}>Chỉnh sửa thông tin</Button>
          </Card>
        )}
      </div>

      <Modal open={showForm} onClose={() => setShowForm(false)} title={editing ? "Cập nhật khách hàng" : "Thêm khách hàng mới"}>
        <form className="space-y-4" onSubmit={handleSave}>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            <Input label="Họ và tên *" value={form.fullName} onChange={(event) => updateField("fullName", event.target.value)} maxLength={100} autoFocus required />
            <Input label="Số điện thoại *" value={form.phone} onChange={(event) => updateField("phone", event.target.value)} inputMode="tel" minLength={8} maxLength={20} required />
          </div>
          <Input label="Email" type="email" value={form.email} onChange={(event) => updateField("email", event.target.value)} maxLength={150} />
          <Input label="Địa chỉ" value={form.address} onChange={(event) => updateField("address", event.target.value)} maxLength={255} />
          {formError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{formError}</p>}
          <div className="flex flex-col-reverse gap-2 pt-2 sm:flex-row sm:justify-end">
            <Button type="button" variant="outline" onClick={() => setShowForm(false)} disabled={saving}>Hủy</Button>
            <Button type="submit" disabled={saving}>{saving ? "Đang lưu..." : editing ? "Lưu thay đổi" : "Lưu khách hàng"}</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
