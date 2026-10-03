// TV3-TUAN7
import { FormEvent, useEffect, useMemo, useState } from "react";
import { detailedErrorMessage } from "../api/errors";
import {
  sparePartsApi,
  stockStatus,
  STOCK_LABELS,
  type SparePart,
  type SparePartPayload,
  type Warehouse,
} from "../api/spareParts";
import { Badge, Button, Card, Icons, Input, Modal, Pagination, SearchBox, Select, TableContainer } from "../components/ui";

const PER_PAGE = 10;

const formatPrice = (value: number) =>
  new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(value);

interface PartFormProps {
  warehouses: Warehouse[];
  initial?: SparePart;
  onSubmit: (payload: SparePartPayload) => Promise<void>;
  onCancel: () => void;
}

function SparePartForm({ warehouses, initial, onSubmit, onCancel }: PartFormProps) {
  const [warehouseId, setWarehouseId] = useState(initial?.warehouseId?.toString() ?? "");
  const [name, setName] = useState(initial?.name ?? "");
  const [manufacturer, setManufacturer] = useState(initial?.manufacturer ?? "");
  const [unitPrice, setUnitPrice] = useState(initial?.unitPrice?.toString() ?? "");
  const [minStock, setMinStock] = useState(initial?.minStockLevel?.toString() ?? "0");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setError("");
    const price = Number(unitPrice);
    const min = Number(minStock);

    if (!warehouseId) return setError("Vui lòng chọn kho.");
    if (!name.trim()) return setError("Vui lòng nhập tên phụ tùng.");
    if (unitPrice.trim() === "" || !Number.isFinite(price) || price < 0) return setError("Đơn giá phải là số không âm.");
    if (!Number.isInteger(min) || min < 0) return setError("Mức tồn tối thiểu phải là số nguyên không âm.");

    setSaving(true);
    try {
      await onSubmit({
        warehouseId: Number(warehouseId),
        name: name.trim(),
        manufacturer: manufacturer.trim() || null,
        unitPrice: price,
        minStockLevel: min,
      });
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "Không thể lưu phụ tùng.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <form className="space-y-4" onSubmit={handleSubmit}>
      <Select
        label="Kho *"
        value={warehouseId}
        onChange={(event) => setWarehouseId(event.target.value)}
        options={[
          { value: "", label: "— Chọn kho —" },
          ...warehouses.map((warehouse) => ({ value: String(warehouse.id), label: warehouse.name })),
        ]}
      />
      <Input label="Tên phụ tùng *" value={name} onChange={(event) => setName(event.target.value)} maxLength={150} autoFocus required />
      <Input label="Hãng sản xuất" value={manufacturer} onChange={(event) => setManufacturer(event.target.value)} maxLength={150} />
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Input label="Đơn giá (VND) *" type="number" inputMode="decimal" min={0} step="any" value={unitPrice} onChange={(event) => setUnitPrice(event.target.value)} required />
        <Input label="Mức tồn tối thiểu" type="number" inputMode="numeric" min={0} value={minStock} onChange={(event) => setMinStock(event.target.value)} />
      </div>
      {initial && (
        <Input
          label="Số lượng tồn"
          value={String(initial.stockQuantity)}
          disabled
          helperText="Tồn kho chỉ thay đổi qua nhập/xuất kho, không sửa tại danh mục."
        />
      )}
      {error && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{error}</p>}
      <div className="flex flex-col-reverse gap-2 pt-2 sm:flex-row sm:justify-end">
        <Button type="button" variant="outline" onClick={onCancel} disabled={saving}>Hủy</Button>
        <Button type="submit" disabled={saving}>{saving ? "Đang lưu..." : initial ? "Lưu thay đổi" : "Thêm phụ tùng"}</Button>
      </div>
    </form>
  );
}

