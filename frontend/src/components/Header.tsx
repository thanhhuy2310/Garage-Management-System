import { useState } from "react";
import { Icons } from "./ui";

const PAGE_TITLES: Record<string, string> = {
  dashboard: "Tổng quan",
  appointments: "Lịch hẹn",
  reception: "Tiếp nhận xe",
  repair: "Phiếu sửa chữa",
  quotation: "Báo giá",
  customers: "Khách hàng",
  vehicles: "Xe",
  services: "Dịch vụ",
  inventory: "Phụ tùng & Kho",
  invoice: "Hóa đơn & Thanh toán",
  history: "Lịch sử sửa chữa",
  notifications: "Thông báo",
  reports: "Báo cáo – Thống kê",
  staff: "Nhân viên",
  settings: "Tài khoản & Phân quyền",
  technician: "Công việc của tôi",
  "design-system": "Hệ thống giao diện",
  mobile: "Ứng dụng Khách hàng",
};

const BREADCRUMBS: Record<string, string> = {
  reception: "Lịch hẹn",
  repair: "Tiếp nhận xe",
  quotation: "Phiếu sửa chữa",
  invoice: "Phiếu sửa chữa",
};

const ROLE_INFO: Record<string, { label: string; name: string; initial: string; avatar: string }> = {
  admin: { label: "Quản trị viên", name: "Admin", initial: "A", avatar: "from-purple-400 to-indigo-600" },
  manager: { label: "Quản lý", name: "Nguyễn Hữu Bảo", initial: "B", avatar: "from-blue-400 to-blue-600" },
  receptionist: { label: "NV tiếp nhận", name: "Phạm Minh Tuấn", initial: "T", avatar: "from-emerald-400 to-emerald-600" },
  technician: { label: "Kỹ thuật viên", name: "Trần Văn Khoa", initial: "K", avatar: "from-orange-400 to-orange-600" },
  warehouse: { label: "NV kho", name: "Đỗ Văn Nam", initial: "N", avatar: "from-amber-400 to-amber-600" },
  cashier: { label: "Thu ngân", name: "Lê Thị Hoa", initial: "H", avatar: "from-pink-400 to-pink-600" },
};

const QUICK_NOTIFICATIONS = [
  { icon: "📅", text: "Nguyễn Văn An đặt lịch bảo dưỡng lúc 08:00", time: "08:30", unread: true },
  { icon: "🔧", text: "Phiếu PSC003 đã hoàn tất sửa chữa", time: "15:45 hôm qua", unread: true },
  { icon: "⚠️", text: "Lọc dầu Toyota dưới mức tồn tối thiểu", time: "09:00 hôm qua", unread: false },
];

interface HeaderProps {
  page: string;
  role?: string;
  onMenuToggle?: () => void;
  onMobileToggle?: () => void;
}

