// TV3-TUAN7
import { FormEvent, useCallback, useEffect, useState } from "react";
import { detailedErrorMessage } from "../api/errors";
import {
  repairDetailsApi,
  type RepairDetail,
  type RepairDetailType,
  type RepairDetails as RepairDetailsData,
} from "../api/repairDetails";
import { sparePartsApi, type SparePart } from "../api/spareParts";
import { Badge, Button, Card, Icons, Input, Modal, Select, TableContainer } from "../components/ui";

const formatPrice = (value: number) =>
  new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(value);

const TYPE_LABELS: Record<RepairDetailType, string> = {
  SERVICE: "Dịch vụ",
  SPARE_PART: "Phụ tùng",
};

interface DetailFormProps {
  editing: RepairDetail | null;
  onSubmit: (value: { type: RepairDetailType; itemId: number; quantity: number; unitPrice: number | null }) => Promise<void>;
  onCancel: () => void;
}

function DetailForm({ editing, onSubmit, onCancel }: DetailFormProps) {
  const [type, setType] = useState<RepairDetailType>(editing?.type ?? "SPARE_PART");
  const [itemId, setItemId] = useState(editing?.itemId?.toString() ?? "");
  const [quantity, setQuantity] = useState(editing?.quantity?.toString() ?? "1");
  const [unitPrice, setUnitPrice] = useState(editing ? String(editing.unitPrice) : "");
  const [parts, setParts] = useState<SparePart[]>([]);
  const [partsError, setPartsError] = useState("");
  const [error, setError] = useState("");
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (editing || type !== "SPARE_PART") return;
    let cancelled = false;
    sparePartsApi
      .list({ page: 0, size: 100 })
      .then((result) => {
        if (!cancelled) setParts(result.items);
      })
      .catch((loadError) => {
        if (!cancelled) setPartsError(detailedErrorMessage(loadError, "Không thể tải danh mục phụ tùng."));
      });
    return () => {
      cancelled = true;
    };
  }, [editing, type]);

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault();
    setError("");
    const id = Number(itemId);
    const qty = Number(quantity);
    const price = unitPrice.trim() === "" ? null : Number(unitPrice);

    if (!editing && (!Number.isInteger(id) || id <= 0)) return setError(type === "SERVICE" ? "Vui lòng nhập mã dịch vụ." : "Vui lòng chọn phụ tùng.");
    if (!Number.isInteger(qty) || qty <= 0) return setError("Số lượng phải là số nguyên lớn hơn 0.");
    if (price !== null && (!Number.isFinite(price) || price < 0)) return setError("Đơn giá phải là số không âm.");

    setSaving(true);
    try {
      await onSubmit({ type, itemId: editing ? editing.itemId : id, quantity: qty, unitPrice: price });
    } catch (submitError) {
      setError(submitError instanceof Error ? submitError.message : "Không thể lưu hạng mục.");
    } finally {
      setSaving(false);
    }
  };

  return (
    <form className="space-y-4" onSubmit={handleSubmit}>
      {editing ? (
        <p className="rounded-md bg-muted px-3 py-2 text-sm text-slate-700">
          {TYPE_LABELS[editing.type]}: <span className="font-semibold">{editing.itemName}</span>
        </p>
      ) : (
        <>
          <Select
            label="Loại hạng mục *"
            value={type}
            onChange={(event) => { setType(event.target.value as RepairDetailType); setItemId(""); }}
            options={[
              { value: "SPARE_PART", label: "Phụ tùng" },
              { value: "SERVICE", label: "Dịch vụ" },
            ]}
          />
          {type === "SPARE_PART" ? (
            <Select
              label="Phụ tùng *"
              value={itemId}
              onChange={(event) => {
                setItemId(event.target.value);
                const picked = parts.find((part) => String(part.id) === event.target.value);
                if (picked) setUnitPrice(String(picked.unitPrice));
              }}
              helperText={partsError || "Đơn giá mặc định lấy từ danh mục phụ tùng."}
              options={[
                { value: "", label: "— Chọn phụ tùng —" },
                ...parts.map((part) => ({ value: String(part.id), label: `${part.name}${part.manufacturer ? ` – ${part.manufacturer}` : ""}` })),
              ]}
            />
          ) : (
            <Input
              label="Mã dịch vụ *"
              type="number"
              inputMode="numeric"
              min={1}
              value={itemId}
              onChange={(event) => setItemId(event.target.value)}
              helperText="Nhập mã dịch vụ trong danh mục Dịch vụ. Để trống đơn giá để lấy giá niêm yết."
            />
          )}
        </>
      )}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Input label="Số lượng *" type="number" inputMode="numeric" min={1} value={quantity} onChange={(event) => setQuantity(event.target.value)} required />
        <Input label="Đơn giá (VND)" type="number" inputMode="decimal" min={0} step="any" value={unitPrice} onChange={(event) => setUnitPrice(event.target.value)} />
      </div>
      <p className="text-xs leading-5 text-muted-foreground">
        Thêm hoặc sửa hạng mục chỉ ghi chi tiết phiếu; không xuất kho và không thay đổi tồn kho.
      </p>
      {error && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{error}</p>}
      <div className="flex flex-col-reverse gap-2 pt-2 sm:flex-row sm:justify-end">
        <Button type="button" variant="outline" onClick={onCancel} disabled={saving}>Hủy</Button>
        <Button type="submit" disabled={saving}>{saving ? "Đang lưu..." : editing ? "Lưu thay đổi" : "Thêm hạng mục"}</Button>
      </div>
    </form>
  );
}

