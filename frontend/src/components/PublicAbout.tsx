import { Icons } from "./ui";
import { GARAGE_NAME } from "../data";
import { dichVu } from "../mock/data";

const STRENGTHS = [
  {
    title: "Minh bạch từng hạng mục",
    description: "Báo giá chi tiết theo DichVu — khách duyệt mới làm, không phát sinh ngoài ý muốn.",
    icon: Icons.fileText,
    tint: "bg-info-soft text-info",
  },
  {
    title: "Theo dõi tiến độ realtime",
    description: "Từ tiếp nhận, kiểm tra đến bàn giao — mọi trạng thái cập nhật trên hệ thống.",
    icon: Icons.history,
    tint: "bg-success-soft text-success",
  },
  {
    title: "Kho phụ tùng quản lý chặt",
    description: "Nhập — xuất — kiểm kê rõ ràng, chỉ dùng phụ tùng có nguồn gốc trong kho.",
    icon: Icons.package,
    tint: "bg-warning-soft text-warning",
  },
];

interface PublicAboutProps {
  onNavigateAbout: () => void;
}

export default function PublicAbout({ onNavigateAbout }: PublicAboutProps) {
  return (
    <section aria-labelledby="homepage-about-title" className="bg-background">
      <div className="mx-auto grid w-full max-w-6xl items-center gap-10 px-4 py-14 sm:py-20 lg:grid-cols-2">
        {/* Visual: workshop card, CSS only */}
        <div className="relative" aria-hidden="true">
          <div className="rounded-2xl p-6 text-white sm:p-8" style={{ background: "var(--gradient-brand)" }}>
            <p className="text-xs font-bold uppercase tracking-widest text-white/60">Xưởng dịch vụ</p>
            <p className="mt-2 text-2xl font-extrabold tracking-tight sm:text-3xl">
              {GARAGE_NAME}
            </p>
            <div className="mt-6 grid grid-cols-2 gap-3">
              <div className="rounded-xl border border-white/15 bg-white/10 p-4">
                <p className="text-3xl font-extrabold text-amber-400">{dichVu.length}</p>
                <p className="mt-1 text-xs text-white/70">Hạng mục dịch vụ</p>
              </div>
              <div className="rounded-xl border border-white/15 bg-white/10 p-4">
                <p className="text-3xl font-extrabold text-amber-400">6</p>
                <p className="mt-1 text-xs text-white/70">Bước quy trình chuẩn</p>
              </div>
              <div className="col-span-2 flex items-center gap-3 rounded-xl border border-white/15 bg-white/10 p-4">
                <span className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-accent text-white">
                  {Icons.bell}
                </span>
                <p className="text-[13px] leading-relaxed text-white/80">
                  Tự động nhắc lịch bảo dưỡng định kỳ — xe đến hạn, khách nhận thông báo ngay.
                </p>
              </div>
            </div>
          </div>
          <div className="absolute -bottom-4 -right-2 hidden rounded-xl border border-border bg-card px-4 py-3 card-shadow sm:block">
            <p className="flex items-center gap-1.5 text-sm font-bold text-success">
              <span className="h-2 w-2 rounded-full bg-success" />
              Xưởng đang hoạt động
            </p>
            <p className="mt-0.5 text-xs text-muted-foreground">T2 – T7 · 07:30 – 17:30</p>
          </div>
        </div>

        {/* Copy */}
        <div>
          <p className="text-xs font-bold uppercase tracking-widest text-accent">Vì sao chọn gara</p>
          <h2 id="homepage-about-title" className="ui-page-title mt-2">
            Quản lý bằng hệ thống,
            <br />
            phục vụ bằng cái tâm
          </h2>
          <p className="ui-secondary-text mt-3 max-w-xl text-sm leading-relaxed">
            {GARAGE_NAME} vận hành trên một hệ thống quản lý thống nhất: lịch hẹn, tiếp nhận, phiếu sửa chữa,
            báo giá, kho và hóa đơn liên thông với nhau — nên thông tin tới tay khách luôn đầy đủ và chính xác.
          </p>
          <ul className="mt-6 space-y-4">
            {STRENGTHS.map((item) => (
              <li key={item.title} className="flex gap-3">
                <span className={`flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg ${item.tint}`} aria-hidden="true">
                  {item.icon}
                </span>
                <div>
                  <h3 className="ui-card-title">{item.title}</h3>
                  <p className="mt-0.5 text-sm leading-relaxed text-muted-foreground">{item.description}</p>
                </div>
              </li>
            ))}
          </ul>
          <button
            type="button"
            onClick={onNavigateAbout}
            className="mt-6 inline-flex min-h-10 items-center gap-1 rounded-md border border-border bg-surface px-4 text-sm font-semibold text-primary transition-all hover:bg-surface-subtle"
          >
            Tìm hiểu thêm về gara
            <span aria-hidden="true">→</span>
          </button>
        </div>
      </div>
    </section>
  );
}
