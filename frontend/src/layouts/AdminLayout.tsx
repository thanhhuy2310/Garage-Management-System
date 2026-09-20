import { useState, type ReactNode } from "react";
import Header from "../components/Header";
import PageShell from "../components/PageShell";
import Sidebar from "../components/Sidebar";
import type { AdminPage, Role } from "../router";

interface AdminLayoutProps {
  children: ReactNode;
  page: AdminPage;
  role: Role;
  allowedPages: readonly AdminPage[];
  onNavigate: (page: AdminPage) => void;
  onLogout: () => void;
}

export default function AdminLayout({ children, page, role, allowedPages, onNavigate, onLogout }: AdminLayoutProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const navigate = (nextPage: string) => {
    onNavigate(nextPage as AdminPage);
    setSidebarOpen(false);
  };

  return (
    <div className="flex h-dvh overflow-hidden bg-background">
      <a href="#admin-content" className="skip-link">Bỏ qua đến nội dung chính</a>
      <Sidebar
        active={page}
        onNavigate={navigate}
        role={role}
        allowedPages={allowedPages}
        mobileOpen={sidebarOpen}
        onClose={() => setSidebarOpen(false)}
        onLogout={onLogout}
      />
      {sidebarOpen && (
        <button
          type="button"
          aria-label="Đóng thanh điều hướng"
          onClick={() => setSidebarOpen(false)}
          className="sidebar-backdrop-enter fixed inset-0 z-20 bg-slate-950/45 xl:hidden"
        />
      )}
      <div className="app-content flex min-w-0 flex-1 flex-col overflow-hidden">
        <Header page={page} role={role} onMenuToggle={() => setSidebarOpen(true)} />
        <main id="admin-content" className="flex-1 overflow-y-auto" tabIndex={-1}>
          <PageShell key={page}>{children}</PageShell>
        </main>
      </div>
    </div>
  );
}
