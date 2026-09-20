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
  admin: { label: "Quản trị viên", name: "Admin", initial: "A", avatar: "bg-violet-600" },
  manager: { label: "Quản lý", name: "Nguyễn Hữu Bảo", initial: "B", avatar: "bg-blue-600" },
  receptionist: { label: "Nhân viên tiếp nhận", name: "Phạm Minh Tuấn", initial: "T", avatar: "bg-emerald-600" },
  technician: { label: "Kỹ thuật viên", name: "Trần Văn Khoa", initial: "K", avatar: "bg-orange-600" },
  warehouse: { label: "Nhân viên kho", name: "Đỗ Văn Nam", initial: "N", avatar: "bg-amber-600" },
};

const QUICK_NOTIFICATIONS = [
  { icon: Icons.calendar, text: "Nguyễn Văn An đặt lịch bảo dưỡng lúc 08:00", time: "08:30", unread: true },
  { icon: Icons.wrench, text: "Phiếu PSC003 đã hoàn tất sửa chữa", time: "15:45 hôm qua", unread: true },
  { icon: Icons.alertTriangle, text: "Lọc dầu Toyota dưới mức tồn tối thiểu", time: "09:00 hôm qua", unread: false },
];

interface HeaderProps {
  page: string;
  role?: string;
  onMenuToggle?: () => void;
}

export default function Header({
  page,
  role = "manager",
  onMenuToggle,
}: HeaderProps) {
  const [showNotifications, setShowNotifications] = useState(false);
  const user = ROLE_INFO[role] ?? ROLE_INFO.manager;

  return (
    <header className="sticky top-0 z-20 flex min-h-[4.5rem] flex-shrink-0 items-center justify-between border-b border-border bg-white px-3 sm:px-5 lg:px-6">
      <div className="flex min-w-0 items-center gap-2">
        <button
          type="button"
          onClick={onMenuToggle}
          aria-label="Mở thanh điều hướng"
          className="mr-1 flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-md text-slate-600 hover:bg-slate-100 xl:hidden"
        >
          {Icons.menu}
        </button>
        {BREADCRUMBS[page] && <span className="hidden text-xs text-slate-500 2xl:inline">{BREADCRUMBS[page]} /</span>}
        <h1 className="truncate text-lg font-bold tracking-tight text-slate-900 sm:text-xl">{PAGE_TITLES[page] ?? page}</h1>
        {page === "dashboard" && (
          <span className="hidden rounded-md bg-slate-100 px-2 py-1 font-mono text-xs text-slate-600 2xl:inline">17/09/2026</span>
        )}
        {page === "technician" && (
          <span className="hidden rounded-full bg-warning-soft px-2 py-0.5 text-xs font-medium text-warning sm:inline">Ca sáng 07:00–12:00</span>
        )}
      </div>

      <div className="ml-3 flex flex-shrink-0 items-center gap-2">
        <div className="relative hidden xl:block">
          <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-slate-400">{Icons.search}</span>
          <input
            type="search"
            aria-label="Tìm kiếm toàn bộ"
            placeholder="Tìm kiếm toàn bộ..."
            className="h-11 w-56 rounded-md border border-border bg-slate-50 pl-9 pr-3 text-sm transition-all placeholder:text-slate-400 focus:border-ring focus:bg-white focus:ring-2 focus:ring-ring/15"
          />
        </div>

        <div className="relative">
          <button
            type="button"
            onClick={() => setShowNotifications((open) => !open)}
            aria-label="Mở thông báo"
            aria-expanded={showNotifications}
            className="relative flex h-11 w-11 items-center justify-center rounded-md text-slate-600 transition-all hover:bg-slate-100"
          >
            {Icons.bell}
            <span className="absolute right-1 top-1 h-2 w-2 rounded-full border border-white bg-danger" />
          </button>
          {showNotifications && (
            <div className="dropdown-enter absolute right-0 top-12 z-50 w-[min(22rem,calc(100vw-1.5rem))] rounded-lg border border-border bg-white shadow-xl">
              <div className="flex items-center justify-between border-b border-border p-4">
                <p className="text-sm font-semibold text-slate-800">Thông báo</p>
                <button type="button" onClick={() => setShowNotifications(false)} aria-label="Đóng thông báo" className="flex h-11 w-11 items-center justify-center rounded-md text-slate-500 hover:bg-slate-100 hover:text-slate-800">{Icons.close}</button>
              </div>
              {QUICK_NOTIFICATIONS.map((notification, index) => (
                <div key={index} className={`flex items-start gap-3 border-b border-slate-100 p-3 last:border-0 ${notification.unread ? "bg-info-soft/50" : ""}`}>
                  <span className="mt-0.5 text-primary" aria-hidden="true">{notification.icon}</span>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm leading-relaxed text-slate-700">{notification.text}</p>
                    <p className="mt-1 text-xs text-slate-500">{notification.time}</p>
                  </div>
                  {notification.unread && <span className="mt-1 h-2 w-2 flex-shrink-0 rounded-full bg-info" />}
                </div>
              ))}
            </div>
          )}
        </div>

        <div className="ml-1 flex items-center gap-2 border-l border-border pl-2">
          <div className={`flex h-9 w-9 items-center justify-center rounded-full ${user.avatar} text-sm font-bold text-white`}>{user.initial}</div>
          <div className="hidden 2xl:block">
            <p className="text-sm font-semibold leading-tight text-slate-800">{user.name}</p>
            <p className="mt-0.5 text-xs leading-tight text-slate-500">{user.label}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
