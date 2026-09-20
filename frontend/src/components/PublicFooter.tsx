import { GARAGE_NAME } from "../data";
import { Icons } from "./ui";
import type { PublicPageKey } from "./PublicHeader";

const SERVICE_LINKS: { key: PublicPageKey; label: string }[] = [
  { key: "services", label: "Bảo dưỡng định kỳ" },
  { key: "services", label: "Sửa chữa tổng hợp" },
  { key: "services", label: "Điện – điều hòa" },
  { key: "parts", label: "Phụ tùng trong kho" },
];

const GARAGE_LINKS: { key: PublicPageKey; label: string }[] = [
  { key: "about", label: "Giới thiệu" },
  { key: "services", label: "Dịch vụ" },
  { key: "parts", label: "Phụ tùng" },
  { key: "contact", label: "Liên hệ" },
];

const TRUST_ITEMS = [
  { title: "Báo giá minh bạch", note: "Khách duyệt trước khi sửa", icon: Icons.fileText },
  { title: "Theo dõi trực tuyến", note: "Cập nhật theo từng bước", icon: Icons.history },
  { title: "Phụ tùng rõ nguồn gốc", note: "Quản lý trực tiếp trong kho", icon: Icons.package },
  { title: "Hỗ trợ sau sửa chữa", note: "Tiếp nhận khi cần kiểm tra lại", icon: Icons.checkCircle },
];

interface PublicFooterProps { onNavigate: (page: PublicPageKey) => void; onBook: () => void; }

export default function PublicFooter({ onNavigate, onBook }: PublicFooterProps) {
  return (
    <>
      <section aria-labelledby="homepage-cta-title" className="bg-surface-subtle px-4 pb-16 sm:px-6 sm:pb-24">
        <div className="mx-auto grid w-full max-w-7xl overflow-hidden bg-accent text-white lg:grid-cols-[1fr_auto]">
          <div className="p-7 sm:p-10 lg:p-12"><p className="text-xs font-extrabold uppercase tracking-[0.18em] text-white/70">Đặt lịch trước khi đến gara</p><h2 id="homepage-cta-title" className="mt-3 max-w-3xl text-2xl font-black uppercase leading-tight tracking-tight sm:text-4xl">Chọn giờ kiểm tra xe phù hợp.</h2><p className="mt-3 max-w-2xl text-base leading-7 text-white/80">Gara xác nhận lịch hẹn và báo giá sau khi kiểm tra tình trạng xe.</p></div>
          <div className="flex flex-col justify-center gap-3 border-t border-white/20 p-7 sm:flex-row lg:border-l lg:border-t-0 lg:p-10">
            <button type="button" onClick={onBook} className="min-h-12 bg-brand-dark px-7 text-xs font-extrabold uppercase tracking-wider text-white transition-all hover:bg-primary">Đặt lịch ngay</button>
            <a href="tel:0901234567" className="inline-flex min-h-12 items-center justify-center border border-white/40 px-7 text-xs font-extrabold uppercase tracking-wider text-white transition-all hover:bg-white hover:text-accent">Gọi gara</a>
          </div>
        </div>
      </section>

      <section aria-label="Cam kết dịch vụ" className="border-y border-white/10 bg-brand-dark text-white">
        <div className="mx-auto grid w-full max-w-7xl grid-cols-1 px-4 sm:grid-cols-2 sm:px-6 lg:grid-cols-4">
          {TRUST_ITEMS.map((item) => (
            <div key={item.title} className="flex items-center gap-4 border-b border-white/10 py-6 sm:border-r sm:px-5 lg:border-b-0 first:pl-0 last:border-r-0 last:pr-0">
              <span className="grid h-11 w-11 flex-shrink-0 place-items-center border border-white/15 text-accent" aria-hidden="true">{item.icon}</span>
              <div><p className="text-base font-extrabold text-white">{item.title}</p><p className="mt-1 text-sm text-white/60">{item.note}</p></div>
            </div>
          ))}
        </div>
      </section>

      <footer className="bg-brand-dark text-sm text-white/60">
        <div className="mx-auto grid w-full max-w-7xl gap-10 px-4 py-14 sm:grid-cols-2 sm:px-6 lg:grid-cols-[1.4fr_0.8fr_0.8fr_1fr]">
          <div>
            <div className="flex items-center gap-3"><span className="grid h-12 w-12 place-items-center bg-accent text-sm font-black tracking-wider text-white">TC</span><div><p className="font-black uppercase text-white">{GARAGE_NAME}</p><p className="mt-0.5 text-[10px] font-bold uppercase tracking-[0.15em] text-white/40">Dịch vụ sửa chữa ô tô</p></div></div>
            <p className="mt-5 max-w-sm text-sm leading-6">Đặt lịch, tiếp nhận, báo giá, sửa chữa và bàn giao minh bạch trên một hệ thống thống nhất.</p>
            <p className="mt-4 text-xs font-bold uppercase tracking-wider text-accent">T2 – T7 · 07:30 – 17:30</p>
          </div>
          <nav aria-label="Dịch vụ"><p className="public-footer-title">Dịch vụ</p><ul className="mt-3">{SERVICE_LINKS.map((link, index) => <li key={`${link.label}-${index}`}><button type="button" onClick={() => onNavigate(link.key)} className="inline-flex min-h-11 items-center transition-all hover:text-white">{link.label}</button></li>)}</ul></nav>
          <nav aria-label="Về gara"><p className="public-footer-title">Gara</p><ul className="mt-3">{GARAGE_LINKS.map((link) => <li key={link.label}><button type="button" onClick={() => onNavigate(link.key)} className="inline-flex min-h-11 items-center transition-all hover:text-white">{link.label}</button></li>)}</ul></nav>
          <div><p className="public-footer-title">Liên hệ</p><ul className="mt-3 text-sm"><li className="flex min-h-11 items-center">123 Lê Lợi, Q.1, TP.HCM</li><li><a href="tel:0901234567" className="inline-flex min-h-11 items-center font-extrabold text-white hover:text-accent">0901 234 567</a></li><li><button type="button" onClick={onBook} className="inline-flex min-h-11 items-center gap-2 font-bold text-accent hover:text-white">Đặt lịch sửa chữa <span aria-hidden="true">{Icons.arrowRight}</span></button></li></ul></div>
        </div>
        <div className="border-t border-white/10"><div className="mx-auto flex w-full max-w-7xl flex-col gap-1 px-4 py-5 text-xs text-white/50 sm:flex-row sm:items-center sm:justify-between sm:px-6"><p>© 2026 {GARAGE_NAME}. Khóa luận tốt nghiệp — Hệ thống quản lý gara ô tô.</p><p>Dữ liệu demo phục vụ học tập.</p></div></div>
      </footer>
    </>
  );
}
