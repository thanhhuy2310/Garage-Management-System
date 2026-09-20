import React from "react";

// ─── Button ────────────────────────────────────────────────────────────────
type BtnVariant = "primary" | "secondary" | "danger" | "ghost" | "outline" | "accent";
interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: BtnVariant;
  size?: "sm" | "md" | "lg";
  icon?: React.ReactNode;
}
export function Button({ variant = "primary", size = "md", icon, children, className = "", ...rest }: ButtonProps) {
  const base = "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md border font-semibold transition-all cursor-pointer select-none active:translate-y-px disabled:active:translate-y-0";
  const sizes = { sm: "min-h-11 px-3 text-sm", md: "min-h-11 px-4 text-sm", lg: "min-h-12 px-5 text-base" };
  const variants: Record<BtnVariant, string> = {
    primary: "border-primary bg-primary text-primary-foreground hover:border-primary-hover hover:bg-primary-hover",
    secondary: "border-border bg-secondary text-secondary-foreground hover:bg-muted",
    danger: "border-danger bg-danger text-white hover:brightness-90",
    ghost: "border-transparent bg-transparent text-muted-foreground hover:bg-muted hover:text-foreground",
    outline: "border-border bg-surface text-foreground hover:bg-surface-subtle",
    accent: "border-accent bg-accent text-accent-foreground hover:brightness-90",
  };
  return (
    <button className={`${base} ${sizes[size]} ${variants[variant]} ${className}`} {...rest}>
      {icon && <span className="flex-shrink-0" aria-hidden="true">{icon}</span>}
      {children}
    </button>
  );
}

// ─── Badge ──────────────────────────────────────────────────────────────────
type BadgeVariant = "pending" | "confirmed" | "arrived" | "cancelled" | "completed"
  | "in_progress" | "waiting_parts" | "draft" | "rejected" | "paid" | "unpaid"
  | "ok" | "low" | "out" | "blue" | "gray";

const BADGE_STYLES: Record<BadgeVariant, string> = {
  pending: "border-warning/20 bg-warning-soft text-warning",
  confirmed: "border-info/20 bg-info-soft text-info",
  arrived: "border-info/20 bg-info-soft text-info",
  cancelled: "border-danger/20 bg-danger-soft text-danger",
  completed: "border-success/20 bg-success-soft text-success",
  in_progress: "border-info/20 bg-info-soft text-info",
  waiting_parts: "border-warning/20 bg-warning-soft text-warning",
  draft: "border-border bg-muted text-muted-foreground",
  rejected: "border-danger/20 bg-danger-soft text-danger",
  paid: "border-success/20 bg-success-soft text-success",
  unpaid: "border-warning/20 bg-warning-soft text-warning",
  ok: "border-success/20 bg-success-soft text-success",
  low: "border-warning/20 bg-warning-soft text-warning",
  out: "border-danger/20 bg-danger-soft text-danger",
  blue: "border-info/20 bg-info-soft text-info",
  gray: "border-border bg-muted text-muted-foreground",
};

const BADGE_LABELS: Partial<Record<BadgeVariant, string>> = {
  pending: "Chờ xác nhận",
  confirmed: "Đã xác nhận",
  arrived: "Đã đến",
  cancelled: "Đã hủy",
  completed: "Hoàn tất",
  in_progress: "Đang sửa chữa",
  waiting_parts: "Chờ phụ tùng",
  draft: "Nháp",
  rejected: "Không xác nhận",
  paid: "Đã thanh toán",
  unpaid: "Chưa thanh toán",
  ok: "Còn hàng",
  low: "Sắp hết",
  out: "Hết hàng",
};