export default function RepairDetails() {
  const [orderInput, setOrderInput] = useState("");
  const [orderId, setOrderId] = useState<number | null>(null);
  const [data, setData] = useState<RepairDetailsData | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<RepairDetail | null>(null);
  const [deleting, setDeleting] = useState<RepairDetail | null>(null);
  const [deleteBusy, setDeleteBusy] = useState(false);

  const load = useCallback(async (id: number) => {
    setLoading(true);
    setError("");
    try {
      setData(await repairDetailsApi.list(id));
    } catch (loadError) {
      setData(null);
      setError(detailedErrorMessage(loadError, "Không thể tải chi tiết phiếu sửa chữa."));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    if (orderId !== null) void load(orderId);
  }, [orderId, load]);

  const handleLookup = (event: FormEvent) => {
    event.preventDefault();
    setSuccess("");
    const id = Number(orderInput);
    if (!Number.isInteger(id) || id <= 0) {
      setData(null);
      setError("Vui lòng nhập mã phiếu sửa chữa hợp lệ.");
      return;
    }
    if (id === orderId) void load(id);
    else setOrderId(id);
  };

  const handleSubmit = async (value: { type: RepairDetailType; itemId: number; quantity: number; unitPrice: number | null }) => {
    if (orderId === null) return;
    try {
      if (editing) {
        await repairDetailsApi.update(orderId, editing.type, editing.itemId, { quantity: value.quantity, unitPrice: value.unitPrice });
      } else {
        await repairDetailsApi.create(orderId, value);
      }
    } catch (saveError) {
      throw new Error(detailedErrorMessage(saveError, "Không thể lưu hạng mục."));
    }
    setShowForm(false);
    setSuccess(editing ? "Đã cập nhật hạng mục." : "Đã thêm hạng mục.");
    await load(orderId);
  };

  const confirmDelete = async () => {
    if (orderId === null || !deleting) return;
    setDeleteBusy(true);
    try {
      await repairDetailsApi.remove(orderId, deleting.type, deleting.itemId);
      setDeleting(null);
      setSuccess("Đã xóa hạng mục.");
      await load(orderId);
    } catch (deleteError) {
      setDeleting(null);
      setError(detailedErrorMessage(deleteError, "Không thể xóa hạng mục."));
    } finally {
      setDeleteBusy(false);
    }
  };

  return (
    <div className="space-y-6">
      <Card className="p-4 sm:p-5">
        <form className="flex flex-col gap-3 sm:flex-row sm:items-end" onSubmit={handleLookup}>
          <div className="sm:w-72">
            <Input
              label="Mã phiếu sửa chữa"
              type="number"
              inputMode="numeric"
              min={1}
              value={orderInput}
              onChange={(event) => setOrderInput(event.target.value)}
              placeholder="Ví dụ: 1"
            />
          </div>
          <Button type="submit" disabled={loading}>{loading ? "Đang tải..." : "Xem chi tiết"}</Button>
        </form>
      </Card>

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}

      {data && (
        <Card>
          <div className="flex flex-col gap-3 border-b border-border px-4 py-4 sm:flex-row sm:items-center sm:justify-between sm:px-5">
            <div>
              <p className="text-lg font-bold text-foreground">Phiếu sửa chữa #{data.repairOrderId}</p>
              <p className="mt-1 flex items-center gap-2 text-sm text-muted-foreground">
                Trạng thái phiếu: <Badge variant={data.editable ? "in_progress" : "completed"} label={data.repairOrderStatus} />
              </p>
            </div>
            <Button icon={Icons.plus} disabled={!data.editable} onClick={() => { setEditing(null); setSuccess(""); setShowForm(true); }}>
              Thêm hạng mục
            </Button>
          </div>
          {!data.editable && (
            <p className="border-b border-border bg-muted px-4 py-2 text-xs text-muted-foreground sm:px-5">
              Phiếu đã đóng nên không thể thêm, sửa hoặc xóa hạng mục.
            </p>
          )}
          <TableContainer>
            <table className="data-table w-full min-w-[720px]">
              <thead>
                <tr>
                  <th>Loại</th>
                  <th>Hạng mục</th>
                  <th className="text-right">Số lượng</th>
                  <th className="text-right">Đơn giá</th>
                  <th className="text-right">Thành tiền</th>
                  <th>Tiến độ</th>
                  <th>Thao tác</th>
                </tr>
              </thead>
              <tbody>
                {data.items.length === 0 && (
                  <tr><td colSpan={7} className="py-10 text-center text-sm text-muted-foreground">Phiếu chưa có hạng mục nào.</td></tr>
                )}
                {data.items.map((item) => (
                  <tr key={`${item.type}-${item.itemId}`}>
                    <td><Badge variant={item.type === "SERVICE" ? "confirmed" : "draft"} label={TYPE_LABELS[item.type]} /></td>
                    <td className="font-medium text-slate-800">{item.itemName}</td>
                    <td className="mono text-right text-sm">{item.quantity}</td>
                    <td className="mono text-right text-sm">{formatPrice(item.unitPrice)}</td>
                    <td className="mono text-right text-sm font-semibold">{formatPrice(item.lineTotal)}</td>
                    <td className="text-sm text-slate-600">{item.status ?? "—"}</td>
                    <td>
                      <div className="flex gap-1">
                        <button
                          type="button"
                          aria-label={`Sửa hạng mục ${item.itemName}`}
                          disabled={!data.editable}
                          onClick={() => { setEditing(item); setSuccess(""); setShowForm(true); }}
                          className="flex h-11 w-11 items-center justify-center rounded text-slate-500 hover:bg-slate-100 disabled:opacity-40"
                        >{Icons.edit}</button>
                        <button
                          type="button"
                          aria-label={`Xóa hạng mục ${item.itemName}`}
                          disabled={!data.editable}
                          onClick={() => setDeleting(item)}
                          className="flex h-11 items-center justify-center rounded px-2 text-sm text-danger hover:bg-danger-soft disabled:opacity-40"
                        >Xóa</button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </TableContainer>
          <dl className="grid grid-cols-1 gap-3 border-t border-border px-4 py-4 text-sm sm:grid-cols-3 sm:px-5">
            <div><dt className="text-xs text-muted-foreground">Tiền dịch vụ</dt><dd className="mono mt-1 font-semibold">{formatPrice(data.serviceTotal)}</dd></div>
            <div><dt className="text-xs text-muted-foreground">Tiền phụ tùng</dt><dd className="mono mt-1 font-semibold">{formatPrice(data.partsTotal)}</dd></div>
            <div><dt className="text-xs text-muted-foreground">Tổng cộng</dt><dd className="mono mt-1 text-lg font-bold text-primary">{formatPrice(data.totalAmount)}</dd></div>
          </dl>
        </Card>
      )}

      <Modal open={showForm} onClose={() => setShowForm(false)} title={editing ? "Sửa hạng mục" : "Thêm hạng mục"} width="max-w-xl">
        {showForm && (
          <DetailForm
            key={editing ? `${editing.type}-${editing.itemId}` : "new"}
            editing={editing}
            onSubmit={handleSubmit}
            onCancel={() => setShowForm(false)}
          />
        )}
      </Modal>

      <Modal open={deleting !== null} onClose={() => setDeleting(null)} title="Xóa hạng mục" width="max-w-md">
        {deleting && (
          <div className="space-y-4">
            <p className="text-sm text-slate-700">
              Xóa <span className="font-semibold">{deleting.itemName}</span> khỏi phiếu #{orderId}? Thao tác này không ảnh hưởng đến tồn kho.
            </p>
            <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
              <Button variant="outline" onClick={() => setDeleting(null)} disabled={deleteBusy}>Hủy</Button>
              <Button variant="danger" onClick={() => void confirmDelete()} disabled={deleteBusy}>{deleteBusy ? "Đang xóa..." : "Xóa hạng mục"}</Button>
            </div>
          </div>
        )}
      </Modal>
    </div>
  );
}
