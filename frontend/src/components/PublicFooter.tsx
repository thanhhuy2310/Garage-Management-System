import { GARAGE_NAME } from "../data";
import type { PublicPageKey } from "./PublicHeader";

const SERVICE_LINKS: { key: PublicPageKey; label: string }[] = [
  { key: "services", label: "Bảo dưỡng định kỳ" },
  { key: "services", label: "Sửa chữa" },
  { key: "services", label: "Điện – điều hòa" },
  { key: "parts", label: "Phụ tùng chính hãng" },
];

const GARAGE_LINKS: { key: PublicPageKey; label: string }[] = [
  { key: "about", label: "Giới thiệu" },
  { key: "services", label: "Dịch vụ" },
  { key: "parts", label: "Phụ tùng" },
  { key: "contact", label: "Liên hệ" },
];

interface PublicFooterProps {
  onNavigate: (page: PublicPageKey) => void;
  onBook: () => void;
}

export default function PublicFooter({ onNavigate, onBook }: PublicFooterProps) {
  return (
    <>
      {/* Call to action */}
      <section aria-labelledby="homepage-cta-title" className="bg-background">
        <div className="mx-auto w-full max-w-6xl px-4 py-14 sm:py-20">
          <div
            className="relative overflow-hidden rounded-2xl px-6 py-10 text-center text-white sm:px-12 sm:py-14"
            style={{ background: "var(--gradient-brand)" }}
          >
            <div
              aria-hidden="true"
              className="pointer-events-none absolute inset-0 opacity-20"
              style={{
                backgroundImage: "repeating-linear-gradient(-45deg, rgba(255,255,255,0.12) 0 2px, transparent 2px 22px)",
              }}
            />
            <div aria-hidden="true" className="pointer-events-none absolute -right-20 -top-20 h-72 w-72 rounded-full bg-accent opacity-25 blur-3xl" />
            <div className="relative">
              <h2 id="homepage-cta-title" className="mx-auto max-w-2xl text-2xl font-extrabold tracking-tight sm:text-4xl">
                Xe có dấu hiệu lạ? Đừng đợi nó “nặng” mới đi khám.
              </h2>
              <p className="mx-auto mt-3 max-w-xl text-sm leading-relaxed text-white/75 sm:text-[15px]">
                Đặt lịch trong 1 phút — gara xác nhận giờ hẹn, kiểm tra xe và báo giá minh bạch trước khi sửa.
              </p>
              <div className="mt-7 flex flex-col justify-center gap-3 sm:flex-row">
                <button
                  type="button"
                  onClick={onBook}
                  className="inline-flex min-h-12 items-center justify-center rounded-md border border-accent bg-accent px-8 text-[15px] font-bold text-accent-foreground transition-all hover:brightness-110"
                >
                  Đặt lịch ngay
                </button>
                <a
                  href="tel:0901234567"
                  className="inline-flex min-h-12 items-center justify-center rounded-md border border-white/30 bg-white/10 px-8 text-[15px] font-semibold text-white transition-all hover:bg-white/20"
                >
                  Gọi 0901 234 567
                </a>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="bg-primary text-sm text-white/70">
        <div className="mx-auto grid w-full max-w-6xl gap-8 px-4 py-12 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <p className="text-[15px] font-bold text-white">{GARAGE_NAME}</p>
            <p className="mt-2 text-[13px] leading-relaxed">
              Hệ thống quản lý gara sửa chữa ô tô: đặt lịch, tiếp nhận, báo giá, sửa chữa và bàn giao minh bạch.
            </p>
            <p className="mt-3 text-[13px]">T2 – T7 · 07:30 – 17:30</p>
          </div>
          <nav aria-label="Dịch vụ">
            <p className="text-xs font-bold uppercase tracking-widest text-white/50">Dịch vụ</p>
            <ul className="mt-3 space-y-2">
              {SERVICE_LINKS.map((link, index) => (
                <li key={`${link.label}-${index}`}>
                  <button
                    type="button"
                    onClick={() => onNavigate(link.key)}
                    className="transition-all hover:text-white"
                  >
                    {link.label}
                  </button>
                </li>
              ))}
            </ul>
          </nav>
          <nav aria-label="Về gara">
            <p className="text-xs font-bold uppercase tracking-widest text-white/50">Gara</p>
            <ul className="mt-3 space-y-2">
              {GARAGE_LINKS.map((link) => (
                <li key={link.label}>
                  <button
                    type="button"
                    onClick={() => onNavigate(link.key)}
                    className="transition-all hover:text-white"
                  >
                    {link.label}
                  </button>
                </li>
              ))}
            </ul>
          </nav>
          <div>
            <p className="text-xs font-bold uppercase tracking-widest text-white/50">Liên hệ</p>
            <ul className="mt-3 space-y-2 text-[13px]">
              <li>123 Lê Lợi, Q.1, TP.HCM</li>
              <li>
                <a href="tel:0901234567" className="font-semibold text-white transition-all hover:underline">
                  0901 234 567
                </a>
              </li>
              <li>
                <button type="button" onClick={onBook} className="transition-all hover:text-white">
                  Đặt lịch sửa chữa →
                </button>
              </li>
            </ul>
          </div>
        </div>
        <div className="border-t border-white/10">
          <div className="mx-auto flex w-full max-w-6xl flex-col gap-1 px-4 py-4 text-xs text-white/50 sm:flex-row sm:items-center sm:justify-between">
            <p>© 2026 {GARAGE_NAME}. Khóa luận tốt nghiệp — Hệ thống quản lý gara sửa chữa ô tô.</p>
            <p>Dữ liệu demo phục vụ học tập.</p>
          </div>
        </div>
      </footer>
    </>
  );
}
