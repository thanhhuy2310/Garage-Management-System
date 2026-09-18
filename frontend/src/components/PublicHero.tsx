interface PublicHeroProps {
  onBook: () => void;
  onViewServices: () => void;
}

const HIGHLIGHTS = ["Báo giá minh bạch", "Kỹ thuật viên kinh nghiệm", "Phụ tùng chính hãng"];

const STATS = [
  { value: "10+", label: "Năm kinh nghiệm" },
  { value: "5.000+", label: "Lượt xe phục vụ" },
  { value: "98%", label: "Khách hài lòng" },
];

export default function PublicHero({ onBook, onViewServices }: PublicHeroProps) {
  return (
    <section aria-label="Giới thiệu gara" className="relative overflow-hidden text-white" style={{ background: "var(--gradient-brand)" }}>
      {/* Decorative backdrop: diagonal lines + amber glow, CSS only */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0 opacity-20"
        style={{
          backgroundImage: "repeating-linear-gradient(-45deg, rgba(255,255,255,0.14) 0 2px, transparent 2px 22px)",
        }}
      />
      <div aria-hidden="true" className="pointer-events-none absolute -right-24 -top-24 h-96 w-96 rounded-full bg-accent opacity-25 blur-3xl" />
      <div aria-hidden="true" className="pointer-events-none absolute -bottom-32 -left-16 h-80 w-80 rounded-full bg-info opacity-20 blur-3xl" />

      <div className="relative mx-auto grid w-full max-w-6xl items-center gap-10 px-4 py-14 sm:py-20 lg:grid-cols-2 lg:py-24">
        {/* Copy */}
        <div>
          <p className="inline-flex items-center gap-2 rounded-full border border-white/20 bg-white/10 px-3 py-1 text-xs font-semibold tracking-wide text-white/90">
            <span className="h-1.5 w-1.5 rounded-full bg-accent" aria-hidden="true" />
            GARA SỬA CHỮA &amp; BẢO DƯỠNG Ô TÔ
          </p>
          <h1 className="mt-4 text-4xl font-extrabold leading-[1.1] tracking-tight sm:text-5xl xl:text-6xl">
            Chăm xe chuẩn hãng,
            <br />
            <span className="text-amber-400">vững mọi hành trình.</span>
          </h1>
          <p className="mt-4 max-w-xl text-[15px] leading-relaxed text-white/75">
            Đặt lịch online, theo dõi tiến độ sửa chữa theo thời gian thực và nhận báo giá minh bạch
            trước khi làm — tất cả trong một hệ thống quản lý gara chuyên nghiệp.
          </p>
          <ul className="mt-5 flex flex-wrap gap-2" aria-label="Cam kết dịch vụ">
            {HIGHLIGHTS.map((item) => (
              <li
                key={item}
                className="inline-flex items-center gap-1.5 rounded-full border border-white/15 bg-white/10 px-3 py-1.5 text-[13px] font-medium text-white/90"
              >
                <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="#fbbf24" strokeWidth="2.5" aria-hidden="true">
                  <path d="m20 6-11 11-5-5" />
                </svg>
                {item}
              </li>
            ))}
          </ul>
          <div className="mt-7 flex flex-col gap-3 sm:flex-row">
            <button
              type="button"
              onClick={onBook}
              className="inline-flex min-h-12 items-center justify-center rounded-md border border-accent bg-accent px-6 text-[15px] font-bold text-accent-foreground transition-all hover:brightness-110"
            >
              Đặt lịch ngay
            </button>
            <button
              type="button"
              onClick={onViewServices}
              className="inline-flex min-h-12 items-center justify-center rounded-md border border-white/30 bg-white/10 px-6 text-[15px] font-semibold text-white transition-all hover:bg-white/20"
            >
              Xem dịch vụ
            </button>
          </div>
          <dl className="mt-9 grid max-w-md grid-cols-3 gap-4 border-t border-white/15 pt-6">
            {STATS.map((stat) => (
              <div key={stat.label} className="flex flex-col">
                <dt className="order-2 mt-1 text-xs leading-snug text-white/60">{stat.label}</dt>
                <dd className="order-1 m-0 text-2xl font-extrabold tracking-tight text-white">{stat.value}</dd>
              </div>
            ))}
          </dl>
        </div>

        {/* Visual: live repair-tracking card */}
        <div className="relative hidden justify-end lg:flex" aria-hidden="true">
          <div className="w-full max-w-sm rounded-2xl border border-white/15 bg-white p-5 text-slate-800 shadow-2xl">
            <div className="flex items-center justify-between">
              <p className="text-sm font-bold text-primary">Theo dõi sửa chữa</p>
              <span className="rounded-full bg-info-soft px-2.5 py-0.5 text-xs font-semibold text-info">Đang thực hiện</span>
            </div>
            <p className="mono mt-3 text-2xl font-bold tracking-tight text-primary">51G-123.45</p>
            <p className="mt-0.5 text-xs text-slate-500">Toyota Vios 2021 · Bảo dưỡng 40.000 km</p>
            <div className="mt-4 space-y-2.5">
              {[
                { label: "Tiếp nhận & kiểm tra", done: true },
                { label: "Báo giá đã xác nhận", done: true },
                { label: "Đang sửa chữa", done: false, active: true },
                { label: "Bàn giao xe", done: false },
              ].map((step) => (
                <div key={step.label} className="flex items-center gap-2.5 text-[13px]">
                  <span
                    className={`flex h-5 w-5 flex-shrink-0 items-center justify-center rounded-full text-[10px] font-bold text-white ${
                      step.done ? "bg-success" : step.active ? "bg-primary" : "bg-slate-200 text-slate-400"
                    }`}
                  >
                    {step.done ? "✓" : step.active ? "●" : "○"}
                  </span>
                  <span className={step.done || step.active ? "font-semibold text-slate-700" : "text-slate-400"}>{step.label}</span>
                </div>
              ))}
            </div>
            <div className="mt-4 h-2 overflow-hidden rounded-full bg-slate-100">
              <div className="h-full w-2/3 rounded-full bg-gradient-to-r from-info to-primary" />
            </div>
            <div className="mt-3 flex items-center justify-between rounded-lg bg-primary-soft px-3 py-2.5">
              <span className="text-xs font-medium text-muted-foreground">Dự kiến bàn giao</span>
              <span className="text-sm font-bold text-primary">Hôm nay · 16:30</span>
            </div>
          </div>
        </div>
      </div>

      {/* Bottom curve into page background */}
      <svg aria-hidden="true" viewBox="0 0 1440 48" preserveAspectRatio="none" className="relative block h-8 w-full sm:h-12">
        <path d="M0 48h1440V24C1200 44 960 48 720 40 480 32 240 24 0 36v12z" fill="var(--background)" />
      </svg>
    </section>
  );
}
