import { useMemo } from "react";
import { Badge, Icons } from "./ui";
import { formatCurrency } from "../mock/data";
import { getInventoryStatus, phuTung } from "../mock/schemaData";

interface PublicPartsProps { onBook: () => void; onViewAll: () => void; }

export default function PublicParts({ onBook, onViewAll }: PublicPartsProps) {
  const featured = useMemo(() => phuTung.filter((part) => getInventoryStatus(part) === "ok").slice(0, 4), []);

  return (
    <section aria-labelledby="homepage-parts-title" className="public-reveal bg-surface">
      <div className="mx-auto w-full max-w-7xl px-4 py-16 sm:px-6 sm:py-24">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <div><p className="public-kicker text-accent">Tra cứu phụ tùng</p><h2 id="homepage-parts-title" className="public-section-title mt-3 text-foreground">Phụ tùng đang có trong kho.</h2></div>
          <button type="button" onClick={onViewAll} className="public-text-link text-primary">Xem kho phụ tùng <span aria-hidden="true">{Icons.arrowRight}</span></button>
        </div>

        <div className="mt-9 grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-4">
          {featured.map((part, index) => (
            <article key={part.MaPhuTung} className="interactive-card group border border-border bg-white hover:border-primary hover:shadow-lg">
              <div className="relative grid h-44 place-items-center overflow-hidden bg-brand-dark">
                <div className="public-hero-grid pointer-events-none absolute inset-0 opacity-50" aria-hidden="true" />
                <span className="relative grid h-16 w-16 place-items-center border border-white/15 text-accent transition-transform group-hover:scale-110" aria-hidden="true">{Icons.package}</span>
                <span className="mono absolute left-4 top-4 text-xs font-bold text-white/35">{String(index + 1).padStart(2, "0")}</span>
                <span className="absolute right-4 top-4"><Badge variant="ok" /></span>
              </div>
              <div className="p-5">
                <p className="text-[10px] font-bold uppercase tracking-[0.14em] text-accent">{part.HangSanXuat || "Phụ tùng gara"} · {part.MaPhuTung}</p>
                <h3 className="mt-2 min-h-12 text-base font-extrabold leading-6 text-foreground">{part.TenPhuTung}</h3>
                <p className="mono mt-4 text-lg font-black text-primary">{formatCurrency(part.DonGia)}</p>
                <button type="button" onClick={onBook} aria-label={`Đặt lịch thay ${part.TenPhuTung}`} className="mt-5 flex min-h-11 w-full items-center justify-center border border-border text-xs font-extrabold uppercase tracking-wider text-foreground transition-all hover:border-primary hover:bg-primary hover:text-white">Đặt lịch thay</button>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
