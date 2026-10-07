// TV3-TUAN8
import { FormEvent, useCallback, useEffect, useState } from "react";
import { detailedErrorMessage } from "../../api/errors";
import { sparePartsApi, type SparePart } from "../../api/spareParts";
import { warehouseApi, type ImportItemPayload, type PageResult, type StockImport } from "../../api/warehouse";
import { Button, Card, Icons, Input, Pagination, Select } from "../../components/ui";
import { formatDateTime, formatPrice, PER_PAGE, useWarehouseRole } from "./common";

interface Row {
  partId: string;
  quantity: string;
  unitPrice: string;
}

const emptyRow = (): Row => ({ partId: "", quantity: "1", unitPrice: "" });

export default function ImportsTab({ refreshKey, onChanged }: { refreshKey: number; onChanged: () => void }) {
  const { canWrite } = useWarehouseRole();
  const [parts, setParts] = useState<SparePart[]>([]);
  const [supplier, setSupplier] = useState("");
  const [importDate, setImportDate] = useState("");
  const [note, setNote] = useState("");
  const [rows, setRows] = useState<Row[]>([emptyRow()]);
  const [formError, setFormError] = useState("");
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState("");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<PageResult<StockImport> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => {
    sparePartsApi.list({ page: 0, size: 100 })
      .then((result) => setParts(result.items))
      .catch((loadError) => setFormError(detailedErrorMessage(loadError, "Không thể tải danh mục phụ tùng.")));
  }, []);

  const load = useCallback(() => {
    setLoading(true);
    setError("");
    warehouseApi.imports({ page: page - 1, size: PER_PAGE })
      .then(setData)
      .catch((loadError) => setError(detailedErrorMessage(loadError, "Không thể tải phiếu nhập kho.")))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(load, [load, refreshKey]);

  const updateRow = (index: number, patch: Partial<Row>) =>
    setRows((current) => current.map((row, i) => (i === index ? { ...row, ...patch } : row)));

  const total = rows.reduce((sum, row) => sum + (Number(row.quantity) || 0) * (Number(row.unitPrice) || 0), 0);

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setFormError("");
    setSuccess("");
    if (!supplier.trim()) return setFormError("Vui lòng nhập nhà cung cấp.");

    const items: ImportItemPayload[] = [];
    const seen = new Set<string>();
    for (const row of rows) {
      const quantity = Number(row.quantity);
      const unitPrice = Number(row.unitPrice);
      if (!row.partId) return setFormError("Vui lòng chọn phụ tùng cho tất cả các dòng.");
      if (seen.has(row.partId)) return setFormError("Một phụ tùng chỉ xuất hiện một lần trong phiếu nhập.");
      if (!Number.isInteger(quantity) || quantity <= 0) return setFormError("Số lượng nhập phải là số nguyên lớn hơn 0.");
      if (row.unitPrice.trim() === "" || !Number.isFinite(unitPrice) || unitPrice < 0) return setFormError("Đơn giá nhập phải là số không âm.");
      seen.add(row.partId);
      items.push({ partId: Number(row.partId), quantity, unitPrice });
    }

    setSaving(true);
    try {
      await warehouseApi.createImport({
        supplier: supplier.trim(),
        importDate: importDate || null,
        note: note.trim() || null,
        items,
      });
      setSuccess("Đã nhập kho. Tồn kho và lịch sử biến động đã được cập nhật.");
      setSupplier(""); setImportDate(""); setNote(""); setRows([emptyRow()]);
      setPage(1);
      onChanged();
      load();
    } catch (saveError) {
      setFormError(detailedErrorMessage(saveError, "Không thể lập phiếu nhập."));
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-4">
      {canWrite && (
        <Card className="p-5">
          <h3 className="mb-4 font-semibold">Lập phiếu nhập kho</h3>
          <form className="space-y-4" onSubmit={submit}>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              <Input label="Nhà cung cấp *" value={supplier} onChange={(event) => setSupplier(event.target.value)} maxLength={200} />
              <Input label="Ngày nhập" type="datetime-local" value={importDate} onChange={(event) => setImportDate(event.target.value)} helperText="Bỏ trống để dùng thời điểm hiện tại." />
              <Input label="Ghi chú" value={note} onChange={(event) => setNote(event.target.value)} maxLength={500} />
            </div>

            <div className="space-y-3">
              {rows.map((row, index) => (
                <div key={index} className="grid grid-cols-1 items-end gap-3 md:grid-cols-[2fr_1fr_1fr_auto]">
                  <Select
                    label={index === 0 ? "Phụ tùng *" : undefined}
                    value={row.partId}
                    onChange={(event) => {
                      const picked = parts.find((part) => String(part.id) === event.target.value);
                      updateRow(index, { partId: event.target.value, unitPrice: picked && !row.unitPrice ? String(picked.unitPrice) : row.unitPrice });
                    }}
                    options={[{ value: "", label: "— Chọn phụ tùng —" }, ...parts.map((part) => ({ value: String(part.id), label: `${part.id} · ${part.name}` }))]}
                  />
                  <Input label={index === 0 ? "Số lượng *" : undefined} type="number" min={1} value={row.quantity} onChange={(event) => updateRow(index, { quantity: event.target.value })} />
                  <Input label={index === 0 ? "Đơn giá nhập *" : undefined} type="number" min={0} step="any" value={row.unitPrice} onChange={(event) => updateRow(index, { unitPrice: event.target.value })} />
                  <Button type="button" variant="outline" disabled={rows.length === 1} onClick={() => setRows((current) => current.filter((_, i) => i !== index))}>Xóa dòng</Button>
                </div>
              ))}
              <Button type="button" variant="outline" icon={Icons.plus} onClick={() => setRows((current) => [...current, emptyRow()])}>Thêm phụ tùng</Button>
            </div>

            <p className="text-sm text-slate-600">Tổng tiền: <strong className="mono">{formatPrice(total)}</strong></p>
            <p className="text-xs text-slate-500">Mỗi chi tiết nhập tăng tồn kho đúng một lần và ghi một dòng biến động NHAP.</p>
            {formError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{formError}</p>}
            {success && <p className="rounded-md bg-success-soft px-3 py-2 text-sm text-success" role="status">{success}</p>}
            <Button type="submit" disabled={saving}>{saving ? "Đang lưu..." : "Lưu phiếu nhập"}</Button>
          </form>
        </Card>
      )}

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {loading && <Card className="p-6 text-center text-sm text-muted-foreground">Đang tải phiếu nhập...</Card>}
      {!loading && data?.items.length === 0 && !error && <Card className="p-6 text-center text-sm text-muted-foreground">Chưa có phiếu nhập kho.</Card>}
      {!loading && data?.items.map((receipt) => (
        <Card key={receipt.id} className="p-5">
          <div className="receipt-header">
            <div>
              <p className="font-semibold">Phiếu nhập #{receipt.id}</p>
              <p className="text-xs text-slate-500">{formatDateTime(receipt.importDate)} · {receipt.supplier}</p>
            </div>
            <p className="text-sm">Nhân viên kho: {receipt.warehouseStaffId}</p>
          </div>
          <table className="data-table w-full">
            <thead><tr><th>Mã</th><th>Tên phụ tùng</th><th className="text-right">Số lượng</th><th className="text-right">Đơn giá nhập</th><th className="text-right">Thành tiền</th></tr></thead>
            <tbody>
              {receipt.items.map((item) => (
                <tr key={item.partId}>
                  <td className="mono text-xs">{item.partId}</td><td>{item.partName}</td>
                  <td className="text-right">{item.quantity}</td>
                  <td className="text-right">{formatPrice(item.unitPrice)}</td>
                  <td className="text-right font-semibold">{formatPrice(item.lineTotal)}</td>
                </tr>
              ))}
            </tbody>
          </table>
          <p className="mt-3 text-right text-sm font-semibold">Tổng: {formatPrice(receipt.totalAmount)}</p>
          {receipt.note && <p className="mt-1 text-xs text-slate-500">Ghi chú: {receipt.note}</p>}
        </Card>
      ))}
      {data && <Pagination page={page} total={data.totalElements} perPage={PER_PAGE} onChange={setPage} />}
    </div>
  );
}
