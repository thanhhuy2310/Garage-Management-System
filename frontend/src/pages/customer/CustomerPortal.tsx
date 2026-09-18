import { useState } from "react";
import { Button, Card, Icons, Input } from "../../components/ui";
import { GARAGE_NAME } from "../../data";
import { khachHang } from "../../mock/data";

export type CustomerTab = "appointments" | "quotations" | "tracking" | "history" | "notifications" | "profile";

const TABS: { key: CustomerTab; label: string; icon: React.ReactNode }[] = [
  { key: "appointments", label: "Lịch hẹn", icon: Icons.calendar },
  { key: "quotations", label: "Báo giá", icon: Icons.fileText },
  { key: "tracking", label: "Tiến độ sửa chữa", icon: Icons.wrench },
  { key: "history", label: "Lịch sử", icon: Icons.history },
  { key: "notifications", label: "Thông báo", icon: Icons.bell },
  { key: "profile", label: "Hồ sơ", icon: Icons.userCheck },
];

// Demo: tài khoản khachhang.an ↔ KH001 (Nguyễn Văn An).
const CURRENT_CUSTOMER_ID = "KH001";

interface CustomerPortalProps {
  onLogout: () => void;
}

function TabPlaceholder({ title, note }: { title: string; note: string }) {
  return (
    <Card className="p-10 text-center">
      <p className="ui-card-title">{title}</p>
      <p className="ui-secondary-text mx-auto mt-1 max-w-md text-sm">{note}</p>
    </Card>
  );
}

function ProfileTab() {
  const customer = khachHang.find((c) => c.MaKhachHang === CURRENT_CUSTOMER_ID);
  const [done, setDone] = useState(false);
  return (
    <div className="grid gap-4 lg:grid-cols-2">
      <Card className="space-y-3 p-5">
        <h3 className="ui-card-title">Thông tin cá nhân</h3>
        <div className="rounded-lg bg-surface-subtle p-3 text-sm">
          <p className="font-semibold text-foreground">{customer?.HoTen}</p>
          <p className="mt-1 text-muted-foreground">{customer?.SoDienThoai} · {customer?.Email}</p>
          <p className="mt-0.5 text-muted-foreground">{customer?.DiaChi}</p>
        </div>
        <p className="text-xs text-muted-foreground">Muốn cập nhật thông tin, liên hệ lễ tân gara để được hỗ trợ.</p>
      </Card>
      <Card className="p-5">
        <h3 className="ui-card-title">Đổi mật khẩu</h3>
        {done ? (
          <p className="mt-3 rounded-md bg-success-soft px-3 py-2 text-sm text-success" role="status">
            Đổi mật khẩu thành công (demo).
          </p>
        ) : (
          <form
            className="mt-3 space-y-4"
            onSubmit={(e) => { e.preventDefault(); setDone(true); }}
          >
            <Input label="Mật khẩu hiện tại *" type="password" required />
            <Input label="Mật khẩu mới *" type="password" required />
            <Input label="Nhập lại mật khẩu mới *" type="password" required />
            <div className="flex justify-end">
              <Button type="submit">Đổi mật khẩu</Button>
            </div>
          </form>
        )}
      </Card>
    </div>
  );
}

export default function CustomerPortal({ onLogout }: CustomerPortalProps) {
  const [tab, setTab] = useState<CustomerTab>("appointments");
  const customer = khachHang.find((c) => c.MaKhachHang === CURRENT_CUSTOMER_ID);

  return (
    <div className="min-h-screen bg-background">
      {/* Customer header */}
      <header className="sticky top-0 z-30 border-b border-border bg-white">
        <div className="mx-auto flex h-16 w-full max-w-6xl items-center justify-between gap-3 px-4">
          <div className="flex min-w-0 items-center gap-2.5">
            <span className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg bg-primary text-white" aria-hidden="true">
              {Icons.wrench}
            </span>
            <div className="min-w-0">
              <p className="truncate text-sm font-bold text-foreground">{GARAGE_NAME}</p>
              <p className="truncate text-xs text-muted-foreground">Xin chào, {customer?.HoTen}</p>
            </div>
          </div>
          <Button size="sm" variant="outline" onClick={onLogout}>Đăng xuất</Button>
        </div>
        {/* Customer nav */}
        <nav aria-label="Khu vực khách hàng" className="mx-auto w-full max-w-6xl px-4">
          <div className="flex gap-1 overflow-x-auto pb-2" role="tablist">
            {TABS.map((item) => (
              <button
                key={item.key}
                type="button"
                role="tab"
                aria-selected={tab === item.key}
                onClick={() => setTab(item.key)}
                className={`flex min-h-10 flex-shrink-0 items-center gap-1.5 rounded-md px-3 text-[13px] font-medium transition-all ${
                  tab === item.key ? "bg-primary text-primary-foreground" : "text-slate-600 hover:bg-surface-subtle"
                }`}
              >
                <span aria-hidden="true">{item.icon}</span>
                {item.label}
              </button>
            ))}
          </div>
        </nav>
      </header>

      <main className="mx-auto w-full max-w-6xl space-y-4 px-4 py-6">
        {tab === "appointments" && <TabPlaceholder title="Lịch hẹn của tôi" note="Đặt lịch mới, xem lịch hẹn sắp tới — hoàn thiện ở phần Customer Appointments." />}
        {tab === "quotations" && <TabPlaceholder title="Báo giá" note="Xem và xác nhận báo giá — hoàn thiện ở phần Customer Quotations." />}
        {tab === "tracking" && <TabPlaceholder title="Tiến độ sửa chữa" note="Theo dõi xe đang sửa theo thời gian thực — hoàn thiện ở phần Repair Tracking." />}
        {tab === "history" && <TabPlaceholder title="Lịch sử sửa chữa" note="Toàn bộ lần sửa chữa, bảo dưỡng đã hoàn tất — hoàn thiện ở phần Repair History." />}
        {tab === "notifications" && <TabPlaceholder title="Thông báo" note="Nhắc bảo dưỡng, trạng thái lịch hẹn, báo giá mới — hoàn thiện ở phần Notifications." />}
        {tab === "profile" && <ProfileTab />}
      </main>
    </div>
  );
}
