import React, { useState } from "react";
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
  "design-system": "Design System",
  mobile: "Ứng dụng Khách hàng (Mobile)",
};

const BREADCRUMBS: Record<string, { parent: string; parentKey?: string }> = {
  reception: { parent: "Lịch hẹn", parentKey: "appointments" },
  repair: { parent: "Tiếp nhận xe", parentKey: "reception" },
  quotation: { parent: "Phiếu sửa chữa", parentKey: "repair" },
  invoice: { parent: "Phiếu sửa chữa", parentKey: "repair" },
};

const ROLE_LABELS: Record<string, string> = {
  admin: "Quản trị viên",
  manager: "Quản lý",
  receptionist: "NV tiếp nhận",
  technician: "Kỹ thuật viên",
  warehouse: "NV kho",
  cashier: "Thu ngân",
};

const ROLE_INITIALS: Record<string, string> = {
  admin: "A", manager: "B", receptionist: "T", technician: "K", warehouse: "N", cashier: "H",
};

const ROLE_AVATAR_BG: Record<string, string> = {
  admin: "from-purple-400 to-indigo-600",
  manager: "from-blue-400 to-blue-600",
  receptionist: "from-emerald-400 to-emerald-600",
  technician: "from-orange-400 to-orange-600",
  warehouse: "from-amber-400 to-amber-600",
  cashier: "from-pink-400 to-pink-600",
};

interface HeaderProps {
  page: string;
  onMobileToggle?: () => void;
  role?: string;
}

export default function Header({ page, onMobileToggle, role = "manager" }: HeaderProps) {
  const [showNoti, setShowNoti] = useState(false);
  const breadcrumb = BREADCRUMBS[page];

  return (
    <header className="h-14 bg-white border-b border-[#dde3ec] flex items-center justify-between px-6 sticky top-0 z-20 flex-shrink-0">
      {/* Left: title + breadcrumb */}
      <div className="flex items-center gap-2">
        {breadcrumb && (
          <span className="text-xs text-slate-400">{breadcrumb.parent} /</span>
        )}
        <h1 className="text-sm font-semibold text-slate-800">{PAGE_TITLES[page] ?? page}</h1>
        {page === "dashboard" && (
          <span className="text-xs text-slate-400 font-mono bg-slate-100 px-2 py-0.5 rounded-md">Thứ Ba, 17/09/2024</span>
        )}
        {page === "technician" && (
          <span className="text-xs bg-orange-100 text-orange-700 px-2 py-0.5 rounded-full font-medium">Ca sáng 07:00–12:00</span>
        )}
      </div>

      {/* Right: tools */}
      <div className="flex items-center gap-2">
        {/* Search */}
        <div className="relative hidden md:block">
          <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 pointer-events-none">{Icons.search}</span>
          <input
            type="text"
            placeholder="Tìm kiếm toàn bộ..."
            className="h-8 pl-8 pr-3 bg-slate-50 border border-[#dde3ec] rounded-lg text-xs w-48 placeholder:text-slate-400 focus:outline-none focus:border-[#3b6fd4] focus:ring-1 focus:ring-[#3b6fd4] focus:bg-white transition-all"
          />
        </div>

        {/* Mobile preview toggle */}
        {onMobileToggle && (
          <button
            onClick={onMobileToggle}
            className="hidden lg:flex h-8 px-3 bg-[#e8eef7] text-[#1e3a6e] text-xs font-medium rounded-lg items-center gap-1.5 hover:bg-[#dce6f5] transition-all border border-[#c5d3e8]"
            title="Xem app khách hàng"
          >
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <rect x="5" y="2" width="14" height="20" rx="2" ry="2"/>
              <line x1="12" y1="18" x2="12.01" y2="18"/>
            </svg>
            App KH
          </button>
        )}

        {/* Notifications */}
        <div className="relative">
          <button
            onClick={() => setShowNoti(s => !s)}
            className="relative w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 text-slate-500 transition-all"
          >
            {Icons.bell}
            <span className="absolute top-1 right-1 w-2 h-2 bg-red-500 rounded-full border border-white" />
          </button>
          {showNoti && (
            <div className="absolute right-0 top-10 bg-white rounded-xl border border-[#dde3ec] shadow-xl w-80 z-50">
              <div className="flex items-center justify-between p-4 border-b border-[#dde3ec]">
                <p className="font-semibold text-slate-800 text-sm">Thông báo</p>
                <button onClick={() => setShowNoti(false)} className="text-slate-400 hover:text-slate-600 text-lg leading-none">×</button>
              </div>
              <div className="max-h-80 overflow-y-auto">
                {[
                  { icon: "📅", text: "Nguyễn Văn An đặt lịch bảo dưỡng lúc 08:00", time: "08:30", unread: true },
                  { icon: "🔧", text: "Phiếu PSC003 xe 51D-567.89 hoàn tất sửa chữa", time: "15:45 hôm qua", unread: true },
                  { icon: "⚠️", text: "Lọc dầu Toyota còn 12 cái – dưới mức tối thiểu", time: "09:00 hôm qua", unread: false },
                  { icon: "💰", text: "Hóa đơn HD001 đã thanh toán 550.000 VNĐ", time: "16:20 hôm qua", unread: false },
                ].map((n, i) => (
                  <div key={i} className={`flex items-start gap-3 p-3 hover:bg-slate-50 cursor-pointer border-b border-[#f1f5f9] last:border-0 ${n.unread ? "bg-blue-50/50" : ""}`}>
                    <span className="text-lg flex-shrink-0">{n.icon}</span>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs text-slate-700 leading-relaxed">{n.text}</p>
                      <p className="text-[10px] text-slate-400 mt-0.5">{n.time}</p>
                    </div>
                    {n.unread && <span className="w-2 h-2 bg-blue-500 rounded-full flex-shrink-0 mt-1" />}
                  </div>
                ))}
              </div>
              <div className="p-3 text-center border-t border-[#dde3ec]">
                <button onClick={() => setShowNoti(false)} className="text-xs text-[#1e3a6e] font-medium hover:underline">Xem tất cả thông báo</button>
              </div>
            </div>
          )}
        </div>

        {/* Avatar / user menu */}
        <div className="flex items-center gap-2 pl-1 border-l border-[#dde3ec] ml-1 cursor-pointer group">
          <div className={`w-7 h-7 bg-gradient-to-br ${ROLE_AVATAR_BG[role] || "from-blue-400 to-blue-600"} rounded-full flex items-center justify-center text-white text-xs font-bold`}>
            {ROLE_INITIALS[role] ?? "U"}
          </div>
          <div className="hidden md:block">
            <p className="text-xs font-semibold text-slate-700 leading-tight">{
              { admin: "Admin", manager: "Nguyễn Hữu Bảo", receptionist: "Phạm Minh Tuấn", technician: "Trần Văn Khoa", warehouse: "Đỗ Văn Nam", cashier: "Lê Thị Hoa" }[role] ?? "Nhân viên"
            }</p>
            <p className="text-[10px] text-slate-400 leading-tight">{ROLE_LABELS[role]}</p>
          </div>
        </div>
      </div>
    </header>
  );
}
