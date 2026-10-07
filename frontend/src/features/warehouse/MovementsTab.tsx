// TV3-TUAN8
import { useEffect, useState } from "react";
import { detailedErrorMessage } from "../../api/errors";
import { inventoryApi, type MovementType, type PageResult, type StockMovement } from "../../api/warehouse";
import { Badge, Card, Pagination, Select, TableContainer } from "../../components/ui";
import { formatDateTime, PER_PAGE } from "./common";

const TYPE_BADGE = { NHAP: "completed", XUAT: "in_progress", KIEM_KE: "pending" } as const;
const TYPE_LABEL: Record<MovementType, string> = { NHAP: "Nhập", XUAT: "Xuất", KIEM_KE: "Kiểm kê" };

export default function MovementsTab({ refreshKey }: { refreshKey: number }) {
  const [type, setType] = useState<MovementType | "ALL">("ALL");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<PageResult<StockMovement> | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  useEffect(() => setPage(1), [type]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");
    inventoryApi.movements({ page: page - 1, size: PER_PAGE, type })
      .then((result) => { if (!cancelled) setData(result); })
      .catch((loadError) => { if (!cancelled) setError(detailedErrorMessage(loadError, "Không thể tải lịch sử biến động kho.")); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [page, type, refreshKey]);

  return (
    <div className="space-y-4">
      <div className="sm:w-60">
        <Select
          value={type}
          onChange={(event) => setType(event.target.value as MovementType | "ALL")}
          options={[
            { value: "ALL", label: "Tất cả loại biến động" },
            { value: "NHAP", label: "Nhập kho" },
            { value: "XUAT", label: "Xuất (thực dùng)" },
            { value: "KIEM_KE", label: "Kiểm kê" },
          ]}
        />
      </div>
      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      <Card>
        <TableContainer>
          <table className="data-table w-full min-w-[860px]">
            <thead>
              <tr>
                <th>Mã</th><th>Thời gian</th><th>Phụ tùng</th><th>Loại</th>
                <th className="text-right">Số lượng</th><th className="text-right">Trước</th><th className="text-right">Sau</th>
                <th>Chứng từ</th><th>Ghi chú</th>
              </tr>
            </thead>
            <tbody>
              {loading && <tr><td colSpan={9} className="py-8 text-center text-sm text-muted-foreground">Đang tải...</td></tr>}
              {!loading && data?.items.length === 0 && !error && <tr><td colSpan={9} className="py-8 text-center text-sm text-muted-foreground">Chưa có biến động kho.</td></tr>}
              {!loading && data?.items.map((movement) => (
                <tr key={movement.id}>
                  <td className="mono text-xs">{movement.id}</td>
                  <td>{formatDateTime(movement.time)}</td>
                  <td>{movement.partId} · {movement.partName}</td>
                  <td><Badge variant={TYPE_BADGE[movement.type]} label={TYPE_LABEL[movement.type]} /></td>
                  <td className="text-right font-semibold">{movement.quantity}</td>
                  <td className="text-right">{movement.quantityBefore ?? "—"}</td>
                  <td className="text-right">{movement.quantityAfter ?? "—"}</td>
                  <td className="mono text-xs">
                    {movement.receiptId ? `Nhập #${movement.receiptId}` : movement.issueId ? `Xuất #${movement.issueId}` : "—"}
                  </td>
                  <td className="text-sm text-slate-600">{movement.note ?? "—"}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableContainer>
        <div className="border-t border-border px-4 py-3">
          <Pagination page={page} total={data?.totalElements ?? 0} perPage={PER_PAGE} onChange={setPage} />
        </div>
      </Card>
    </div>
  );
}
