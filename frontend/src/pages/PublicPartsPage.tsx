import { useMemo, useState } from "react";
import PublicFooter from "../components/PublicFooter";
import PublicHeader, { type PublicPageKey } from "../components/PublicHeader";
import { Badge, Icons } from "../components/ui";
import { formatCurrency } from "../mock/data";
import { getInventoryStatus, phuTung, type InventoryStatus } from "../mock/schemaData";

const STATUS_FILTERS: { key: "all" | InventoryStatus; label: string }[] = [
  { key: "all", label: "Tất cả" },
  { key: "ok", label: "Còn hàng" },
  { key: "low", label: "Sắp hết" },
  { key: "out", label: "Hết hàng" },
];

interface PublicPartsPageProps {
  onNavigate: (page: PublicPageKey) => void;
  onLogin: () => void;
  onBook: () => void;
}

export default function PublicPartsPage({ onNavigate, onLogin, onBook }: PublicPartsPageProps) {
  const [status, setStatus] = useState<"all" | InventoryStatus>("all");
  const [search, setSearch] = useState("");

  const keyword = search.trim().toLowerCase();
  const filtered = useMemo(
    () =>
      phuTung.filter((part) => {
        const matchesStatus = status === "all" || getInventoryStatus(part) === status;
        const matchesKeyword =
          !keyword ||
          `${part.TenPhuTung} ${part.HangSanXuat ?? ""} ${part.MaPhuTung}`.toLowerCase().includes(keyword);
        return matchesStatus && matchesKeyword;
      }),
    [status, keyword],
  );

  return (
    <div className="min-h-screen bg-background">
      <PublicHeader active="parts" onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} />
      <main>
        <div className="border-b border-border bg-surface-subtle">
          <div className="mx-auto w-full max-w-6xl px-4 py-10 sm:py-14">
            <p className="text-xs font-bold uppercase tracking-widest text-accent">Phụ tùng</p>
            <h1 className="ui-page-title mt-2 text-3xl sm:text-4xl">Kho phụ tùng công khai</h1>
            <p className="ui-secondary-text mt-2 max-w-2xl text-sm">
              {phuTung.length} mã phụ tùng có nguồn gốc rõ ràng. Tình trạng tồn kho hiển thị thật —
              mã nào hết hàng, gara báo trước khi nhận xe.
            </p>
          </div>
        </div>

        <div className="mx-auto w-full max-w-6xl px-4 py-10">
          <div className="page-toolbar">
            <div className="flex flex-wrap gap-1.5" role="group" aria-label="Lọc theo tình trạng tồn kho">
              {STATUS_FILTERS.map((item) => (
                <button
                  key={item.key}
                  type="button"
                  onClick={() => setStatus(item.key)}
                  aria-pressed={status === item.key}
                  className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
                    status === item.key
                      ? "border-primary bg-primary text-primary-foreground"
                      : "border-border bg-surface text-muted-foreground hover:border-primary hover:text-primary"
                  }`}
                >
                  {item.label}
                </button>
              ))}
            </div>
            <div className="relative w-full sm:w-auto">
              <input
                type="search"
                aria-label="Tìm phụ tùng"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Tên, hãng, mã phụ tùng..."
                className="h-10 w-full rounded-md border border-border bg-surface pl-3 pr-3 text-sm text-foreground shadow-sm placeholder:text-muted-foreground transition-all hover:border-slate-400 focus:border-ring focus:ring-2 focus:ring-ring/15 sm:w-64"
              />
            </div>
          </div>

          {filtered.length > 0 ? (
            <ul className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {filtered.map((part) => {
                const partStatus = getInventoryStatus(part);
                return (
                  <li
                    key={part.MaPhuTung}
                    className="card-shadow flex flex-col rounded-lg border border-border bg-card p-5 text-card-foreground"
                  >
                    <div className="flex items-start justify-between gap-2">
                      <span className="flex h-11 w-11 items-center justify-center rounded-lg bg-primary-soft text-primary" aria-hidden="true">
                        {Icons.package}
                      </span>
                      <Badge variant={partStatus} />
                    </div>
                    <h2 className="ui-card-title mt-3 leading-snug">{part.TenPhuTung}</h2>
                    <p className="mt-1 text-xs text-muted-foreground">
                      Hãng: {part.HangSanXuat} · <span className="mono">{part.MaPhuTung}</span>
                    </p>
                    <div className="mt-3 flex items-center justify-between">
                      <p className="mono text-lg font-bold text-primary">{formatCurrency(part.DonGia)}</p>
                      <p className="text-xs text-muted-foreground">Tồn: {part.SoLuongTon}</p>
                    </div>
                    <button
                      type="button"
                      onClick={onBook}
                      disabled={partStatus === "out"}
                      className="mt-4 inline-flex min-h-10 items-center justify-center rounded-md bg-primary px-4 text-sm font-semibold text-primary-foreground transition-all hover:bg-primary-hover disabled:cursor-not-allowed disabled:opacity-50"
                      aria-label={`Đặt lịch thay ${part.TenPhuTung}`}
                    >
                      {partStatus === "out" ? "Hết hàng" : "Đặt lịch thay"}
                    </button>
                  </li>
                );
              })}
            </ul>
          ) : (
            <p className="py-16 text-center text-sm text-slate-400">Không tìm thấy phụ tùng phù hợp.</p>
          )}
        </div>
      </main>
      <PublicFooter onNavigate={onNavigate} onBook={onBook} />
    </div>
  );
}
