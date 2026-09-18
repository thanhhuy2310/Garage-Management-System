import { GARAGE_NAME } from "../data";
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

const ROLE_AVATARS: Record<string, { bg: string; initial: string; name: string; title: string }> = {
  admin: { bg: "from-purple-400 to-indigo-600", initial: "A", name: "Admin Hệ thống", title: "Quản trị viên" },
  manager: { bg: "from-blue-400 to-blue-600", initial: "B", name: "Nguyễn Hữu Bảo", title: "Quản lý" },
  receptionist: { bg: "from-emerald-400 to-emerald-600", initial: "T", name: "Phạm Minh Tuấn", title: "NV tiếp nhận" },
  technician: { bg: "from-orange-400 to-orange-600", initial: "K", name: "Trần Văn Khoa", title: "Kỹ thuật viên" },
  warehouse: { bg: "from-amber-400 to-amber-600", initial: "N", name: "Đỗ Văn Nam", title: "NV kho" },
};

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
  const avatar = ROLE_AVATARS[role] ?? ROLE_AVATARS.manager;
  const visibleNav = allowedPages
    ? ALL_NAV_ITEMS.filter((item) => allowedPages.includes(item.key))
    : ALL_NAV_ITEMS;

  return (
    <aside className={`fixed left-0 top-0 z-30 flex h-dvh w-60 flex-shrink-0 flex-col bg-primary text-white transition-transform duration-200 xl:translate-x-0 ${mobileOpen ? "translate-x-0" : "-translate-x-full"}`}>
      <div className="flex min-h-16 items-center border-b border-white/10 px-4">
        <div className="flex min-w-0 items-center gap-3">
          <div className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-amber-600 shadow-sm">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
              <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v9a2 2 0 0 1-2 2h-2" />
              <circle cx="7.5" cy="17.5" r="2.5" /><circle cx="17.5" cy="17.5" r="2.5" />
            </svg>
          </div>
          <div className="min-w-0">
            <p className="truncate text-sm font-semibold leading-tight text-white">{GARAGE_NAME}</p>
            <p className="mt-0.5 text-xs leading-tight text-white/65">Hệ thống quản lý</p>
          </div>
        </div>
        <button type="button" onClick={onClose} aria-label="Đóng thanh điều hướng" className="ml-auto flex h-10 w-10 items-center justify-center rounded-md text-xl text-white/70 hover:bg-white/10 hover:text-white xl:hidden">×</button>
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
              className={`group relative mb-1 flex min-h-11 w-full items-center gap-3 rounded-md border-l-[3px] px-3 text-left transition-all ${isActive ? "border-amber-400 bg-white/12 text-white" : "border-transparent text-white/75 hover:bg-white/8 hover:text-white"}`}
            >
              <span className={`flex-shrink-0 ${isActive ? "text-amber-400" : "text-white/60 group-hover:text-white/80"}`}>{item.icon}</span>
              <span className={`truncate text-sm font-medium ${isActive ? "font-semibold text-white" : ""}`}>{item.label}</span>
              {item.badge && <span className="ml-auto flex min-h-5 min-w-5 flex-shrink-0 items-center justify-center rounded-full bg-amber-500 px-1.5 text-xs font-bold text-white" aria-label={`${item.badge} thông báo chưa đọc`}>{item.badge}</span>}
            </button>
          );
        })}
      </nav>

      <div className="border-t border-white/10 p-3">
        <div className="flex min-h-12 items-center gap-3 rounded-md px-2">
          <div className={`flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-gradient-to-br ${avatar.bg} text-sm font-bold text-white shadow`}>{avatar.initial}</div>
          <div className="min-w-0 flex-1">
            <p className="truncate text-sm font-semibold text-white">{avatar.name}</p>
            <p className="truncate text-xs text-white/60">{avatar.title}</p>
          </div>
          <button type="button" onClick={onLogout} className="flex h-10 w-10 items-center justify-center rounded-md text-white/60 hover:bg-white/10 hover:text-white" title="Đăng xuất" aria-label="Đăng xuất">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" y1="12" x2="9" y2="12" />
            </svg>
          </button>
        </div>
      </div>
    </aside>
  );
}
