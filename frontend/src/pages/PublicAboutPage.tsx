import PublicFooter from "../components/PublicFooter";
import PublicHeader, { type PublicPageKey } from "../components/PublicHeader";
import { Icons } from "../components/ui";
import { GARAGE_NAME } from "../data";
import { dichVu } from "../mock/data";
import { phuTung } from "../mock/schemaData";

const VALUES = [
  { title: "Minh bạch", description: "Báo giá chi tiết từng hạng mục, khách duyệt mới làm.", icon: Icons.fileText, tint: "bg-info-soft text-info" },
  { title: "Theo đúng quy trình", description: "Từ đặt lịch đến bàn giao, mỗi bước đều được ghi nhận.", icon: Icons.clipboard, tint: "bg-success-soft text-success" },
  { title: "Chủ động thời gian", description: "Khách chọn giờ hẹn và nhận nhắc lịch bảo dưỡng định kỳ.", icon: Icons.bell, tint: "bg-warning-soft text-warning" },
];

interface PublicAboutPageProps {
  onNavigate: (page: PublicPageKey) => void;
  onLogin: () => void;
  onBook: () => void;
}

export default function PublicAboutPage({ onNavigate, onLogin, onBook }: PublicAboutPageProps) {
  return (
    <div className="min-h-screen bg-background">
      <PublicHeader active="about" onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} />
      <main>
        <div className="border-b border-border bg-surface-subtle">
          <div className="mx-auto w-full max-w-6xl px-4 py-10 sm:px-6 sm:py-14">
            <p className="text-xs font-bold uppercase tracking-widest text-accent">Giới thiệu</p>
            <h1 className="ui-page-title mt-2 text-3xl sm:text-4xl">Về {GARAGE_NAME}</h1>
            <p className="ui-secondary-text mt-2 max-w-2xl text-sm">
              Xưởng sửa chữa và bảo dưỡng ô tô vận hành trên một hệ thống quản lý thống nhất —
              từ lịch hẹn, tiếp nhận, báo giá đến kho và hóa đơn.
            </p>
          </div>
        </div>

        <div className="mx-auto grid w-full max-w-6xl items-center gap-10 px-4 py-12 lg:grid-cols-2">
          <div>
            <h2 className="ui-section-title text-xl">Theo dõi đầy đủ từ tiếp nhận đến bàn giao</h2>
            <p className="mt-3 text-sm leading-relaxed text-muted-foreground">
              Mỗi xe vào xưởng đều có hồ sơ đầy đủ: phiếu tiếp nhận ghi tình trạng ban đầu, phiếu sửa chữa
              theo dõi từng hạng mục, báo giá xác nhận trước khi làm và hóa đơn rõ ràng khi bàn giao.
              Nhờ đó thông tin tới tay khách luôn đầy đủ và chính xác.
            </p>
            <div className="mt-6 grid grid-cols-3 gap-3">
              {[
                { value: String(dichVu.length), label: "Hạng mục dịch vụ" },
                { value: String(phuTung.length), label: "Mã phụ tùng" },
                { value: "6", label: "Bước quy trình" },
              ].map((stat) => (
                <div key={stat.label} className="card-shadow rounded-lg border border-border bg-card p-4 text-center">
                  <p className="text-2xl font-extrabold tracking-tight text-primary">{stat.value}</p>
                  <p className="mt-1 text-xs text-muted-foreground">{stat.label}</p>
                </div>
              ))}
            </div>
          </div>
          <ul className="space-y-4">
            {VALUES.map((item) => (
              <li key={item.title} className="card-shadow flex gap-4 rounded-lg border border-border bg-card p-4 sm:p-5">
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
        </div>

        <div className="mx-auto w-full max-w-6xl px-4 pb-14 sm:px-6">
          <div className="flex flex-col items-center justify-between gap-4 rounded-xl bg-brand-dark px-6 py-8 text-center text-white sm:flex-row sm:text-left">
            <div>
              <h2 className="text-xl font-extrabold tracking-tight">Đặt lịch trước khi đến gara</h2>
              <p className="mt-1 text-sm text-white/75">Chọn ngày giờ phù hợp, gara sẽ xác nhận trong giờ làm việc.</p>
            </div>
            <button
              type="button"
              onClick={onBook}
              className="inline-flex min-h-11 flex-shrink-0 items-center rounded-md border border-accent bg-accent px-6 text-sm font-bold text-accent-foreground transition-all hover:brightness-110"
            >
              Đặt lịch ngay
            </button>
          </div>
        </div>
      </main>
      <PublicFooter onNavigate={onNavigate} onBook={onBook} />
    </div>
  );
}
