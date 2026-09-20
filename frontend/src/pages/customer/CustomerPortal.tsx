import { useState } from "react";
import { Button, Card, Icons, Input } from "../../components/ui";
import CustomerLayout from "../../layouts/CustomerLayout";
import { khachHang } from "../../mock/data";
import type { CustomerPage } from "../../router";
import CustomerAppointments from "./CustomerAppointments";
import CustomerHistory from "./CustomerHistory";
import CustomerNotifications from "./CustomerNotifications";
import CustomerOverview from "./CustomerOverview";
import CustomerQuotations from "./CustomerQuotations";
import CustomerTracking from "./CustomerTracking";

export type CustomerTab = CustomerPage;

const TABS: { key: CustomerTab; label: string; icon: React.ReactNode }[] = [
  { key: "overview", label: "Tổng quan", icon: Icons.home },
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
  page: CustomerPage;
  onNavigate: (page: CustomerPage) => void;
}

function ProfileTab() {
  const customer = khachHang.find((c) => c.MaKhachHang === CURRENT_CUSTOMER_ID);
  const [done, setDone] = useState(false);
  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <Card className="space-y-4 p-4 sm:p-5">
        <h3 className="ui-card-title">Thông tin cá nhân</h3>
        <div className="rounded-lg bg-surface-subtle p-3 text-sm">
          <p className="font-semibold text-foreground">{customer?.HoTen}</p>
          <p className="mt-1 text-muted-foreground">{customer?.SoDienThoai} · {customer?.Email}</p>
          <p className="mt-0.5 text-muted-foreground">{customer?.DiaChi}</p>
        </div>
        <p className="text-xs text-muted-foreground">Muốn cập nhật thông tin, liên hệ lễ tân gara để được hỗ trợ.</p>
      </Card>
      <Card className="p-4 sm:p-5">
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

export default function CustomerPortal({ onLogout, page, onNavigate }: CustomerPortalProps) {
  const customer = khachHang.find((c) => c.MaKhachHang === CURRENT_CUSTOMER_ID);

  return (
    <CustomerLayout
      onLogout={onLogout}
      customerName={customer?.HoTen}
      navigation={
        <nav aria-label="Khu vực khách hàng" className="mx-auto w-full max-w-6xl px-4">
          <div className="flex gap-2 overflow-x-auto pb-3" role="tablist">
            {TABS.map((item) => (
              <button
                key={item.key}
                type="button"
                role="tab"
                aria-selected={page === item.key}
                onClick={() => onNavigate(item.key)}
                className={`flex min-h-11 flex-shrink-0 items-center gap-2 rounded-md px-3.5 text-sm font-semibold transition-all ${
                  page === item.key ? "bg-primary text-primary-foreground" : "text-slate-600 hover:bg-surface-subtle"
                }`}
              >
                <span aria-hidden="true">{item.icon}</span>
                {item.label}
              </button>
            ))}
          </div>
        </nav>
      }
    >
      <div className="space-y-6">
        {page === "overview" && <CustomerOverview onNavigate={onNavigate} />}
        {page === "appointments" && <CustomerAppointments />}
        {page === "quotations" && <CustomerQuotations />}
        {page === "tracking" && <CustomerTracking />}
        {page === "history" && <CustomerHistory />}
        {page === "notifications" && <CustomerNotifications />}
        {page === "profile" && <ProfileTab />}
      </div>
    </CustomerLayout>
  );
}
