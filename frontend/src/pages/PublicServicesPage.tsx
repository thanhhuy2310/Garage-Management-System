import { useMemo, useState } from "react";
import PublicFooter from "../components/PublicFooter";
import PublicHeader, { type PublicPageKey } from "../components/PublicHeader";
import { dichVu, formatCurrency } from "../mock/data";

interface PublicServicesPageProps {
  onNavigate: (page: PublicPageKey) => void;
  onLogin: () => void;
  onBook: () => void;
}

export default function PublicServicesPage({ onNavigate, onLogin, onBook }: PublicServicesPageProps) {
  const [category, setCategory] = useState("Tất cả");
  const [search, setSearch] = useState("");

  const categories = useMemo(
    () => ["Tất cả", ...Array.from(new Set(dichVu.map((service) => service.LoaiDichVu).filter(Boolean))) as string[]],
    [],
  );

  const keyword = search.trim().toLowerCase();
  const filtered = dichVu.filter(
    (service) =>
      (category === "Tất cả" || service.LoaiDichVu === category) &&
      (!keyword || service.TenDichVu.toLowerCase().includes(keyword)),
  );

  return (
    <div className="min-h-screen bg-background">
      <PublicHeader active="services" onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} />
      <main>
        {/* Page hero */}
        <div className="border-b border-border bg-surface-subtle">
          <div className="mx-auto w-full max-w-6xl px-4 py-10 sm:py-14">
            <p className="text-xs font-bold uppercase tracking-widest text-accent">Dịch vụ</p>
            <h1 className="ui-page-title mt-2 text-3xl sm:text-4xl">Bảng dịch vụ &amp; giá công khai</h1>
            <p className="ui-secondary-text mt-2 max-w-2xl text-sm">
              {dichVu.length} hạng mục thuộc {categories.length - 1} nhóm dịch vụ. Giá niêm yết là giá tham khảo —
              gara báo giá xác nhận chính xác theo tình trạng xe trước khi làm.
            </p>
          </div>
        </div>

        <div className="mx-auto w-full max-w-6xl px-4 py-10">
          {/* Filter + search */}
          <div className="page-toolbar">
            <div className="flex flex-wrap gap-1.5" role="group" aria-label="Lọc theo nhóm dịch vụ">
              {categories.map((item) => (
                <button
                  key={item}
                  type="button"
                  onClick={() => setCategory(item)}
                  aria-pressed={category === item}
                  className={`rounded-full border px-3 py-1.5 text-xs font-medium transition-all ${
                    category === item
                      ? "border-primary bg-primary text-primary-foreground"
                      : "border-border bg-surface text-muted-foreground hover:border-primary hover:text-primary"
                  }`}
                >
                  {item}
                </button>
              ))}
            </div>
            <div className="relative w-full sm:w-auto">
              <input
                type="search"
                aria-label="Tìm dịch vụ"
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Tìm tên dịch vụ..."
                className="h-10 w-full rounded-md border border-border bg-surface pl-3 pr-3 text-sm text-foreground shadow-sm placeholder:text-muted-foreground transition-all hover:border-slate-400 focus:border-ring focus:ring-2 focus:ring-ring/15 sm:w-64"
              />
            </div>
          </div>

          {/* Service list */}
          {filtered.length > 0 ? (
            <ul className="mt-6 grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
              {filtered.map((service) => (
                <li
                  key={service.MaDichVu}
                  className="card-shadow flex flex-col rounded-lg border border-border bg-card p-5 text-card-foreground"
                >
                  <div className="flex items-center justify-between gap-2">
                    <span className="rounded-full bg-primary-soft px-2 py-1 text-xs font-medium text-primary">
                      {service.LoaiDichVu || "Chưa phân loại"}
                    </span>
                    <span className="mono text-xs text-slate-400">{service.MaDichVu}</span>
                  </div>
                  <h2 className="ui-card-title mt-3 leading-snug">{service.TenDichVu}</h2>
                  <p className="mt-1 line-clamp-2 text-[13px] text-muted-foreground">{service.MoTa || "Liên hệ gara để được tư vấn chi tiết."}</p>
                  <p className="mono mt-3 text-lg font-bold text-primary">{formatCurrency(service.DonGia)}</p>
                  <button
                    type="button"
                    onClick={onBook}
                    className="mt-4 inline-flex min-h-10 items-center justify-center rounded-md bg-primary px-4 text-sm font-semibold text-primary-foreground transition-all hover:bg-primary-hover"
                    aria-label={`Đặt lịch ${service.TenDichVu}`}
                  >
                    Đặt lịch dịch vụ này
                  </button>
                </li>
              ))}
            </ul>
          ) : (
            <p className="py-16 text-center text-sm text-slate-400">Không tìm thấy dịch vụ phù hợp.</p>
          )}

          <p className="mt-8 rounded-lg border border-info/20 bg-info-soft p-4 text-[13px] leading-relaxed text-info">
            Giá trên là giá tham khảo theo từng hạng mục. Sau khi kiểm tra xe, gara lập báo giá chi tiết và chỉ
            thực hiện khi khách hàng xác nhận.
          </p>
        </div>
      </main>
      <PublicFooter onNavigate={onNavigate} onBook={onBook} />
    </div>
  );
}
