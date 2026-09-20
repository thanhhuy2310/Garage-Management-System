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
      <div className="mx-auto grid w-full max-w-7xl items-stretch gap-0 px-4 py-16 sm:px-6 sm:py-24 lg:grid-cols-2">
        <div className="relative overflow-hidden bg-brand-dark p-7 text-white sm:p-10 lg:p-12" aria-hidden="true">
          <div className="public-hero-grid pointer-events-none absolute inset-0 opacity-40" />
          <div className="relative flex h-full min-h-[430px] flex-col">
            <p className="public-kicker text-accent">Xưởng dịch vụ</p>
            <p className="mt-4 max-w-md text-3xl font-black uppercase leading-tight tracking-tight sm:text-4xl">{GARAGE_NAME}</p>
            <div className="mt-auto grid grid-cols-2 border border-white/15">
              <div className="border-b border-r border-white/15 p-5"><p className="text-4xl font-black text-accent">{dichVu.length}</p><p className="mt-1 text-xs font-bold uppercase tracking-wider text-white/50">Hạng mục dịch vụ</p></div>
              <div className="border-b border-white/15 p-5"><p className="text-4xl font-black text-accent">06</p><p className="mt-1 text-xs font-bold uppercase tracking-wider text-white/50">Bước kiểm soát</p></div>
              <div className="col-span-2 flex items-center gap-4 p-5"><span className="grid h-11 w-11 flex-shrink-0 place-items-center bg-accent text-white">{Icons.bell}</span><p className="text-base leading-7 text-white/75">Nhắc lịch bảo dưỡng và thông báo tiến độ tự động cho khách hàng.</p></div>
            </div>
          </div>
        </div>

        <div className="bg-white p-7 sm:p-10 lg:p-12">
          <p className="public-kicker text-accent">Cách gara vận hành</p>
          <h2 id="homepage-about-title" className="public-section-title mt-3 text-foreground">Thông tin rõ ràng ở từng bước.</h2>
          <p className="mt-5 text-base leading-7 text-muted-foreground">Từ lịch hẹn, báo giá, phiếu sửa chữa đến kho và hóa đơn đều liên thông. Thông tin đến tay khách luôn đầy đủ, nhất quán và dễ kiểm tra.</p>
          <ul className="mt-7 divide-y divide-border border-y border-border">
            {STRENGTHS.map((item) => (
              <li key={item.title} className="flex gap-4 py-5">
                <span className="grid h-11 w-11 flex-shrink-0 place-items-center bg-primary-soft text-primary" aria-hidden="true">{item.icon}</span>
                <div><h3 className="font-extrabold text-foreground">{item.title}</h3><p className="mt-1 text-base leading-7 text-muted-foreground">{item.description}</p></div>
              </li>
            ))}
          </ul>
          <button type="button" onClick={onNavigateAbout} className="public-text-link mt-7 text-primary">Tìm hiểu về gara <span aria-hidden="true">{Icons.arrowRight}</span></button>
        </div>
      </div>
    </section>
  );
}
