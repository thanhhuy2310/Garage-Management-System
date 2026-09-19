import type { ReactNode } from "react";
import { GARAGE_NAME } from "../data";
import { Button, Icons } from "../components/ui";

interface CustomerLayoutProps {
  children: ReactNode;
  onLogout: () => void;
  navigation?: ReactNode;
  customerName?: string;
}

export default function CustomerLayout({ children, onLogout, navigation, customerName = "Khách hàng" }: CustomerLayoutProps) {
  return (
    <div className="min-h-screen bg-background text-foreground">
      <a href="#customer-content" className="skip-link">Bỏ qua đến nội dung chính</a>
      <header className="sticky top-0 z-30 border-b border-border bg-surface/95 backdrop-blur">
        <div className="mx-auto flex min-h-16 w-full max-w-6xl items-center justify-between gap-3 px-4 sm:px-6">
          <div className="flex min-w-0 items-center gap-3">
            <span className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-primary text-white" aria-hidden="true">{Icons.wrench}</span>
            <div className="min-w-0">
              <p className="truncate text-sm font-bold text-foreground">{GARAGE_NAME}</p>
              <p className="truncate text-xs text-muted-foreground">Xin chào, {customerName}</p>
            </div>
          </div>
          <Button size="sm" variant="outline" onClick={onLogout}>Đăng xuất</Button>
        </div>
        {navigation}
      </header>
      <main id="customer-content" tabIndex={-1} className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6">
        {children}
      </main>
    </div>
  );
}
