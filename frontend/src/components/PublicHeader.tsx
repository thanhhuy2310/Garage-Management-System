import { useState } from "react";
import { GARAGE_NAME } from "../data";
import { Icons } from "./ui";

export type PublicPageKey = "home" | "about" | "services" | "parts" | "contact";

const NAV_ITEMS: { key: PublicPageKey; label: string }[] = [
  { key: "home", label: "Trang chủ" },
  { key: "about", label: "Giới thiệu" },
  { key: "services", label: "Dịch vụ" },
  { key: "parts", label: "Phụ tùng" },
  { key: "contact", label: "Liên hệ" },
];

const HOTLINE = "0901 234 567";

interface PublicHeaderProps {
  active: PublicPageKey;
  onNavigate: (page: PublicPageKey) => void;
  onLogin: () => void;
  onBook: () => void;
}

export default function PublicHeader({ active, onNavigate, onLogin, onBook }: PublicHeaderProps) {
  const [menuOpen, setMenuOpen] = useState(false);

  const go = (page: PublicPageKey) => {
    setMenuOpen(false);
    onNavigate(page);
  };

  return (
    <>
      <div className="bg-accent text-accent-foreground">
        <div className="mx-auto flex min-h-10 w-full max-w-7xl items-center justify-center px-4 py-2 text-center text-xs font-extrabold uppercase tracking-[0.16em]">
          Đặt lịch trực tuyến · Duyệt báo giá · Theo dõi tiến độ sửa chữa
        </div>
      </div>

      <header className="sticky top-0 z-40 border-b border-white/10 bg-brand-dark text-white shadow-lg">
        <div className="mx-auto flex h-[76px] w-full max-w-7xl items-center justify-between gap-4 px-4 sm:px-6">
          <button type="button" onClick={() => go("home")} aria-label={`${GARAGE_NAME} – Trang chủ`} className="group flex min-w-0 items-center gap-2 text-left sm:gap-3">
            <span className="grid h-11 w-11 flex-shrink-0 place-items-center bg-accent text-xs font-black tracking-wider text-white transition-all group-hover:bg-white group-hover:text-brand-dark sm:h-12 sm:w-12 sm:text-sm" aria-hidden="true">TC</span>
            <span className="min-w-0">
              <span className="block truncate text-xs font-black uppercase leading-tight tracking-[-0.02em] text-white sm:text-base">Gara Thành Công</span>
              <span className="mt-1 hidden truncate text-xs font-bold uppercase tracking-[0.14em] text-white/55 sm:block">Dịch vụ sửa chữa ô tô</span>
            </span>
          </button>

          <nav aria-label="Điều hướng website" className="hidden h-full items-center gap-8 xl:flex">
            {NAV_ITEMS.map((item) => (
              <button key={item.key} type="button" onClick={() => go(item.key)} aria-current={active === item.key ? "page" : undefined} className={`relative flex h-full items-center whitespace-nowrap text-sm font-extrabold uppercase tracking-[0.1em] transition-all ${active === item.key ? "text-white" : "text-white/60 hover:text-white"}`}>
                {item.label}
                {active === item.key && <span className="public-nav-indicator absolute inset-x-0 bottom-0 h-1 bg-accent" aria-hidden="true" />}
              </button>
            ))}
          </nav>

          <div className="flex flex-shrink-0 items-center gap-2">
            <a href={`tel:${HOTLINE.replace(/\s/g, "")}`} className="hidden min-h-11 items-center border-r border-white/15 pr-4 text-right 2xl:flex">
              <span><span className="block text-xs font-bold uppercase tracking-[0.14em] text-white/50">Hotline hỗ trợ</span><span className="mt-0.5 block text-sm font-extrabold text-white">{HOTLINE}</span></span>
            </a>
            <button type="button" onClick={onLogin} className="hidden min-h-11 items-center px-3 text-sm font-extrabold uppercase tracking-wider text-white/70 transition-all hover:text-white sm:inline-flex">Đăng nhập</button>
            <button type="button" onClick={onBook} className="inline-flex min-h-11 items-center bg-accent px-3 text-xs font-extrabold uppercase tracking-wider text-white transition-all hover:brightness-110 sm:px-5 sm:text-sm">Đặt lịch</button>
            <button type="button" onClick={() => setMenuOpen((open) => !open)} aria-label={menuOpen ? "Đóng menu" : "Mở menu"} aria-expanded={menuOpen} className="flex h-11 w-11 items-center justify-center border border-white/15 text-white transition-all hover:border-white/40 xl:hidden">
              <span aria-hidden="true">{menuOpen ? Icons.close : Icons.menu}</span>
            </button>
          </div>
        </div>

        {menuOpen && (
          <nav aria-label="Điều hướng website trên di động" className="mobile-menu-enter border-t border-white/10 bg-brand-dark px-4 py-3 xl:hidden">
            {NAV_ITEMS.map((item) => (
              <button key={item.key} type="button" onClick={() => go(item.key)} aria-current={active === item.key ? "page" : undefined} className={`flex min-h-12 w-full items-center justify-between border-b border-white/10 px-1 text-left text-sm font-extrabold uppercase tracking-[0.1em] ${active === item.key ? "text-accent" : "text-white/70"}`}>
                {item.label}<span aria-hidden="true">{Icons.arrowRight}</span>
              </button>
            ))}
            <button type="button" onClick={() => { setMenuOpen(false); onLogin(); }} className="mt-3 flex min-h-11 w-full items-center justify-center border border-white/20 text-sm font-extrabold uppercase tracking-wider text-white sm:hidden">Đăng nhập</button>
          </nav>
        )}
      </header>
    </>
  );
}