export default function Header({
  page,
  role = "manager",
  onMenuToggle,
  onMobileToggle,
}: HeaderProps) {
  const [showNotifications, setShowNotifications] = useState(false);
  const user = ROLE_INFO[role] ?? ROLE_INFO.manager;

  return (
    <header className="sticky top-0 z-20 flex h-14 flex-shrink-0 items-center justify-between border-b border-[#dde3ec] bg-white px-3 sm:px-6">
      <div className="flex min-w-0 items-center gap-2">
        <button
          type="button"
          onClick={onMenuToggle}
          aria-label="Mở thanh điều hướng"
          className="mr-1 flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-lg text-slate-600 hover:bg-slate-100 lg:hidden"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <line x1="3" y1="6" x2="21" y2="6" />
            <line x1="3" y1="12" x2="21" y2="12" />
            <line x1="3" y1="18" x2="21" y2="18" />
          </svg>
        </button>
        {BREADCRUMBS[page] && <span className="hidden text-xs text-slate-400 sm:inline">{BREADCRUMBS[page]} /</span>}
        <h1 className="truncate text-sm font-semibold text-slate-800">{PAGE_TITLES[page] ?? page}</h1>
        {page === "dashboard" && (
          <span className="hidden rounded-md bg-slate-100 px-2 py-0.5 font-mono text-xs text-slate-400 xl:inline">17/09/2024</span>
        )}
        {page === "technician" && (
          <span className="hidden rounded-full bg-orange-100 px-2 py-0.5 text-xs font-medium text-orange-700 sm:inline">Ca sáng 07:00–12:00</span>
        )}
      </div>

      <div className="ml-3 flex flex-shrink-0 items-center gap-2">
        <div className="relative hidden md:block">
          <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">{Icons.search}</span>
          <input
            type="search"
            aria-label="Tìm kiếm toàn bộ"
            placeholder="Tìm kiếm toàn bộ..."
            className="h-8 w-48 rounded-lg border border-[#dde3ec] bg-slate-50 pl-8 pr-3 text-xs transition-all placeholder:text-slate-400 focus:border-[#3b6fd4] focus:bg-white focus:outline-none focus:ring-1 focus:ring-[#3b6fd4]"
          />
        </div>

        {onMobileToggle && (
          <button
            type="button"
            onClick={onMobileToggle}
            className="hidden h-8 items-center gap-1.5 rounded-lg border border-[#c5d3e8] bg-[#e8eef7] px-3 text-xs font-medium text-[#1e3a6e] transition-all hover:bg-[#dce6f5] lg:flex"
            title="Xem ứng dụng khách hàng"
          >
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <rect x="5" y="2" width="14" height="20" rx="2" /><line x1="12" y1="18" x2="12.01" y2="18" />
            </svg>
            App KH
          </button>
        )}

        <div className="relative">
          <button
            type="button"
            onClick={() => setShowNotifications((open) => !open)}
            aria-label="Mở thông báo"
            aria-expanded={showNotifications}
            className="relative flex h-8 w-8 items-center justify-center rounded-lg text-slate-500 transition-all hover:bg-slate-100"
          >
            {Icons.bell}
            <span className="absolute right-1 top-1 h-2 w-2 rounded-full border border-white bg-red-500" />
          </button>
          {showNotifications && (
            <div className="absolute right-0 top-10 z-50 w-[min(20rem,calc(100vw-1.5rem))] rounded-xl border border-[#dde3ec] bg-white shadow-xl">
              <div className="flex items-center justify-between border-b border-[#dde3ec] p-4">
                <p className="text-sm font-semibold text-slate-800">Thông báo</p>
                <button type="button" onClick={() => setShowNotifications(false)} aria-label="Đóng thông báo" className="text-lg leading-none text-slate-400 hover:text-slate-600">×</button>
              </div>
              {QUICK_NOTIFICATIONS.map((notification, index) => (
                <div key={index} className={`flex items-start gap-3 border-b border-slate-100 p-3 last:border-0 ${notification.unread ? "bg-blue-50/50" : ""}`}>
                  <span className="text-lg">{notification.icon}</span>
                  <div className="min-w-0 flex-1">
                    <p className="text-xs leading-relaxed text-slate-700">{notification.text}</p>
                    <p className="mt-0.5 text-[10px] text-slate-400">{notification.time}</p>
                  </div>
                  {notification.unread && <span className="mt-1 h-2 w-2 flex-shrink-0 rounded-full bg-blue-500" />}
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="ml-1 flex items-center gap-2 border-l border-[#dde3ec] pl-2">
          <div className={`flex h-7 w-7 items-center justify-center rounded-full bg-gradient-to-br ${user.avatar} text-xs font-bold text-white`}>{user.initial}</div>
          <div className="hidden md:block">
            <p className="text-xs font-semibold leading-tight text-slate-700">{user.name}</p>
            <p className="text-[10px] leading-tight text-slate-400">{user.label}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
