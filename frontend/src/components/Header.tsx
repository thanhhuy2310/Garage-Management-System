import { readSession } from "../api/session"
import { Icons } from "./ui"

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
}

export const ROLE_LABELS: Record<string, string> = {
  admin: "Quản trị viên",
  manager: "Quản lý",
  receptionist: "Nhân viên tiếp nhận",
  technician: "Kỹ thuật viên",
  warehouse: "Nhân viên kho",
}

interface HeaderProps {
  page: string
  role?: string
  onMenuToggle?: () => void
}

export default function Header({
  page,
  role = "manager",
  onMenuToggle,
}: HeaderProps) {
  const username = readSession()?.account.username ?? ""

  return (
    <header className="sticky top-0 z-20 flex min-h-[4.5rem] flex-shrink-0 items-center justify-between gap-3 border-b border-border bg-white px-3 sm:px-5 lg:px-6">
      <div className="flex min-w-0 items-center gap-2">
        <button
          type="button"
          onClick={onMenuToggle}
          aria-label="Mở thanh điều hướng"
          className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-md text-slate-600 hover:bg-slate-100 xl:hidden"
        >
          {Icons.menu}
        </button>
        <h1 className="truncate text-lg font-bold text-foreground sm:text-xl">
          {PAGE_TITLES[page] ?? page}
        </h1>
      </div>
      <div className="flex min-w-0 items-center gap-3">
        <div className="hidden min-w-0 text-right sm:block">
          <p className="max-w-48 truncate text-sm font-semibold text-foreground">
            {username}
          </p>
          <p className="text-xs text-muted-foreground">
            {ROLE_LABELS[role] ?? role}
          </p>
        </div>
        <span
          className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-primary text-sm font-bold text-white"
          aria-label={username}
        >
          {username.slice(0, 1).toUpperCase()}
        </span>
      </div>
    </header>
  )
}
