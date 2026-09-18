import { useMemo } from "react";
import { Icons } from "./ui";
import { dichVu, formatCurrency } from "../mock/data";

const CATEGORY_META: Record<string, { icon: React.ReactNode; tint: string }> = {
  "Bảo dưỡng": { icon: Icons.clipboard, tint: "bg-info-soft text-info" },
  "Sửa chữa": { icon: Icons.wrench, tint: "bg-primary-soft text-primary" },
  "Điện - điều hòa": { icon: Icons.settings, tint: "bg-warning-soft text-warning" },
  "Động cơ": { icon: Icons.car, tint: "bg-danger-soft text-danger" },
  "Lốp": { icon: Icons.truck, tint: "bg-success-soft text-success" },
  "Đồng sơn": { icon: Icons.inbox, tint: "bg-info-soft text-info" },
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
      if (!current) {
        map.set(key, { count: 1, minPrice: service.DonGia, sample: service.TenDichVu });
      } else {
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
    <section aria-labelledby="homepage-services-title" className="bg-background">
      <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:py-20">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-bold uppercase tracking-widest text-accent">Dịch vụ nổi bật</p>
            <h2 id="homepage-services-title" className="ui-page-title mt-2">
              Mọi bệnh của xe, đều có thợ giỏi lo
            </h2>
            <p className="ui-secondary-text mt-2 max-w-xl text-sm">
              Giá công khai theo từng hạng mục, báo giá xác nhận trước khi sửa — không phát sinh ngoài ý muốn.
            </p>
          </div>
          <button
            type="button"
            onClick={onViewAll}
            className="inline-flex min-h-10 flex-shrink-0 items-center gap-1 rounded-md border border-border bg-surface px-4 text-sm font-semibold text-primary transition-all hover:bg-surface-subtle"
          >
            Xem tất cả dịch vụ
            <span aria-hidden="true">→</span>
          </button>
        </div>

        <div className="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {groups.map(([category, info]) => {
            const meta = CATEGORY_META[category] ?? { icon: Icons.wrench, tint: "bg-muted text-muted-foreground" };
            return (
              <article
                key={category}
                className="card-shadow group flex flex-col rounded-lg border border-border bg-card p-5 text-card-foreground transition-all hover:-translate-y-0.5 hover:shadow-md"
              >
                <div className={`flex h-11 w-11 items-center justify-center rounded-lg ${meta.tint}`} aria-hidden="true">
                  {meta.icon}
                </div>
                <h3 className="ui-card-title mt-4">{category}</h3>
                <p className="mt-1 text-sm text-muted-foreground">
                  {info.count} hạng mục · chỉ từ <span className="mono font-bold text-primary">{formatCurrency(info.minPrice)}</span>
                </p>
                <p className="mt-2 text-[13px] text-slate-500">Tiêu biểu: {info.sample}</p>
                <button
                  type="button"
                  onClick={onBook}
                  className="mt-4 inline-flex min-h-10 items-center justify-center rounded-md bg-primary px-4 text-sm font-semibold text-primary-foreground transition-all hover:bg-primary-hover"
                  aria-label={`Đặt lịch ${category}`}
                >
                  Đặt lịch {category.toLowerCase()}
                </button>
              </article>
            );
          })}
        </div>
      </div>
    </section>
  );
}
