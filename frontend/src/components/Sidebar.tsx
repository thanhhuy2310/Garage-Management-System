import React from "react";
import { Icons } from "./ui";
import { GARAGE_NAME } from "../data";

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
  // Technician-specific
  { key: "technician", label: "Công việc của tôi", icon: Icons.wrench },
  { key: "design-system", label: "Design System", icon: Icons.info },
];

const ROLE_AVATARS: Record<string, { bg: string; initial: string; name: string; title: string }> = {
  admin: { bg: "from-purple-400 to-indigo-600", initial: "A", name: "Admin Hệ thống", title: "Quản trị viên" },
  manager: { bg: "from-blue-400 to-blue-600", initial: "B", name: "Nguyễn Hữu Bảo", title: "Quản lý" },
  receptionist: { bg: "from-emerald-400 to-emerald-600", initial: "T", name: "Phạm Minh Tuấn", title: "NV tiếp nhận" },
  technician: { bg: "from-orange-400 to-orange-600", initial: "K", name: "Trần Văn Khoa", title: "Kỹ thuật viên" },
  warehouse: { bg: "from-amber-400 to-amber-600", initial: "N", name: "Đỗ Văn Nam", title: "NV kho" },
  cashier: { bg: "from-pink-400 to-pink-600", initial: "H", name: "Lê Thị Hoa", title: "Thu ngân" },
};

interface SidebarProps {
  active: string;
  onNavigate: (key: string) => void;
  role?: string;
  allowedPages?: string[];
}

export default function Sidebar({ active, onNavigate, role = "manager", allowedPages }: SidebarProps) {
  const avatar = ROLE_AVATARS[role] ?? ROLE_AVATARS.manager;

  const visibleNav = allowedPages
    ? ALL_NAV_ITEMS.filter(item => allowedPages.includes(item.key))
    : ALL_NAV_ITEMS;

  return (
    <aside className="w-[220px] flex-shrink-0 h-screen flex flex-col bg-[#1e3a6e] text-white fixed left-0 top-0 z-30">
      {/* Logo */}
      <div className="px-5 py-4 border-b border-white/10">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-amber-500 rounded-xl flex items-center justify-center flex-shrink-0 shadow-md">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
              <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v9a2 2 0 0 1-2 2h-2"/>
              <circle cx="7.5" cy="17.5" r="2.5"/>
              <circle cx="17.5" cy="17.5" r="2.5"/>
            </svg>
          </div>
          <div className="min-w-0">
            <p className="text-xs font-bold leading-tight truncate text-white">{GARAGE_NAME}</p>
            <p className="text-[10px] text-white/50 leading-tight">Quản lý gara</p>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <nav className="flex-1 overflow-y-auto py-2 px-2">
        {visibleNav.map(item => {
          const isActive = active === item.key;
          return (
            <button
              key={item.key}
              onClick={() => onNavigate(item.key)}
              className={`w-full flex items-center gap-3 px-3 py-2.5 rounded-lg text-left mb-0.5 transition-all group relative ${
                isActive
                  ? "bg-white/15 text-white"
                  : "hover:bg-white/8 text-white/70 hover:text-white"
              }`}
              style={isActive ? { borderLeft: "3px solid #f59e0b", paddingLeft: "9px" } : { borderLeft: "3px solid transparent" }}
            >
              <span className={`flex-shrink-0 transition-all ${isActive ? "text-amber-400" : "text-white/60 group-hover:text-white/80"}`}>
                {item.icon}
              </span>
              <span className={`text-[13px] font-medium truncate ${isActive ? "text-white font-semibold" : ""}`}>
                {item.label}
              </span>
              {item.badge && (
                <span className="ml-auto bg-amber-500 text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full flex-shrink-0">
                  {item.badge}
                </span>
              )}
            </button>
          );
        })}
      </nav>

      {/* User */}
      <div className="px-3 py-3 border-t border-white/10">
        <div className="flex items-center gap-3 px-1">
          <div className={`w-8 h-8 bg-gradient-to-br ${avatar.bg} rounded-full flex items-center justify-center text-white text-sm font-bold flex-shrink-0 shadow`}>
            {avatar.initial}
          </div>
          <div className="min-w-0 flex-1">
            <p className="text-xs font-semibold text-white truncate">{avatar.name}</p>
            <p className="text-[10px] text-white/50 truncate">{avatar.title}</p>
          </div>
          <button className="p-1 rounded hover:bg-white/10 text-white/40 hover:text-white/70 transition-all flex-shrink-0" title="Đăng xuất">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"/><polyline points="16 17 21 12 16 7"/><line x1="21" y1="12" x2="9" y2="12"/>
            </svg>
          </button>
        </div>
      </div>
    </aside>
  );
}
