import { useMemo } from "react";
import { Icons } from "./ui";
import { dichVu, formatCurrency } from "../mock/data";

const CATEGORY_ICONS: Record<string, React.ReactNode> = {
  "Bảo dưỡng": Icons.clipboard,
  "Sửa chữa": Icons.wrench,
  "Điện - điều hòa": Icons.settings,
  "Động cơ": Icons.car,
  "Lốp": Icons.truck,
  "Đồng sơn": Icons.inbox,
};

interface PublicServicesProps {
  onBook: () => void;
  onViewAll: () => void;
}

export default function PublicServices({ onBook, onViewAll }: PublicServicesProps) {
  const groups = useMemo(() => {
    const map = new Map<string, { count: number; minPrice: number; sample: string }>();
    for (const service of dichVu) {
      const key = service.LoaiDichVu ?? "Dịch vụ khác";
      const current = map.get(key);
      if (!current) map.set(key, { count: 1, minPrice: service.DonGia, sample: service.TenDichVu });
      else {
        current.count += 1;
        if (service.DonGia < current.minPrice) {
          current.minPrice = service.DonGia;
          current.sample = service.TenDichVu;
        }
      }
    }
    return [...map.entries()];
  }, []);

  return (
    <section aria-labelledby="homepage-services-title" className="public-reveal bg-brand-dark text-white">
      <div className="mx-auto w-full max-w-7xl px-4 py-16 sm:px-6 sm:py-24">
        <div className="flex flex-col gap-5 border-b border-white/12 pb-8 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="public-kicker text-accent">Dịch vụ tại gara</p>
            <h2 id="homepage-services-title" className="public-section-title mt-3 max-w-3xl text-white">Sửa chữa và bảo dưỡng theo từng hạng mục.</h2>
          </div>
          <button type="button" onClick={onViewAll} className="public-text-link text-white">Xem tất cả dịch vụ <span aria-hidden="true">{Icons.arrowRight}</span></button>
        </div>

        <div className="mt-8 grid grid-cols-1 gap-px overflow-hidden border border-white/12 bg-white/12 sm:grid-cols-2 lg:grid-cols-3">
          {groups.map(([category, info], index) => (
            <article key={category} className="public-service-card group relative flex min-h-[280px] flex-col bg-brand-dark p-6 sm:p-7">
              <div className="flex items-start justify-between">
                <span className="grid h-12 w-12 place-items-center border border-white/15 text-accent transition-all group-hover:border-accent group-hover:bg-accent group-hover:text-white" aria-hidden="true">{CATEGORY_ICONS[category] ?? Icons.wrench}</span>
                <span className="mono text-4xl font-black text-white/10 transition-all group-hover:text-accent/30" aria-hidden="true">{String(index + 1).padStart(2, "0")}</span>
              </div>
              <div className="mt-auto pt-10">
                <h3 className="text-xl font-black uppercase tracking-tight text-white">{category}</h3>
                <p className="mt-2 text-base leading-7 text-white/65">
                  {info.count > 1 ? `${info.sample} và ${info.count - 1} hạng mục liên quan.` : info.sample}
                </p>
                <div className="mt-5 flex items-end justify-between gap-4 border-t border-white/10 pt-4">
                  <p><span className="block text-[10px] font-bold uppercase tracking-wider text-white/35">Chi phí từ</span><span className="mono mt-1 block font-bold text-white">{formatCurrency(info.minPrice)}</span></p>
                  <button type="button" onClick={onBook} aria-label={`Đặt lịch ${category}`} className="min-h-11 border border-white/15 px-4 text-sm font-extrabold uppercase tracking-wider text-white transition-all hover:border-accent hover:bg-accent">Đặt lịch</button>
                </div>
              </div>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