export function Badge({ variant, label, className = "" }: { variant: BadgeVariant; label?: string; className?: string }) {
  return (
    <span className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${BADGE_STYLES[variant]} ${className}`}>
      {label ?? BADGE_LABELS[variant] ?? variant}
    </span>
  );
}

// ─── Input ──────────────────────────────────────────────────────────────────
interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  icon?: React.ReactNode;
  error?: string;
  helperText?: string;
}
export function Input({ label, icon, error, helperText, className = "", id, ...rest }: InputProps) {
  const generatedId = React.useId();
  const inputId = id ?? generatedId;
  const descriptionId = error || helperText ? `${inputId}-description` : undefined;
  return (
    <div className="flex flex-col gap-1.5">
      {label && <label htmlFor={inputId} className="text-sm font-semibold text-slate-700">{label}</label>}
      <div className="relative">
        {icon && <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" aria-hidden="true">{icon}</span>}
        <input
          id={inputId}
          aria-invalid={Boolean(error)}
          aria-describedby={descriptionId}
          className={`min-h-11 w-full rounded-md border border-border bg-surface px-3 text-base text-foreground shadow-sm sm:text-sm ${icon ? "pl-9" : ""} placeholder:text-muted-foreground hover:border-slate-400 focus:border-ring focus:ring-2 focus:ring-ring/15 transition-all ${error ? "border-danger focus:border-danger focus:ring-danger/15" : ""} ${className}`}
          {...rest}
        />
      </div>
      {(error || helperText) && <p id={descriptionId} className={`text-xs leading-relaxed ${error ? "text-danger" : "text-muted-foreground"}`} role={error ? "alert" : undefined}>{error ?? helperText}</p>}
    </div>
  );
}

// ─── Select ─────────────────────────────────────────────────────────────────
interface SelectProps extends React.SelectHTMLAttributes<HTMLSelectElement> {
  label?: string;
  options: { value: string; label: string }[];
  helperText?: string;
}
export function Select({ label, options, helperText, className = "", id, ...rest }: SelectProps) {
  const generatedId = React.useId();
  const selectId = id ?? generatedId;
  return (
    <div className="flex flex-col gap-1.5">
      {label && <label htmlFor={selectId} className="text-sm font-semibold text-slate-700">{label}</label>}
      <select
        id={selectId}
        aria-describedby={helperText ? `${selectId}-description` : undefined}
        className={`min-h-11 rounded-md border border-border bg-surface px-3 text-base text-foreground shadow-sm hover:border-slate-400 focus:border-ring focus:ring-2 focus:ring-ring/15 transition-all sm:text-sm ${className}`}
        {...rest}
      >
        {options.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
      </select>
      {helperText && <p id={`${selectId}-description`} className="text-xs leading-relaxed text-slate-500">{helperText}</p>}
    </div>
  );
}

// ─── Card ───────────────────────────────────────────────────────────────────
interface TextareaProps extends React.TextareaHTMLAttributes<HTMLTextAreaElement> {
  label?: string;
  error?: string;
  helperText?: string;
}
export function Textarea({ label, error, helperText, className = "", id, ...rest }: TextareaProps) {
  const generatedId = React.useId();
  const textareaId = id ?? generatedId;
  const descriptionId = error || helperText ? `${textareaId}-description` : undefined;
  return (
    <div className="flex flex-col gap-1.5">
      {label && <label htmlFor={textareaId} className="text-sm font-semibold text-slate-700">{label}</label>}
      <textarea
        id={textareaId}
        aria-invalid={Boolean(error)}
        aria-describedby={descriptionId}
        className={`min-h-28 w-full resize-y rounded-md border border-border bg-surface px-3 py-3 text-base text-foreground shadow-sm placeholder:text-muted-foreground hover:border-slate-400 focus:border-ring focus:ring-2 focus:ring-ring/15 transition-all sm:text-sm ${error ? "border-danger focus:border-danger focus:ring-danger/15" : ""} ${className}`}
        {...rest}
      />
      {(error || helperText) && <p id={descriptionId} className={`text-xs leading-relaxed ${error ? "text-danger" : "text-muted-foreground"}`} role={error ? "alert" : undefined}>{error ?? helperText}</p>}
    </div>
  );
}

interface ChoiceProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, "type"> {
  label: string;
  description?: string;
}
function Choice({ type, label, description, className = "", id, ...rest }: ChoiceProps & { type: "checkbox" | "radio" }) {
  const generatedId = React.useId();
  const choiceId = id ?? generatedId;
  return (
    <label htmlFor={choiceId} className="flex min-h-11 cursor-pointer items-start gap-3 py-2.5 text-sm text-foreground">
      <input id={choiceId} type={type} className={`mt-0.5 h-5 w-5 flex-shrink-0 border-border text-primary accent-primary focus:ring-ring ${className}`} {...rest} />
      <span>
        <span className="block font-medium">{label}</span>
        {description && <span className="mt-0.5 block text-xs text-muted-foreground">{description}</span>}
      </span>
    </label>
  );
}
export function Checkbox(props: ChoiceProps) { return <Choice type="checkbox" {...props} />; }
export function Radio(props: ChoiceProps) { return <Choice type="radio" {...props} />; }

export function TableContainer({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return <div className={`table-container ${className}`}>{children}</div>;
}

export function Card({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  const content = React.Children.map(children, child => (
    React.isValidElement(child) && child.type === "table"
      ? <TableContainer>{child}</TableContainer>
      : child
  ));
  return (
    <div className={`rounded-lg border border-border bg-card text-card-foreground card-shadow ${className}`}>
      {content}
    </div>
  );
}

// ─── Modal ──────────────────────────────────────────────────────────────────
export function Modal({ open, onClose, title, children, width = "max-w-lg" }: {
  open: boolean; onClose: () => void; title: string; children: React.ReactNode; width?: string;
}) {
  const titleId = React.useId();
  const dialogRef = React.useRef<HTMLDivElement>(null);

  React.useEffect(() => {
    if (!open) return;

    const previouslyFocused = document.activeElement as HTMLElement | null;
    const previousOverflow = document.body.style.overflow;
    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") onClose();
    };

    document.body.style.overflow = "hidden";
    document.addEventListener("keydown", handleKeyDown);
    window.requestAnimationFrame(() => dialogRef.current?.focus());

    return () => {
      document.body.style.overflow = previousOverflow;
      document.removeEventListener("keydown", handleKeyDown);
      previouslyFocused?.focus();
    };
  }, [open, onClose]);

  if (!open) return null;
  return (
    <div className="fixed inset-0 z-50 flex items-end justify-center p-0 sm:items-center sm:p-6" onClick={onClose} role="presentation">
      <div className="absolute inset-0 bg-slate-950/50 backdrop-blur-[2px]" />
      <div
        ref={dialogRef}
        role="dialog"
        aria-modal="true"
        aria-labelledby={titleId}
        tabIndex={-1}
        className={`relative flex max-h-[calc(100dvh-0.75rem)] w-full flex-col overflow-hidden rounded-t-xl bg-white card-shadow-md sm:max-h-[90vh] sm:rounded-xl ${width}`}
        onClick={e => e.stopPropagation()}
      >
        <div className="flex items-center justify-between gap-4 border-b border-border px-4 py-3 sm:px-6 sm:py-4">
          <h2 id={titleId} className="text-lg font-semibold text-slate-900">{title}</h2>
          <button type="button" onClick={onClose} aria-label="Đóng hộp thoại" className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-md text-slate-500 transition-all hover:bg-slate-100 hover:text-slate-800">
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 6 6 18M6 6l12 12"/></svg>
          </button>
        </div>
        <div className="overflow-y-auto p-4 sm:p-6">{children}</div>
      </div>
    </div>
  );
}

// ─── Tabs ───────────────────────────────────────────────────────────────────
export function Tabs({ tabs, active, onChange }: {
  tabs: { key: string; label: string; count?: number }[];
  active: string;
  onChange: (key: string) => void;
}) {
  return (
    <div className="flex max-w-full gap-1 overflow-x-auto rounded-lg bg-slate-100 p-1" role="tablist">
      {tabs.map(t => (
        <button
          key={t.key}
          type="button"
          onClick={() => onChange(t.key)}
          role="tab"
          aria-selected={active === t.key}
          className={`flex min-h-11 flex-shrink-0 items-center gap-2 rounded-md px-3.5 text-sm font-semibold transition-all ${active === t.key ? "bg-white text-primary shadow-sm" : "text-slate-600 hover:bg-white/60 hover:text-slate-900"}`}
        >
          {t.label}
          {t.count !== undefined && (
            <span className={`rounded-full px-1.5 py-0.5 text-xs ${active === t.key ? "bg-primary text-primary-foreground" : "bg-slate-200 text-slate-600"}`}>{t.count}</span>
          )}
        </button>
      ))}
    </div>
  );
}

// ─── SearchBox ──────────────────────────────────────────────────────────────
export function SearchBox({ value, onChange, placeholder = "Tìm kiếm..." }: {
  value: string; onChange: (v: string) => void; placeholder?: string;
}) {
  return (
    <div className="relative w-full sm:w-auto">
      <svg aria-hidden="true" className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 w-4 h-4" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
        <circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/>
      </svg>
      <input
        type="search"
        aria-label={placeholder}
        value={value}
        onChange={e => onChange(e.target.value)}
        placeholder={placeholder}
        className="h-11 w-full rounded-md border border-border bg-surface pl-10 pr-3 text-base text-foreground shadow-sm placeholder:text-muted-foreground hover:border-slate-400 focus:border-ring focus:ring-2 focus:ring-ring/15 transition-all sm:w-72 sm:text-sm"
      />
    </div>
  );
}

// ─── Pagination ─────────────────────────────────────────────────────────────
export function Pagination({ page, total, perPage, onChange }: {
  page: number; total: number; perPage: number; onChange: (p: number) => void;
}) {
  const pages = Math.ceil(total / perPage);
  if (pages <= 1) return null;
  return (
    <nav className="flex items-center gap-1" aria-label="Phân trang">
      <button aria-label="Trang trước" onClick={() => onChange(page - 1)} disabled={page === 1}
        className="flex h-11 w-11 items-center justify-center rounded-md border border-border text-sm text-slate-600 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
        ‹
      </button>
      {Array.from({ length: pages }, (_, i) => i + 1).map(p => (
        <button key={p} onClick={() => onChange(p)} aria-label={`Trang ${p}`} aria-current={p === page ? "page" : undefined}
          className={`flex h-11 w-11 items-center justify-center rounded-md text-sm transition-all ${p === page ? "bg-primary text-white" : "border border-border text-slate-600 hover:bg-slate-50"}`}>
          {p}
        </button>
      ))}
      <button aria-label="Trang sau" onClick={() => onChange(page + 1)} disabled={page === pages}
        className="flex h-11 w-11 items-center justify-center rounded-md border border-border text-sm text-slate-600 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40">
        ›
      </button>
    </nav>
  );
}

// ─── StatCard ────────────────────────────────────────────────────────────────
export function StatCard({ label, value, icon, trend, trendUp, color = "blue" }: {
  label: string; value: string | number; icon: React.ReactNode;
  trend?: string; trendUp?: boolean; color?: "blue" | "amber" | "green" | "red" | "navy";
}) {
  const iconBg: Record<string, string> = {
    blue: "bg-info-soft text-info",
    amber: "bg-warning-soft text-warning",
    green: "bg-success-soft text-success",
    red: "bg-danger-soft text-danger",
    navy: "bg-primary-soft text-primary",
  };
  return (
    <Card className="h-full min-h-32 p-5">
      <div className="flex h-full items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="min-h-10 text-[13px] font-medium leading-5 text-muted-foreground">{label}</p>
          <p className="mt-1 whitespace-nowrap text-[26px] font-bold leading-tight tracking-tight text-foreground">{value}</p>
          {trend && (
            <p className={`mt-1.5 flex items-center gap-1 text-xs font-medium ${trendUp ? "text-success" : "text-danger"}`}>
              {trendUp ? "↑" : "↓"} {trend}
            </p>
          )}
        </div>
        <div className={`flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg ${iconBg[color]}`} aria-hidden="true">
          {icon}
        </div>
      </div>
    </Card>
  );
}

// ─── Empty State ─────────────────────────────────────────────────────────────
export function EmptyState({ message = "Không có dữ liệu" }: { message?: string }) {
  return (
    <div className="flex flex-col items-center justify-center py-16 text-slate-500">
      <svg className="w-12 h-12 mb-3 opacity-40" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
        <rect x="2" y="5" width="20" height="14" rx="2"/><path d="M2 10h20"/>
      </svg>
      <p className="text-sm">{message}</p>
    </div>
  );
}

// ─── Timeline Item ───────────────────────────────────────────────────────────
export function TimelineItem({ label, time, note, done, active }: {
  label: string; time?: string; note?: string; done: boolean; active?: boolean;
}) {
  return (
    <div className="flex gap-4 relative">
      <div className="flex flex-col items-center">
        <div className={`w-9 h-9 rounded-full flex items-center justify-center flex-shrink-0 border-2 z-10 ${done ? "bg-success border-success" : active ? "bg-primary border-primary" : "bg-white border-slate-300"}`}>
          {done ? (
            <svg className="w-4 h-4 text-white" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3"><path d="m20 6-11 11-5-5"/></svg>
          ) : active ? (
            <div className="w-3 h-3 rounded-full bg-white" />
          ) : (
            <div className="w-3 h-3 rounded-full bg-slate-300" />
          )}
        </div>
      </div>
      <div className="pb-6">
        <p className={`font-medium text-sm ${done ? "text-slate-600" : active ? "text-primary" : "text-slate-400"}`}>{label}</p>
        {time && <p className="text-xs text-slate-400 mt-0.5">{time}</p>}
        {note && <p className="text-xs text-slate-500 mt-1 bg-slate-50 rounded px-2 py-1">{note}</p>}
      </div>
    </div>
  );
}

// ─── Icons (inline SVG) ───────────────────────────────────────────────────────
export const Icons = {
  home: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/></svg>,
  calendar: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="4" width="18" height="18" rx="2" ry="2"/><line x1="16" y1="2" x2="16" y2="6"/><line x1="8" y1="2" x2="8" y2="6"/><line x1="3" y1="10" x2="21" y2="10"/></svg>,
  car: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v9a2 2 0 0 1-2 2h-2"/><circle cx="7.5" cy="17.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/></svg>,
  users: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>,
  wrench: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14.7 6.3a1 1 0 0 0 0 1.4l1.6 1.6a1 1 0 0 0 1.4 0l3.77-3.77a6 6 0 0 1-7.94 7.94l-6.91 6.91a2.12 2.12 0 0 1-3-3l6.91-6.91a6 6 0 0 1 7.94-7.94l-3.76 3.76z"/></svg>,
  clipboard: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M16 4h2a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V6a2 2 0 0 1 2-2h2"/><rect x="8" y="2" width="8" height="4" rx="1" ry="1"/></svg>,
  fileText: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/></svg>,
  package: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="16.5" y1="9.4" x2="7.5" y2="4.21"/><path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z"/><polyline points="3.27 6.96 12 12.01 20.73 6.96"/><line x1="12" y1="22.08" x2="12" y2="12"/></svg>,
  creditCard: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="1" y="4" width="22" height="16" rx="2" ry="2"/><line x1="1" y1="10" x2="23" y2="10"/></svg>,
  history: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="1 4 1 10 7 10"/><path d="M3.51 15a9 9 0 1 0 .49-4.65"/></svg>,
  bell: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9"/><path d="M13.73 21a2 2 0 0 1-3.46 0"/></svg>,
  barChart: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="18" y1="20" x2="18" y2="10"/><line x1="12" y1="20" x2="12" y2="4"/><line x1="6" y1="20" x2="6" y2="14"/></svg>,
  userCheck: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M16 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="8.5" cy="7" r="4"/><polyline points="17 11 19 13 23 9"/></svg>,
  settings: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 0 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.68 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 0 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.68a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 0 1 2.83 2.83l-.06.06A1.65 1.65 0 0 0 19.4 9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z"/></svg>,
  plus: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>,
  search: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>,
  edit: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg>,
  eye: <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>,
  chevronRight: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="9 18 15 12 9 6"/></svg>,
  download: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"/><polyline points="7 10 12 15 17 10"/><line x1="12" y1="15" x2="12" y2="3"/></svg>,
  printer: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="6 9 6 2 18 2 18 9"/><path d="M6 18H4a2 2 0 0 1-2-2v-5a2 2 0 0 1 2-2h16a2 2 0 0 1 2 2v5a2 2 0 0 1-2 2h-2"/><rect x="6" y="14" width="12" height="8"/></svg>,
  send: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><line x1="22" y1="2" x2="11" y2="13"/><polygon points="22 2 15 22 11 13 2 9 22 2"/></svg>,
  truck: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="1" y="3" width="15" height="13"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>,
  inbox: <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polyline points="22 12 16 12 14 15 10 15 8 12 2 12"/><path d="M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z"/></svg>,
  filter: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3"/></svg>,
  checkCircle: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>,
  xCircle: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>,
  alertTriangle: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3Z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>,
  info: <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"/><line x1="12" y1="16" x2="12" y2="12"/><line x1="12" y1="8" x2="12.01" y2="8"/></svg>,
};
