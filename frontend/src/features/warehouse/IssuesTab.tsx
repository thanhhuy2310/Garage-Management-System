// TV3-TUAN8
import { FormEvent, useCallback, useEffect, useState } from "react";
import { detailedErrorMessage } from "../../api/errors";
import { sparePartsApi, type SparePart } from "../../api/spareParts";
import { warehouseApi, type IssueItem, type PageResult, type StockIssue } from "../../api/warehouse";
import { Badge, Button, Card, Icons, Input, Modal, Pagination, Select } from "../../components/ui";
import { formatDateTime, PER_PAGE, useWarehouseRole } from "./common";

interface Row {
  partId: string;
  quantity: string;
}

const emptyRow = (): Row => ({ partId: "", quantity: "1" });

export default function IssuesTab({ refreshKey, onChanged }: { refreshKey: number; onChanged: () => void }) {
  const { canWrite, canConfirmUsage, role, needsTechnicianId } = useWarehouseRole();
  // Kỹ thuật viên chỉ xem/xác nhận; tạo phiếu xuất do thủ kho/quản lý.
  const canIssue = canWrite && role !== "TECHNICIAN";

  const [parts, setParts] = useState<SparePart[]>([]);
  const [orderId, setOrderId] = useState("");
  const [technicianId, setTechnicianId] = useState("");
  const [reason, setReason] = useState("");
  const [rows, setRows] = useState<Row[]>([emptyRow()]);
  const [formError, setFormError] = useState("");
  const [saving, setSaving] = useState(false);
  const [success, setSuccess] = useState("");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<PageResult<StockIssue> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  const [confirming, setConfirming] = useState<{ issue: StockIssue; item: IssueItem } | null>(null);
  const [actualUsed, setActualUsed] = useState("");
  const [confirmTechnician, setConfirmTechnician] = useState("");
  const [confirmError, setConfirmError] = useState("");
  const [confirmBusy, setConfirmBusy] = useState(false);

  useEffect(() => {
    if (!canIssue) return;
    sparePartsApi.list({ page: 0, size: 100 })
      .then((result) => setParts(result.items))
      .catch((loadError) => setFormError(detailedErrorMessage(loadError, "Không thể tải danh mục phụ tùng.")));
  }, [canIssue]);

  const load = useCallback(() => {
    setLoading(true);
    setError("");
    warehouseApi.issues({ page: page - 1, size: PER_PAGE })
      .then(setData)
      .catch((loadError) => setError(detailedErrorMessage(loadError, "Không thể tải phiếu xuất kho.")))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(load, [load, refreshKey]);

  const updateRow = (index: number, patch: Partial<Row>) =>
    setRows((current) => current.map((row, i) => (i === index ? { ...row, ...patch } : row)));

  const submit = async (event: FormEvent) => {
    event.preventDefault();
    setFormError("");
    setSuccess("");
    const order = Number(orderId);
    const technician = technicianId.trim() === "" ? null : Number(technicianId);
    if (!Number.isInteger(order) || order <= 0) return setFormError("Vui lòng nhập mã phiếu sửa chữa hợp lệ.");
    if (technician !== null && (!Number.isInteger(technician) || technician <= 0)) return setFormError("Mã kỹ thuật viên không hợp lệ.");
    if (!reason.trim()) return setFormError("Vui lòng nhập lý do xuất.");

    const items: { partId: number; quantity: number }[] = [];
    const seen = new Set<string>();
    for (const row of rows) {
      const quantity = Number(row.quantity);
      if (!row.partId) return setFormError("Vui lòng chọn phụ tùng cho tất cả các dòng.");
      if (seen.has(row.partId)) return setFormError("Một phụ tùng chỉ xuất hiện một lần trong phiếu xuất.");
      if (!Number.isInteger(quantity) || quantity <= 0) return setFormError("Số lượng cấp phát phải là số nguyên lớn hơn 0.");
      seen.add(row.partId);
      items.push({ partId: Number(row.partId), quantity });
    }

    setSaving(true);
    try {
      await warehouseApi.createIssue({ repairOrderId: order, requestedTechnicianId: technician, reason: reason.trim(), items });
      // Không báo "đã trừ tồn": cấp phát chưa giảm tồn.
      setSuccess("Đã cấp phát — chờ KTV xác nhận thực dùng. Tồn kho chưa thay đổi.");
      setOrderId(""); setTechnicianId(""); setReason(""); setRows([emptyRow()]);
      setPage(1);
      load();
    } catch (saveError) {
      setFormError(detailedErrorMessage(saveError, "Không thể lập phiếu xuất."));
    } finally {
      setSaving(false);
    }
  };

  const openConfirm = (issue: StockIssue, item: IssueItem) => {
    setConfirming({ issue, item });
    setActualUsed(String(item.issuedQuantity));
    setConfirmTechnician(issue.requestedTechnicianId ? String(issue.requestedTechnicianId) : "");
    setConfirmError("");
  };

  const submitConfirm = async (event: FormEvent) => {
    event.preventDefault();
    if (!confirming) return;
    setConfirmError("");
    const used = Number(actualUsed);
    if (!Number.isInteger(used) || used < 0 || used > confirming.item.issuedQuantity) {
      return setConfirmError(`Số lượng thực dùng phải là số nguyên từ 0 đến ${confirming.item.issuedQuantity}.`);
    }
    const technician = Number(confirmTechnician);
    if (needsTechnicianId && (!Number.isInteger(technician) || technician <= 0)) return setConfirmError("Vui lòng nhập mã kỹ thuật viên xác nhận.");

    setConfirmBusy(true);
    try {
      await warehouseApi.confirmUsage(confirming.issue.id, confirming.item.partId, {
        actualUsed: used,
        technicianId: needsTechnicianId ? technician : null,
      });
      setConfirming(null);
      setSuccess("Đã xác nhận thực dùng. Tồn kho giảm theo số lượng thực dùng.");
      onChanged();
      load();
    } catch (confirmErr) {
      setConfirmError(detailedErrorMessage(confirmErr, "Không thể xác nhận thực dùng."));
    } finally {
      setConfirmBusy(false);
    }
  };

  const used = Number(actualUsed);
  const preview = confirming && Number.isInteger(used) && used >= 0 && used <= confirming.item.issuedQuantity
    ? confirming.item.issuedQuantity - used
    : null;

  return (
    <div className="space-y-4">
      <div className="rounded-lg border border-info/20 bg-info-soft p-4 text-sm text-info">
        Lập phiếu xuất là <strong>cấp phát</strong> và <strong>chưa trừ tồn kho</strong>. Tồn chỉ giảm khi kỹ thuật viên xác nhận số lượng thực dùng; phần chưa dùng được hoàn trả.
      </div>

      {canIssue && (
        <Card className="p-5">
          <h3 className="mb-4 font-semibold">Lập phiếu xuất kho (cấp phát)</h3>
          <form className="space-y-4" onSubmit={submit}>
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              <Input label="Mã phiếu sửa chữa *" type="number" min={1} value={orderId} onChange={(event) => setOrderId(event.target.value)} />
              <Input label="Mã kỹ thuật viên yêu cầu" type="number" min={1} value={technicianId} onChange={(event) => setTechnicianId(event.target.value)} helperText="Phải là KTV được phân công cho phiếu." />
              <Input label="Lý do *" value={reason} onChange={(event) => setReason(event.target.value)} maxLength={500} />
            </div>
            <div className="space-y-3">
              {rows.map((row, index) => {
                const picked = parts.find((part) => String(part.id) === row.partId);
                return (
                  <div key={index} className="grid grid-cols-1 items-end gap-3 md:grid-cols-[2fr_1fr_auto]">
                    <Select
                      label={index === 0 ? "Phụ tùng *" : undefined}
                      value={row.partId}
                      onChange={(event) => updateRow(index, { partId: event.target.value })}
                      helperText={picked ? `Tồn hiện tại: ${picked.stockQuantity}` : undefined}
                      options={[{ value: "", label: "— Chọn phụ tùng —" }, ...parts.map((part) => ({ value: String(part.id), label: `${part.id} · ${part.name}` }))]}
                    />
                    <Input label={index === 0 ? "Số lượng cấp phát *" : undefined} type="number" min={1} value={row.quantity} onChange={(event) => updateRow(index, { quantity: event.target.value })} />
                    <Button type="button" variant="outline" disabled={rows.length === 1} onClick={() => setRows((current) => current.filter((_, i) => i !== index))}>Xóa dòng</Button>
                  </div>
                );
              })}
              <Button type="button" variant="outline" icon={Icons.plus} onClick={() => setRows((current) => [...current, emptyRow()])}>Thêm phụ tùng</Button>
            </div>
            {formError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{formError}</p>}
            <Button type="submit" disabled={saving}>{saving ? "Đang cấp phát..." : "Cấp phát phụ tùng"}</Button>
          </form>
        </Card>
      )}

      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}
      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {loading && <Card className="p-6 text-center text-sm text-muted-foreground">Đang tải phiếu xuất...</Card>}
      {!loading && data?.items.length === 0 && !error && <Card className="p-6 text-center text-sm text-muted-foreground">Chưa có phiếu xuất kho.</Card>}

      {!loading && data?.items.map((issue) => (
        <Card key={issue.id} className="p-5">
          <div className="receipt-header">
            <div>
              <p className="font-semibold">Phiếu xuất #{issue.id} · Phiếu sửa chữa {issue.repairOrderId ?? "—"}</p>
              <p className="text-xs text-slate-500">{formatDateTime(issue.issueDate)} · {issue.reason}</p>
            </div>
            <p className="text-xs text-slate-500">Nhân viên kho: {issue.warehouseStaffId} · KTV yêu cầu: {issue.requestedTechnicianId ?? "—"}</p>
          </div>
          <table className="data-table w-full">
            <thead>
              <tr>
                <th>Mã</th><th>Tên phụ tùng</th><th className="text-right">Cấp phát</th>
                <th className="text-right">Thực dùng</th><th className="text-right">Hoàn trả</th>
                <th className="text-right">Tồn sau</th><th>Trạng thái</th><th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              {issue.items.map((item) => (
                <tr key={item.partId}>
                  <td className="mono text-xs">{item.partId}</td>
                  <td>{item.partName}</td>
                  <td className="text-right">{item.issuedQuantity}</td>
                  <td className="text-right font-semibold">{item.actualUsedQuantity ?? "—"}</td>
                  <td className="text-right">{item.returnedQuantity ?? "—"}</td>
                  <td className="text-right">{item.stockAfter ?? "—"}</td>
                  <td>
                    {item.state === "DA_XAC_NHAN"
                      ? <Badge variant="completed" label="Đã xác nhận thực dùng" />
                      : <Badge variant="pending" label="Đã cấp phát — chờ KTV xác nhận" />}
                  </td>
                  <td>
                    {item.state === "CHO_XAC_NHAN" && canConfirmUsage && issue.repairOrderId !== null && (
                      <Button size="sm" variant="outline" onClick={() => openConfirm(issue, item)}>Xác nhận thực dùng</Button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </Card>
      ))}
      {data && <Pagination page={page} total={data.totalElements} perPage={PER_PAGE} onChange={setPage} />}

      <Modal open={confirming !== null} onClose={() => setConfirming(null)} title="Xác nhận số lượng thực dùng" width="max-w-md">
        {confirming && (
          <form className="space-y-4" onSubmit={submitConfirm}>
            <p className="text-sm text-slate-700">
              <strong>{confirming.item.partName}</strong> · đã cấp phát <strong>{confirming.item.issuedQuantity}</strong>
            </p>
            <Input label="Số lượng thực dùng *" type="number" min={0} max={confirming.item.issuedQuantity} value={actualUsed} onChange={(event) => setActualUsed(event.target.value)} autoFocus />
            {needsTechnicianId && (
              <Input label="Mã kỹ thuật viên xác nhận *" type="number" min={1} value={confirmTechnician} onChange={(event) => setConfirmTechnician(event.target.value)} />
            )}
            <p className="text-sm text-slate-600">
              {preview === null ? "Nhập số lượng từ 0 đến số đã cấp phát." : <>Hoàn trả: <strong>{preview}</strong> · Tồn kho giảm: <strong>{used}</strong></>}
            </p>
            {confirmError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{confirmError}</p>}
            <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
              <Button type="button" variant="outline" onClick={() => setConfirming(null)} disabled={confirmBusy}>Hủy</Button>
              <Button type="submit" disabled={confirmBusy}>{confirmBusy ? "Đang xác nhận..." : "Xác nhận"}</Button>
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
}
