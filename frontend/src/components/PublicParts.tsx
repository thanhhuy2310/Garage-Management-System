import { useMemo } from "react";
import { Badge, Icons } from "./ui";
import { formatCurrency } from "../mock/data";
import { getInventoryStatus, phuTung } from "../mock/schemaData";

interface PublicPartsProps {
  onBook: () => void;
  onViewAll: () => void;
}

export default function PublicParts({ onBook, onViewAll }: PublicPartsProps) {
  const featured = useMemo(
    () => phuTung.filter((part) => getInventoryStatus(part) === "ok").slice(0, 4),
    [],
  );

  return (
    <section aria-labelledby="homepage-parts-title" className="border-y border-border bg-surface-subtle">
      <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:py-20">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-bold uppercase tracking-widest text-accent">Phụ tùng nổi bật</p>
            <h2 id="homepage-parts-title" className="ui-page-title mt-2">
              Phụ tùng chính hãng, sẵn trong kho
            </h2>
            <p className="ui-secondary-text mt-2 max-w-xl text-sm">
              Chỉ dùng phụ tùng có nguồn gốc, tồn kho quản lý theo từng mã — hết hàng là báo ngay, không để xe chờ.
            </p>
          </div>
          <button
            type="button"
            onClick={onViewAll}
            className="inline-flex min-h-10 flex-shrink-0 items-center gap-1 rounded-md border border-border bg-surface px-4 text-sm font-semibold text-primary transition-all hover:bg-surface-subtle"
          >
            Xem tất cả phụ tùng
            <span aria-hidden="true">→</span>
          </button>
        </div>

        <div className="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          {featured.map((part) => (
            <article
              key={part.MaPhuTung}
              className="card-shadow flex flex-col rounded-lg border border-border bg-card p-5 text-card-foreground transition-all hover:-translate-y-0.5 hover:shadow-md"
            >
              <div className="flex items-start justify-between gap-2">
                <span className="flex h-11 w-11 items-center justify-center rounded-lg bg-primary-soft text-primary" aria-hidden="true">
                  {Icons.package}
                </span>
                <Badge variant="ok" />
              </div>
              <h3 className="ui-card-title mt-4 leading-snug">{part.TenPhuTung}</h3>
              <p className="mt-1 text-xs text-muted-foreground">
                Hãng: {part.HangSanXuat} · <span className="mono">{part.MaPhuTung}</span>
              </p>
              <p className="mono mt-3 text-lg font-bold text-primary">{formatCurrency(part.DonGia)}</p>
              <button
                type="button"
                onClick={onBook}
                className="mt-4 inline-flex min-h-10 items-center justify-center rounded-md border border-border bg-surface px-4 text-sm font-semibold text-foreground transition-all hover:border-primary hover:text-primary"
                aria-label={`Đặt lịch thay ${part.TenPhuTung}`}
              >
                Đặt lịch thay
              </button>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
