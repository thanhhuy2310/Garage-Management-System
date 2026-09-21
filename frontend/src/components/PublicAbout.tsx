import { Icons } from "./ui";
import { GARAGE_NAME } from "../data";
import { dichVu } from "../mock/data";

const STRENGTHS = [
  { title: "Báo giá trước khi sửa", description: "Chi tiết từng dịch vụ và phụ tùng, khách duyệt mới thực hiện.", icon: Icons.fileText },
  { title: "Theo dõi tiến độ", description: "Trạng thái tiếp nhận, kiểm tra, sửa chữa và bàn giao luôn được cập nhật.", icon: Icons.history },
  { title: "Phụ tùng có nguồn gốc", description: "Kho được quản lý theo mã, số lượng và lịch sử nhập xuất rõ ràng.", icon: Icons.package },
];

interface PublicAboutProps { onNavigateAbout: () => void; }

export default function PublicAbout({ onNavigateAbout }: PublicAboutProps) {
  return (
    <section aria-labelledby="homepage-about-title" className="public-reveal border-y border-border bg-surface-subtle">
      <div className="mx-auto w-full max-w-7xl px-4 py-16 sm:px-6 sm:py-24">
        <div className="grid overflow-hidden border border-border bg-white shadow-[0_24px_70px_rgba(15,23,42,0.10)] lg:grid-cols-[1.08fr_0.92fr]">
          <figure className="public-about-media relative min-h-[520px] overflow-hidden bg-brand-dark text-white lg:min-h-[620px]">
            <img
              src="/images/garage-workshop.webp"
              alt="Kỹ thuật viên kiểm tra động cơ ô tô trong xưởng dịch vụ hiện đại"
              width="1536"
              height="1024"
              loading="lazy"
              className="absolute inset-0 h-full w-full object-cover object-center"
            />
            <div className="absolute inset-0 bg-[linear-gradient(180deg,rgba(5,18,30,0.22)_0%,rgba(5,18,30,0.30)_34%,rgba(5,18,30,0.96)_100%)]" aria-hidden="true" />
            <div className="public-hero-grid pointer-events-none absolute inset-0 opacity-25" aria-hidden="true" />

            <div className="relative flex min-h-[520px] h-full flex-col justify-between p-7 sm:p-10 lg:min-h-[620px] lg:p-12">
              <div>
                <div className="inline-flex items-center gap-2 border border-white/25 bg-brand-dark/55 px-3 py-2 text-xs font-extrabold uppercase tracking-[0.14em] backdrop-blur-sm">
                  <span className="h-2 w-2 bg-accent" aria-hidden="true" /> Xưởng dịch vụ đang hoạt động
                </div>
                <p className="mt-5 max-w-md text-3xl font-black uppercase leading-tight tracking-tight text-white sm:text-4xl">{GARAGE_NAME}</p>
              </div>

              <div className="bg-brand-dark/88 backdrop-blur-md">
                <div className="grid grid-cols-2 border border-white/15">
                  <div className="border-r border-white/15 p-5 sm:p-6"><p className="tabular-nums text-4xl font-black text-accent">{dichVu.length}</p><p className="mt-1 text-xs font-bold uppercase tracking-wider text-white/60">Hạng mục dịch vụ</p></div>
                  <div className="p-5 sm:p-6"><p className="tabular-nums text-4xl font-black text-accent">06</p><p className="mt-1 text-xs font-bold uppercase tracking-wider text-white/60">Bước kiểm soát</p></div>
                  <div className="col-span-2 flex items-start gap-4 border-t border-white/15 p-5 sm:items-center sm:p-6"><span className="grid h-11 w-11 flex-shrink-0 place-items-center bg-accent text-white" aria-hidden="true">{Icons.bell}</span><p className="text-base leading-7 text-white/80">Nhắc lịch bảo dưỡng và thông báo tiến độ tự động cho khách hàng.</p></div>
                </div>
              </div>
            </div>
          </figure>

          <div className="flex flex-col justify-center bg-white p-7 sm:p-10 lg:p-12">
            <p className="public-kicker text-accent">Cách gara vận hành</p>
            <h2 id="homepage-about-title" className="public-section-title mt-3 text-foreground">Thông tin rõ ràng ở từng bước.</h2>
            <p className="mt-5 text-base leading-7 text-muted-foreground">Từ lịch hẹn, báo giá, phiếu sửa chữa đến kho và hóa đơn đều liên thông. Thông tin đến tay khách luôn đầy đủ, nhất quán và dễ kiểm tra.</p>
            <ul className="mt-7 divide-y divide-border border-y border-border">
              {STRENGTHS.map((item) => (
                <li key={item.title} className="group flex gap-4 py-5">
                  <span className="grid h-11 w-11 flex-shrink-0 place-items-center bg-primary-soft text-primary transition-colors group-hover:bg-primary group-hover:text-white" aria-hidden="true">{item.icon}</span>
                  <div><h3 className="font-extrabold text-foreground">{item.title}</h3><p className="mt-1 text-base leading-7 text-muted-foreground">{item.description}</p></div>
                </li>
              ))}
            </ul>
            <button type="button" onClick={onNavigateAbout} className="public-text-link mt-7 self-start text-primary">Tìm hiểu về gara <span aria-hidden="true">{Icons.arrowRight}</span></button>
          </div>
        </div>
      </div>
    </section>
  );
}
