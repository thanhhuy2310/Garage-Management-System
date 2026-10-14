// TV3-TUAN8
import { FormEvent, useCallback, useEffect, useState } from "react";
import { detailedErrorMessage } from "../../api/errors";
import { sparePartsApi, type SparePart } from "../../api/spareParts";
import { warehouseApi, type CheckStatus, type CheckSummary, type InventoryCheck, type PageResult } from "../../api/warehouse";
import { Badge, Button, Card, Icons, Input, Modal, Pagination, TableContainer } from "../../components/ui";
import { formatDateTime, PER_PAGE, useWarehouseRole } from "./common";

const STATUS: Record<CheckStatus, { variant: "in_progress" | "pending" | "completed" | "rejected"; label: string }> = {
  DANG_KIEM_KE: { variant: "in_progress", label: "Đang kiểm kê" },
  CHO_PHE_DUYET: { variant: "pending", label: "Chờ quản lý phê duyệt" },
  DA_HOAN_TAT: { variant: "completed", label: "Hoàn tất" },
  DA_TU_CHOI: { variant: "rejected", label: "Bị từ chối" },
};

export default function ChecksTab({ refreshKey, onChanged }: { refreshKey: number; onChanged: () => void }) {
  const { canWrite, isManager } = useWarehouseRole();
  const [page, setPage] = useState(1);
  const [data, setData] = useState<PageResult<CheckSummary> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const [selected, setSelected] = useState<InventoryCheck | null>(null);
  const [drafts, setDrafts] = useState<Record<number, { actual: string; reason: string }>>({});
  const [busy, setBusy] = useState(false);

  const [showCreate, setShowCreate] = useState(false);
  const [parts, setParts] = useState<SparePart[]>([]);
  const [picked, setPicked] = useState<number[]>([]);
  const [note, setNote] = useState("");
  const [createError, setCreateError] = useState("");

  const [rejecting, setRejecting] = useState(false);
  const [rejectReason, setRejectReason] = useState("");
  const [rejectError, setRejectError] = useState("");

  const load = useCallback(() => {
    setLoading(true);
    setError("");
    warehouseApi.checks({ page: page - 1, size: PER_PAGE })
      .then(setData)
      .catch((loadError) => setError(detailedErrorMessage(loadError, "Không thể tải danh sách kiểm kê.")))
      .finally(() => setLoading(false));
  }, [page]);

  useEffect(load, [load, refreshKey]);

  const open = async (id: number) => {
    setError("");
    try {
      const check = await warehouseApi.check(id);
      setSelected(check);
      setDrafts({});
    } catch (loadError) {
      setError(detailedErrorMessage(loadError, "Không thể tải phiên kiểm kê."));
    }
  };

  const openCreate = () => {
    setShowCreate(true);
    setPicked([]);
    setNote("");
    setCreateError("");
    sparePartsApi.list({ page: 0, size: 100 })
      .then((result) => setParts(result.items))
      .catch((loadError) => setCreateError(detailedErrorMessage(loadError, "Không thể tải danh mục phụ tùng.")));
  };

  const submitCreate = async (event: FormEvent) => {
    event.preventDefault();
    if (picked.length === 0) return setCreateError("Vui lòng chọn ít nhất một phụ tùng để kiểm kê.");
    setBusy(true);
    try {
      const check = await warehouseApi.createCheck({ note: note.trim() || null, partIds: picked });
      setShowCreate(false);
      setSelected(check);
      setSuccess("Đã tạo phiên kiểm kê. Hãy nhập số lượng thực tế cho từng phụ tùng.");
      load();
    } catch (saveError) {
      setCreateError(detailedErrorMessage(saveError, "Không thể tạo phiên kiểm kê."));
    } finally {
      setBusy(false);
    }
  };

  const saveActual = async (partId: number) => {
    if (!selected) return;
    const draft = drafts[partId];
    const actual = Number(draft?.actual);
    if (!draft || draft.actual.trim() === "" || !Number.isInteger(actual) || actual < 0) {
      return setError("Số lượng thực tế phải là số nguyên không âm.");
    }
    setBusy(true);
    setError("");
    try {
      setSelected(await warehouseApi.setActual(selected.id, partId, { actualQuantity: actual, reason: draft.reason.trim() || null }));
      setDrafts((current) => { const next = { ...current }; delete next[partId]; return next; });
      load();
    } catch (saveError) {
      setError(detailedErrorMessage(saveError, "Không thể lưu số lượng thực tế."));
    } finally {
      setBusy(false);
    }
  };

  const approve = async () => {
    if (!selected) return;
    setBusy(true);
    setError("");
    try {
      setSelected(await warehouseApi.approveCheck(selected.id, null));
      setSuccess("Đã phê duyệt điều chỉnh. Tồn kho đã được cập nhật theo số lượng thực tế.");
      onChanged();
      load();
    } catch (approveError) {
      setError(detailedErrorMessage(approveError, "Không thể phê duyệt điều chỉnh."));
    } finally {
      setBusy(false);
    }
  };

  const reject = async (event: FormEvent) => {
    event.preventDefault();
    if (!selected) return;
    if (!rejectReason.trim()) return setRejectError("Vui lòng nhập lý do từ chối.");
    setBusy(true);
    try {
      setSelected(await warehouseApi.rejectCheck(selected.id, rejectReason.trim()));
      setRejecting(false);
      setRejectReason("");
      setSuccess("Đã từ chối điều chỉnh. Tồn kho không thay đổi.");
      load();
    } catch (rejectErr) {
      setRejectError(detailedErrorMessage(rejectErr, "Không thể từ chối điều chỉnh."));
    } finally {
      setBusy(false);
    }
  };

  const status = selected ? STATUS[selected.status] : null;

  return (
    <div className="space-y-4">
      <div className="page-toolbar">
        <div>
          <p className="font-semibold">Kiểm kê tồn kho</p>
          <p className="text-xs text-slate-500">Tồn kho chỉ thay đổi sau khi quản lý phê duyệt chênh lệch.</p>
        </div>
        {canWrite && <Button icon={Icons.plus} onClick={openCreate}>Tạo phiên kiểm kê</Button>}
      </div>

      {success && <p className="rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{success}</p>}
      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}

      <Card>
        <TableContainer>
          <table className="data-table w-full min-w-[640px]">
            <thead><tr><th>Mã</th><th>Ngày kiểm kê</th><th>Ghi chú</th><th className="text-right">Phụ tùng</th><th className="text-right">Chênh lệch</th><th>Trạng thái</th><th>Thao tác</th></tr></thead>
            <tbody>
              {loading && <tr><td colSpan={7} className="py-8 text-center text-sm text-muted-foreground">Đang tải...</td></tr>}
              {!loading && data?.items.length === 0 && <tr><td colSpan={7} className="py-8 text-center text-sm text-muted-foreground">Chưa có phiên kiểm kê.</td></tr>}
              {!loading && data?.items.map((check) => (
                <tr key={check.id}>
                  <td className="mono text-xs">{check.id}</td>
                  <td>{formatDateTime(check.checkDate)}</td>
                  <td>{check.note ?? "—"}</td>
                  <td className="text-right">{check.itemCount}</td>
                  <td className="text-right">{check.differenceCount}</td>
                  <td><Badge variant={STATUS[check.status].variant} label={STATUS[check.status].label} /></td>
                  <td><Button size="sm" variant="outline" onClick={() => void open(check.id)}>Xem</Button></td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableContainer>
        <div className="border-t border-border px-4 py-3">
          <Pagination page={page} total={data?.totalElements ?? 0} perPage={PER_PAGE} onChange={setPage} />
        </div>
      </Card>

      {selected && status && (
        <Card className="p-5">
          <div className="receipt-header">
            <div>
              <p className="font-semibold">Phiên kiểm kê #{selected.id}</p>
              <p className="text-xs text-slate-500">{formatDateTime(selected.checkDate)} · nhân viên {selected.createdBy}{selected.note ? ` · ${selected.note}` : ""}</p>
            </div>
            <Badge variant={status.variant} label={status.label} />
          </div>
          <TableContainer>
            <table className="data-table w-full min-w-[720px]">
              <thead>
                <tr><th>Mã</th><th>Tên phụ tùng</th><th className="text-right">Tồn hệ thống</th><th className="text-right">Tồn thực tế</th><th className="text-right">Chênh lệch</th><th>Nguyên nhân</th><th>Điều chỉnh</th></tr>
              </thead>
              <tbody>
                {selected.items.map((item) => {
                  const draft = drafts[item.partId] ?? { actual: item.actualQuantity === null ? "" : String(item.actualQuantity), reason: item.reason ?? "" };
                  const editable = selected.status === "DANG_KIEM_KE" && canWrite;
                  return (
                    <tr key={item.partId}>
                      <td className="mono text-xs">{item.partId}</td>
                      <td>{item.partName}</td>
                      <td className="text-right">{item.systemQuantity}</td>
                      <td className="text-right">
                        {editable
                          ? <Input type="number" min={0} value={draft.actual} onChange={(event) => setDrafts((c) => ({ ...c, [item.partId]: { ...draft, actual: event.target.value } }))} />
                          : (item.actualQuantity ?? "—")}
                      </td>
                      <td className={`text-right font-semibold ${item.difference ? "text-warning" : ""}`}>{item.difference === null ? "—" : item.difference > 0 ? `+${item.difference}` : item.difference}</td>
                      <td>
                        {editable
                          ? <Input value={draft.reason} maxLength={500} onChange={(event) => setDrafts((c) => ({ ...c, [item.partId]: { ...draft, reason: event.target.value } }))} />
                          : (item.reason ?? "—")}
                      </td>
                      <td>
                        {editable
                          ? <Button size="sm" variant="outline" disabled={busy} onClick={() => void saveActual(item.partId)}>Lưu</Button>
                          : item.adjustmentApproved ? <Badge variant="completed" label="Đã điều chỉnh" /> : "—"}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </TableContainer>

          {selected.status === "CHO_PHE_DUYET" && (
            <div className="mt-4 flex flex-col gap-3 rounded-lg border border-warning/20 bg-warning-soft p-4 text-sm text-warning sm:flex-row sm:items-center sm:justify-between">
              <span>Có chênh lệch: tồn kho giữ nguyên cho đến khi quản lý phê duyệt.</span>
              {isManager && (
                <span className="flex gap-2">
                  <Button size="sm" disabled={busy} onClick={() => void approve()}>Phê duyệt điều chỉnh</Button>
                  <Button size="sm" variant="outline" disabled={busy} onClick={() => { setRejecting(true); setRejectError(""); }}>Từ chối</Button>
                </span>
              )}
            </div>
          )}
          {selected.decisionReason && <p className="mt-3 text-xs text-slate-500">Lý do quyết định: {selected.decisionReason}</p>}
        </Card>
      )}

      <Modal open={showCreate} onClose={() => setShowCreate(false)} title="Tạo phiên kiểm kê" width="max-w-xl">
        <form className="space-y-4" onSubmit={submitCreate}>
          <Input label="Ghi chú" value={note} onChange={(event) => setNote(event.target.value)} maxLength={500} />
          <div className="max-h-64 space-y-1 overflow-y-auto rounded-md border border-border p-2">
            {parts.map((part) => (
              <label key={part.id} className="flex min-h-11 cursor-pointer items-center gap-2 rounded px-2 text-sm hover:bg-slate-50">
                <input
                  type="checkbox"
                  checked={picked.includes(part.id)}
                  onChange={(event) => setPicked((current) => event.target.checked ? [...current, part.id] : current.filter((id) => id !== part.id))}
                />
                <span className="mono text-xs text-slate-400">{part.id}</span> {part.name}
              </label>
            ))}
          </div>
          <p className="text-xs text-slate-500">Đã chọn {picked.length} phụ tùng. Hệ thống ghi nhận (chụp) tồn hiện tại làm tồn hệ thống.</p>
          {createError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{createError}</p>}
          <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
            <Button type="button" variant="outline" onClick={() => setShowCreate(false)} disabled={busy}>Hủy</Button>
            <Button type="submit" disabled={busy}>{busy ? "Đang tạo..." : "Tạo phiên"}</Button>
          </div>
        </form>
      </Modal>

      <Modal open={rejecting} onClose={() => setRejecting(false)} title="Từ chối điều chỉnh" width="max-w-md">
        <form className="space-y-4" onSubmit={reject}>
          <Input label="Lý do từ chối *" value={rejectReason} onChange={(event) => setRejectReason(event.target.value)} maxLength={500} autoFocus />
          {rejectError && <p className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger" role="alert">{rejectError}</p>}
          <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
            <Button type="button" variant="outline" onClick={() => setRejecting(false)} disabled={busy}>Hủy</Button>
            <Button type="submit" disabled={busy}>Từ chối</Button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
