// TV3-TUAN8
import { useEffect, useState } from "react";
import { detailedErrorMessage } from "../../api/errors";
import { inventoryApi, type InventoryPage, type StockStatus } from "../../api/warehouse";
import { Badge, Card, Icons, Pagination, SearchBox, Select, TableContainer } from "../../components/ui";
import { formatPrice, PER_PAGE, useDebounced } from "./common";

const STATUS_BADGE = { CON_HANG: "ok", SAP_HET: "low", HET_HANG: "out" } as const;

export default function StockTab({ refreshKey }: { refreshKey: number }) {
  const [search, setSearch] = useState("");
  const [status, setStatus] = useState<StockStatus | "ALL">("ALL");
  const [page, setPage] = useState(1);
  const [data, setData] = useState<InventoryPage | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const keyword = useDebounced(search.trim());

  useEffect(() => setPage(1), [keyword, status]);

  useEffect(() => {
    let cancelled = false;
    setLoading(true);
    setError("");
    inventoryApi
      .stock({ page: page - 1, size: PER_PAGE, search: keyword || undefined, status })
      .then((result) => { if (!cancelled) setData(result); })
      .catch((loadError) => { if (!cancelled) setError(detailedErrorMessage(loadError, "Không thể tải tồn kho.")); })
      .finally(() => { if (!cancelled) setLoading(false); });
    return () => { cancelled = true; };
  }, [page, keyword, status, refreshKey]);

  return (
    <div className="space-y-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
        <SearchBox value={search} onChange={setSearch} placeholder="Mã, tên hoặc hãng phụ tùng..." />
        <Select
          value={status}
          onChange={(event) => setStatus(event.target.value as StockStatus | "ALL")}
          options={[
            { value: "ALL", label: "Tất cả trạng thái" },
            { value: "CON_HANG", label: "Còn hàng" },
            { value: "SAP_HET", label: "Sắp hết" },
            { value: "HET_HANG", label: "Hết hàng" },
          ]}
        />
      </div>

      {error && <p className="rounded-md bg-danger-soft px-4 py-3 text-sm text-danger" role="alert">{error}</p>}
      {data && data.lowStockCount > 0 && (
        <div className="flex items-center gap-3 rounded-lg border border-warning/20 bg-warning-soft p-4 text-sm text-warning">
          <span>{Icons.alertTriangle}</span>
          <span><strong>{data.lowStockCount} mặt hàng</strong> đang ở hoặc dưới mức tồn tối thiểu.</span>
        </div>
      )}

      <Card>
        <TableContainer>
          <table className="data-table w-full min-w-[820px]">
            <thead>
              <tr>
                <th>Mã</th><th>Tên phụ tùng</th><th>Hãng</th><th>Kho</th>
                <th className="text-right">Đơn giá</th><th className="text-right">Tồn</th>
                <th className="text-right">Mức tối thiểu</th><th>Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              {loading && <tr><td colSpan={8} className="py-10 text-center text-sm text-muted-foreground">Đang tải tồn kho...</td></tr>}
              {!loading && data?.items.length === 0 && !error && (
                <tr><td colSpan={8} className="py-10 text-center text-sm text-muted-foreground">Không có phụ tùng phù hợp.</td></tr>
              )}
              {!loading && data?.items.map((item) => (
                <tr key={item.id}>
                  <td className="mono text-xs">{item.id}</td>
                  <td className="font-medium">{item.name}</td>
                  <td>{item.manufacturer ?? "—"}</td>
                  <td className="mono text-xs">{item.warehouseId}</td>
                  <td className="mono text-right text-sm">{formatPrice(item.unitPrice)}</td>
                  <td className="mono text-right font-bold">{item.stockQuantity}</td>
                  <td className="mono text-right text-slate-500">{item.minStockLevel}</td>
                  <td><Badge variant={STATUS_BADGE[item.stockStatus]} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        </TableContainer>
        <div className="flex flex-col gap-3 border-t border-border px-4 py-3 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-xs text-muted-foreground">{data?.totalElements ?? 0} phụ tùng</p>
          <Pagination page={page} total={data?.totalElements ?? 0} perPage={PER_PAGE} onChange={setPage} />
        </div>
      </Card>
    </div>
  );
}
