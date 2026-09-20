import { dichVu } from "../mock/data";
import { phuTung } from "../mock/schemaData";
import { Icons } from "./ui";

interface PublicHeroProps {
  onBook: () => void;
  onViewServices: () => void;
}

const STATS = [
  { value: String(dichVu.length), label: "Hạng mục dịch vụ" },
  { value: String(phuTung.length), label: "Mã phụ tùng" },
  { value: "6", label: "Bước xử lý" },
];

export default function PublicHero({ onBook, onViewServices }: PublicHeroProps) {
  return (
    <section aria-label="Giới thiệu gara" className="public-hero relative isolate flex min-h-[690px] items-center overflow-hidden text-white lg:min-h-[760px]">
      <div className="public-hero-grid pointer-events-none absolute inset-0" aria-hidden="true" />
      <div className="relative mx-auto w-full max-w-7xl px-4 py-20 sm:px-6 lg:py-28">
        <div className="max-w-3xl">
          <p className="public-kicker text-accent">Gara Ô Tô Thành Công</p>
          <h1 className="public-display mt-5 max-w-[820px] text-white">
            Bảo dưỡng đúng lịch.
            <span className="mt-3 block text-accent sm:mt-4">An tâm khi lăn bánh.</span>
          </h1>
          <p className="mt-6 max-w-xl text-base leading-7 text-white/75 sm:text-lg">
            Đặt lịch, kiểm tra, duyệt báo giá và theo dõi quá trình sửa chữa ngay trên hệ thống.
          </p>

          <div className="mt-8 flex flex-col gap-3 sm:flex-row">
            <button type="button" onClick={onBook} className="public-primary-button">Đặt lịch sửa chữa <span aria-hidden="true">{Icons.arrowRight}</span></button>
            <button type="button" onClick={onViewServices} className="public-secondary-button">Xem bảng dịch vụ</button>
          </div>

          <dl className="mt-12 grid max-w-2xl grid-cols-3 border-y border-white/15 bg-brand-dark/45 backdrop-blur-sm">
            {STATS.map((stat) => (
              <div key={stat.label} className="border-r border-white/15 px-3 py-5 last:border-r-0 sm:px-6">
                <dt className="mt-1 text-[10px] font-bold uppercase tracking-wider text-white/55 sm:text-xs">{stat.label}</dt>
                <dd className="m-0 text-2xl font-black tracking-tight text-white sm:text-3xl">{stat.value}</dd>
              </div>
            ))}
          </dl>
        </div>
      </div>

      <div className="absolute bottom-0 right-0 hidden items-center gap-4 bg-accent px-7 py-5 text-white lg:flex">
        <span className="grid h-11 w-11 place-items-center border border-white/30" aria-hidden="true">{Icons.clock}</span>
        <div><p className="text-[10px] font-bold uppercase tracking-[0.16em] text-white/70">Giờ làm việc</p><p className="mt-1 font-extrabold">T2 – T7 · 07:30 – 17:30</p></div>
      </div>
    </section>
  );
}