export default function SpareParts() {
  const [parts, setParts] = useState<SparePart[]>([]);
  const [totalElements, setTotalElements] = useState(0);
  const [warehouses, setWarehouses] = useState<Warehouse[]>([]);
  const [search, setSearch] = useState("");
  const [query, setQuery] = useState("");
  const [page, setPage] = useState(1);
  const [refreshKey, setRefreshKey] = useState(0);
  const [editing, setEditing] = useState<SparePart | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");

  useEffect(() => {
    const timer = window.setTimeout(() => {
      setQuery(search.trim());
      setPage(1);
    }, 300);
    return () => window.clearTimeout(timer);
  }, [search]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");
    sparePartsApi
      .list({ page: page - 1, size: PER_PAGE, search: query || undefined })
      .then((result) => {
        if (cancelled) return;
        setParts(result.items);
        setTotalElements(result.totalElements);
      })
      .catch((loadError) => {
        if (!cancelled) setError(detailedErrorMessage(loadError, "Không thể tải danh mục phụ tùng."));
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [page, query, refreshKey]);

  useEffect(() => {
    let cancelled = false;
    sparePartsApi
      .warehouses()
      .then((result) => {
        if (!cancelled) setWarehouses(result);
      })
      .catch((loadError) => {
        if (!cancelled) setError(detailedErrorMessage(loadError, "Không thể tải danh sách kho."));
      });
    return () => {
      cancelled = true;
    };
  }, []);

  const warehouseName = useMemo(() => {
    const names = new Map(warehouses.map((warehouse) => [warehouse.id, warehouse.name]));
    return (id: number) => names.get(id) ?? `Kho ${id}`;
  }, [warehouses]);

  const openCreate = () => {
    setEditing(null);
    setSuccess("");
    setShowForm(true);
  };

  const openEdit = (part: SparePart) => {
    setEditing(part);
    setSuccess("");
    setShowForm(true);
  };

  const handleSubmit = async (payload: SparePartPayload) => {
    try {
      if (editing) await sparePartsApi.update(editing.id, payload);
      else await sparePartsApi.create(payload);
    } catch (saveError) {
      throw new Error(detailedErrorMessage(saveError, "Không thể lưu phụ tùng."));
    }
    setShowForm(false);
    setSuccess(editing ? "Đã cập nhật phụ tùng." : "Đã thêm phụ tùng mới.");
    if (!editing) {
      setSearch("");
      setQuery("");
      setPage(1);
    }
    setRefreshKey((key) => key + 1);
  };

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <SearchBox value={search} onChange={setSearch} placeholder="Tìm theo tên hoặc hãng sản xuất..." />
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => setRefreshKey((key) => key + 1)} disabled={loading}>Tải lại</Button>
          <Button icon={Icons.plus} onClick={openCreate}>Thêm phụ tùng</Button>
        </div>
      </div>

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}

      <Card>
        <TableContainer>
          <table className="data-table w-full min-w-[820px]">
            <thead>
              <tr>
                <th>Mã</th>
                <th>Tên phụ tùng</th>
                <th>Hãng sản xuất</th>
                <th>Kho</th>
                <th className="text-right">Đơn giá</th>
                <th className="text-right">Tồn</th>
                <th className="text-right">Tối thiểu</th>
                <th>Tình trạng</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {loading && <tr><td colSpan={9} className="py-10 text-center text-sm text-muted-foreground">Đang tải danh mục phụ tùng...</td></tr>}
              {!loading && parts.length === 0 && !error && (
                <tr><td colSpan={9} className="py-10 text-center text-sm text-muted-foreground">Không tìm thấy phụ tùng phù hợp.</td></tr>
              )}
              {!loading && parts.map((part) => {
                const state = stockStatus(part);
                return (
                  <tr key={part.id}>
                    <td><span className="mono text-xs text-slate-400">{part.id}</span></td>
                    <td className="font-medium text-slate-800">{part.name}</td>
                    <td className="text-slate-600">{part.manufacturer || "—"}</td>
                    <td className="text-slate-600">{warehouseName(part.warehouseId)}</td>
                    <td className="mono text-right text-sm">{formatPrice(part.unitPrice)}</td>
                    <td className="mono text-right text-sm font-semibold">{part.stockQuantity}</td>
                    <td className="mono text-right text-sm text-slate-500">{part.minStockLevel}</td>
                    <td><Badge variant={state} label={STOCK_LABELS[state]} /></td>
                    <td>
                      <button
                        type="button"
                        aria-label={`Sửa phụ tùng ${part.name}`}
                        onClick={() => openEdit(part)}
                        className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100"
                      >{Icons.edit}</button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </TableContainer>
        <div className="flex flex-col gap-3 border-t border-border px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-xs text-muted-foreground">{totalElements} phụ tùng · Tồn kho chỉ thay đổi qua nhập/xuất kho</p>
          <Pagination page={page} total={totalElements} perPage={PER_PAGE} onChange={setPage} />
        </div>
      </Card>

      <Modal open={showForm} onClose={() => setShowForm(false)} title={editing ? "Cập nhật phụ tùng" : "Thêm phụ tùng"} width="max-w-xl">
        {showForm && (
          <SparePartForm
            key={editing?.id ?? "new"}
            warehouses={warehouses}
            initial={editing ?? undefined}
            onSubmit={handleSubmit}
            onCancel={() => setShowForm(false)}
          />
        )}
      </Modal>
    </div>
  );
}
