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
const WORKING_HOURS = "T2 – T7 · 07:30 – 17:30";
const ADDRESS = "123 Lê Lợi, Q.1, TP.HCM";

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
      {/* Utility top bar */}
      <div className="hidden bg-brand-dark text-xs text-white/80 md:block">
        <div className="mx-auto flex h-9 w-full max-w-6xl items-center justify-between px-4">
          <div className="flex items-center gap-4">
            <a href={`tel:${HOTLINE.replace(/\s/g, "")}`} className="flex items-center gap-1.5 font-semibold text-white transition-all hover:text-white">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <path d="M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72c.127.96.361 1.903.7 2.81a2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45c.907.339 1.85.573 2.81.7A2 2 0 0 1 22 16.92z" />
              </svg>
              Hotline: {HOTLINE}
            </a>
            <span className="hidden items-center gap-1.5 lg:flex">
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                <circle cx="12" cy="12" r="10" /><polyline points="12 6 12 12 16 14" />
              </svg>
              {WORKING_HOURS}
            </span>
          </div>
          <p className="hidden truncate sm:block">{ADDRESS}</p>
        </div>
      </div>

      {/* Main header bar */}
      <header className="sticky top-0 z-40 border-b border-border bg-white/95 backdrop-blur">
        <div className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between gap-3 px-4">
          <button
            type="button"
            onClick={() => go("home")}
            aria-label={`${GARAGE_NAME} – Trang chủ`}
            className="flex min-w-0 items-center gap-2.5 text-left"
          >
            <span className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-brand-dark text-white" aria-hidden="true">
              {Icons.wrench}
            </span>
            <span className="min-w-0">
              <span className="block truncate text-[15px] font-bold leading-tight tracking-tight text-foreground">{GARAGE_NAME}</span>
              <span className="block truncate text-xs leading-tight text-muted-foreground">Sửa chữa &amp; Bảo dưỡng ô tô</span>
            </span>
          </button>

          <nav aria-label="Điều hướng website" className="hidden items-center gap-1 lg:flex">
            {NAV_ITEMS.map((item) => (
              <button
                key={item.key}
                type="button"
                onClick={() => go(item.key)}
                aria-current={active === item.key ? "page" : undefined}
                className={`relative rounded-md px-3 py-2 text-sm font-medium transition-all hover:bg-surface-subtle ${
                  active === item.key ? "text-primary" : "text-slate-600 hover:text-foreground"
                }`}
              >
                {item.label}
                {active === item.key && (
                  <span className="absolute inset-x-3 -bottom-[13px] h-0.5 rounded-full bg-accent" aria-hidden="true" />
                )}
              </button>
            ))}
          </nav>

          <div className="flex flex-shrink-0 items-center gap-2">
            <button
              type="button"
              onClick={onLogin}
              className="hidden h-10 items-center rounded-md border border-border bg-surface px-4 text-sm font-semibold text-foreground transition-all hover:bg-surface-subtle sm:inline-flex"
            >
              Đăng nhập
            </button>
            <button
              type="button"
              onClick={onBook}
              className="inline-flex h-10 items-center rounded-md border border-accent bg-accent px-4 text-sm font-semibold text-accent-foreground transition-all hover:brightness-90"
            >
              Đặt lịch
            </button>
            <button
              type="button"
              onClick={() => setMenuOpen((open) => !open)}
              aria-label={menuOpen ? "Đóng menu" : "Mở menu"}
              aria-expanded={menuOpen}
              className="flex h-10 w-10 items-center justify-center rounded-md text-slate-600 transition-all hover:bg-surface-subtle lg:hidden"
            >
              {menuOpen ? (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                  <path d="M18 6 6 18M6 6l12 12" />
                </svg>
              ) : (
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" aria-hidden="true">
                  <line x1="3" y1="6" x2="21" y2="6" />
                  <line x1="3" y1="12" x2="21" y2="12" />
                  <line x1="3" y1="18" x2="21" y2="18" />
                </svg>
              )}
            </button>
          </div>
        </div>

        {/* Mobile menu */}
        {menuOpen && (
          <nav aria-label="Điều hướng website trên di động" className="border-t border-border bg-white px-4 pb-4 pt-2 lg:hidden">
            {NAV_ITEMS.map((item) => (
              <button
                key={item.key}
                type="button"
                onClick={() => go(item.key)}
                aria-current={active === item.key ? "page" : undefined}
                className={`flex min-h-11 w-full items-center justify-between rounded-md px-3 text-sm transition-all hover:bg-surface-subtle ${
                  active === item.key ? "font-semibold text-primary" : "text-slate-700"
                }`}
              >
                {item.label}
                {active === item.key && <span className="h-1.5 w-1.5 rounded-full bg-accent" aria-hidden="true" />}
              </button>
            ))}
            <button
              type="button"
              onClick={() => { setMenuOpen(false); onLogin(); }}
              className="mt-2 flex min-h-11 w-full items-center justify-center rounded-md border border-border bg-surface px-3 text-sm font-semibold text-foreground transition-all hover:bg-surface-subtle sm:hidden"
            >
              Đăng nhập
            </button>
          </nav>
        )}
      </header>
    </>
  );
}
