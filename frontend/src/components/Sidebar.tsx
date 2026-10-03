import { GARAGE_NAME } from "../data";
import { readSession } from "../api/session";
import { ROLE_LABELS } from "./Header";
import { Icons } from "./ui";

const ALL_NAV_ITEMS = [
  { key: "dashboard", label: "Tổng quan", icon: Icons.home },
  { key: "appointments", label: "Lịch hẹn", icon: Icons.calendar },
  { key: "reception", label: "Tiếp nhận xe", icon: Icons.truck },
  { key: "repair", label: "Phiếu sửa chữa", icon: Icons.wrench },
  { key: "quotation", label: "Báo giá", icon: Icons.fileText },
  { key: "customers", label: "Khách hàng", icon: Icons.users },
  { key: "vehicles", label: "Xe", icon: Icons.car },
  { key: "services", label: "Dịch vụ", icon: Icons.clipboard },
  { key: "inventory", label: "Phụ tùng & Kho", icon: Icons.package },
  { key: "invoice", label: "Hóa đơn & Thanh toán", icon: Icons.creditCard },
  { key: "history", label: "Lịch sử sửa chữa", icon: Icons.history },
  { key: "notifications", label: "Thông báo", icon: Icons.bell, badge: 4 },
  { key: "reports", label: "Báo cáo – Thống kê", icon: Icons.barChart },
  { key: "staff", label: "Nhân viên", icon: Icons.userCheck },
  { key: "settings", label: "Tài khoản & Phân quyền", icon: Icons.settings },
  { key: "technician", label: "Công việc của tôi", icon: Icons.wrench },
  { key: "design-system", label: "Hệ thống giao diện", icon: Icons.info },
];

interface SidebarProps {
  active: string;
  onNavigate: (key: string) => void;
  role?: string;
  allowedPages?: readonly string[];
  mobileOpen?: boolean;
  onClose?: () => void;
  onLogout?: () => void;
}

export default function Sidebar({
  active,
  onNavigate,
  role = "manager",
  allowedPages,
  mobileOpen = false,
  onClose,
  onLogout,
}: SidebarProps) {
  const username = readSession()?.account.username ?? "";
  const visibleNav = allowedPages
    ? ALL_NAV_ITEMS.filter((item) => allowedPages.includes(item.key))
    : ALL_NAV_ITEMS;

  return (
    <aside className={`fixed left-0 top-0 z-30 flex h-dvh w-[min(18rem,86vw)] flex-shrink-0 flex-col bg-brand-dark text-white transition-transform duration-200 xl:w-60 xl:translate-x-0 ${mobileOpen ? "translate-x-0" : "-translate-x-full"}`}>
      <div className="flex min-h-[4.5rem] items-center border-b border-white/10 px-4">
        <div className="flex min-w-0 items-center gap-3">
          <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-accent text-white shadow-sm" aria-hidden="true">{Icons.car}</div>
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold leading-tight text-white">{GARAGE_NAME}</p>
            <p className="mt-0.5 text-xs leading-tight text-white/65">Hệ thống quản lý</p>
          </div>
        </div>
        <button type="button" onClick={onClose} aria-label="Đóng thanh điều hướng" className="ml-auto flex h-11 w-11 items-center justify-center rounded-md text-white/70 hover:bg-white/10 hover:text-white xl:hidden">{Icons.close}</button>
      </div>

      <nav className="flex-1 overflow-y-auto px-3 py-3" aria-label="Điều hướng chính">
        {visibleNav.map((item) => {
          const isActive = active === item.key;
          return (
            <button
              key={item.key}
              type="button"
              onClick={() => { onNavigate(item.key); onClose?.(); }}
              aria-current={isActive ? "page" : undefined}
              className={`group relative mb-1 flex min-h-12 w-full items-center gap-3 rounded-md border-l-[3px] px-3 text-left transition-all ${isActive ? "border-amber-400 bg-white/12 text-white" : "border-transparent text-white/75 hover:bg-white/8 hover:text-white"}`}
            >
              <span className={`flex-shrink-0 ${isActive ? "text-amber-400" : "text-white/60 group-hover:text-white/80"}`}>{item.icon}</span>
              <span className={`truncate text-sm font-medium ${isActive ? "font-semibold text-white" : ""}`}>{item.label}</span>
              {item.badge && <span className="ml-auto flex min-h-5 min-w-5 flex-shrink-0 items-center justify-center rounded-full bg-accent px-1.5 text-xs font-bold text-white" aria-label={`${item.badge} thông báo chưa đọc`}>{item.badge}</span>}
            </button>
          );
        })}
      </nav>

      <div className="border-t border-white/10 p-3">
        <div className="flex min-h-12 items-center gap-3 rounded-md px-2">
          <div className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-primary text-sm font-bold text-white shadow">{username.slice(0, 1).toUpperCase()}</div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-semibold text-white">{username}</p>
            <p className="truncate text-xs text-white/60">{ROLE_LABELS[role] ?? role}</p>
          </div>
          <button type="button" onClick={onLogout} className="flex h-11 w-11 items-center justify-center rounded-md text-white/60 hover:bg-white/10 hover:text-white" title="Đăng xuất" aria-label="Đăng xuất">
            {Icons.logOut}
          </button>
        </div>
      </div>
    </aside>
  );
}
