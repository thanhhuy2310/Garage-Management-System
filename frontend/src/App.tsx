import { lazy, Suspense, useEffect, useState } from "react";
import Header from "./components/Header";
import PageShell from "./components/PageShell";
import Sidebar from "./components/Sidebar";
import Login from "./pages/Login";

const Dashboard = lazy(() => import("./pages/Dashboard"));
const Appointments = lazy(() => import("./pages/Appointments"));
const Reception = lazy(() => import("./pages/Reception"));
const RepairOrders = lazy(() => import("./pages/RepairOrders"));
const Quotation = lazy(() => import("./pages/Quotation"));
const Customers = lazy(() => import("./pages/Customers"));
const Vehicles = lazy(() => import("./pages/Vehicles"));
const Services = lazy(() => import("./pages/Services"));
const Inventory = lazy(() => import("./pages/Inventory"));
const Invoice = lazy(() => import("./pages/Invoice"));
const History = lazy(() => import("./pages/History"));
const Notifications = lazy(() => import("./pages/Notifications"));
const Reports = lazy(() => import("./pages/Reports"));
const Staff = lazy(() => import("./pages/Staff"));
const Settings = lazy(() => import("./pages/Settings"));
const TechnicianView = lazy(() => import("./pages/TechnicianView"));
const DesignSystem = lazy(() => import("./pages/DesignSystem"));
const MobileApp = lazy(() => import("./pages/MobileApp"));

export type Page =
  | "dashboard" | "appointments" | "reception" | "repair" | "quotation"
  | "customers" | "vehicles" | "services" | "inventory" | "invoice"
  | "history" | "notifications" | "reports" | "staff" | "settings"
  | "technician" | "design-system" | "mobile";

type Role = "customer" | "receptionist" | "technician" | "warehouse" | "manager" | "admin";

const PAGE_KEYS = new Set<Page>([
  "dashboard", "appointments", "reception", "repair", "quotation",
  "customers", "vehicles", "services", "inventory", "invoice",
  "history", "notifications", "reports", "staff", "settings",
  "technician", "design-system", "mobile",
]);

const ROLE_LABELS: Record<Role, string> = {
  customer: "Khách hàng",
  admin: "Quản trị viên",
  manager: "Quản lý",
  receptionist: "NV tiếp nhận",
  technician: "Kỹ thuật viên",
  warehouse: "NV kho",
};

const ROLE_NAV: Record<Role, Page[]> = {
  customer: ["mobile"],
  receptionist: ["customers", "vehicles", "appointments", "reception", "repair", "quotation", "invoice", "history"],
  technician: ["technician"],
  warehouse: ["inventory"],
  manager: ["dashboard", "staff", "services", "repair", "reports"],
  admin: ["settings"],
};

const ROLE_USERNAMES: Record<Role, string> = {
  customer: "khachhang.an",
  receptionist: "tiepnhan",
  technician: "ktv.khoa",
  warehouse: "kho.nam",
  manager: "manager",
  admin: "admin",
};

function getPageFromHash(): Page | null {
  const key = window.location.hash.replace(/^#\/?/, "") as Page;
  return PAGE_KEYS.has(key) ? key : null;
}

function PageContent({ page }: { page: Page }) {
  switch (page) {
    case "dashboard": return <Dashboard />;
    case "appointments": return <Appointments />;
    case "reception": return <Reception />;
    case "repair": return <RepairOrders />;
    case "quotation": return <Quotation />;
    case "customers": return <Customers />;
    case "vehicles": return <Vehicles />;
    case "services": return <Services />;
    case "inventory": return <Inventory />;
    case "invoice": return <Invoice />;
    case "history": return <History />;
    case "notifications": return <Notifications />;
    case "reports": return <Reports />;
    case "staff": return <Staff />;
    case "settings": return <Settings />;
    case "technician": return <TechnicianView />;
    case "design-system": return <DesignSystem />;
    case "mobile": return <MobileApp />;
  }
}

function PageLoading() {
  return (
    <div className="flex min-h-[240px] items-center justify-center text-sm text-slate-500" role="status">
      <span className="mr-3 h-5 w-5 animate-spin rounded-full border-2 border-slate-200 border-t-[#1e3a6e]" />
      Đang tải nội dung...
    </div>
  );
}

export default function App() {
  const [loggedIn, setLoggedIn] = useState(false);
  const [role, setRole] = useState<Role>("manager");
  const [page, setPage] = useState<Page>(() => getPageFromHash() ?? "dashboard");
  const [showMobile, setShowMobile] = useState(false);
  const [showRolePicker, setShowRolePicker] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const allowedPages = ROLE_NAV[role];

  useEffect(() => {
    const syncRoute = () => {
      const nextPage = getPageFromHash();
      if (nextPage && (allowedPages.includes(nextPage) || nextPage === "mobile")) {
        setPage(nextPage);
      }
    };
    window.addEventListener("hashchange", syncRoute);
    return () => window.removeEventListener("hashchange", syncRoute);
  }, [allowedPages]);

  const navigate = (nextPage: Page) => {
    if (!allowedPages.includes(nextPage) && nextPage !== "mobile") return;
    setPage(nextPage);
    setSidebarOpen(false);
    window.location.hash = `/${nextPage}`;
  };

  const handleLogin = () => {
    const landingPage = role === "technician" ? "technician" : allowedPages[0];
    setLoggedIn(true);
    navigate(landingPage);
  };

  if (!loggedIn) {
    return (
      <div className="relative">
        <Login
          onLogin={handleLogin}
          account={{ label: ROLE_LABELS[role], username: ROLE_USERNAMES[role] }}
        />
        <div className="fixed bottom-6 right-6 z-50">
          {showRolePicker && (
            <div className="mb-2 min-w-[220px] rounded-lg border border-border bg-white p-3 shadow-xl">
              <p className="mb-2 px-1 text-xs font-semibold uppercase tracking-wide text-slate-500">Đăng nhập với vai trò</p>
              {(Object.entries(ROLE_LABELS) as [Role, string][]).map(([key, label]) => (
                <button
                  key={key}
                  onClick={() => { setRole(key); setShowRolePicker(false); }}
                  className={`flex min-h-10 w-full items-center justify-between rounded-md px-3 text-sm transition-all hover:bg-slate-50 ${role === key ? "font-semibold text-primary" : "text-slate-700"}`}
                >
                  {label}
                  {role === key && <span className="text-[#1e3a6e]">✓</span>}
                </button>
              ))}
            </div>
          )}
          <button
            onClick={() => setShowRolePicker((previous) => !previous)}
            className="flex min-h-11 w-full items-center gap-2 rounded-md bg-primary px-4 text-sm font-semibold text-white shadow-lg transition-all hover:bg-[#102a4c]"
          >
            <span>Vai trò: {ROLE_LABELS[role]}</span>
            <span className="text-white/60">▼</span>
          </button>
        </div>
      </div>
    );
  }

  const handleLogout = () => {
    setLoggedIn(false);
    setShowMobile(false);
    setSidebarOpen(false);
    window.history.replaceState(null, "", window.location.pathname);
  };

  if (role === "customer") {
    return (
      <div className="relative min-h-screen bg-[#f0f4f8]">
        <button
          type="button"
          onClick={handleLogout}
          className="fixed right-4 top-4 z-50 rounded-lg bg-[#1e3a6e] px-3 py-2 text-xs font-semibold text-white shadow-lg hover:bg-[#162d56]"
        >
          Đăng xuất
        </button>
        <Suspense fallback={<PageLoading />}><MobileApp /></Suspense>
      </div>
    );
  }

  if (showMobile) {
    return (
      <div className="min-h-screen bg-[#f0f4f8]">
        <div className="fixed inset-x-0 top-0 z-40 flex h-12 items-center justify-between bg-[#1e3a6e] px-4 text-white sm:px-6">
          <div className="flex min-w-0 items-center gap-3">
            <div className="flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-lg bg-amber-500">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
                <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v9a2 2 0 0 1-2 2h-2" />
                <circle cx="7.5" cy="17.5" r="2.5" /><circle cx="17.5" cy="17.5" r="2.5" />
              </svg>
            </div>
            <span className="truncate text-sm font-bold">Ứng dụng Khách hàng – Mobile Preview</span>
            <span className="hidden rounded-full bg-white/10 px-2 py-0.5 text-xs text-white/50 sm:inline">390×844</span>
          </div>
          <button onClick={() => setShowMobile(false)} className="ml-3 flex-shrink-0 rounded-lg bg-white/15 px-3 py-1.5 text-sm font-medium transition-all hover:bg-white/25">
            ← <span className="hidden sm:inline">Về giao diện quản lý</span>
          </button>
        </div>
        <div className="pt-12">
          <Suspense fallback={<PageLoading />}><MobileApp /></Suspense>
        </div>
      </div>
    );
  }

  return (
    <div className="flex h-screen overflow-hidden bg-[#f0f4f8]">
      <a href="#main-content" className="fixed left-3 top-3 z-[60] -translate-y-20 rounded-md bg-white px-4 py-2 text-sm font-semibold text-primary shadow-lg transition-transform focus:translate-y-0">
        Bỏ qua đến nội dung chính
      </a>
      <Sidebar
        active={page}
        onNavigate={(key) => navigate(key as Page)}
        role={role}
        allowedPages={allowedPages}
        mobileOpen={sidebarOpen}
        onClose={() => setSidebarOpen(false)}
        onLogout={handleLogout}
      />
      {sidebarOpen && (
        <button
          aria-label="Đóng thanh điều hướng"
          onClick={() => setSidebarOpen(false)}
          className="fixed inset-0 z-20 bg-slate-950/40 xl:hidden"
        />
      )}
      <div className="app-content flex min-w-0 flex-1 flex-col overflow-hidden">
        <Header
          page={page}
          role={role}
          onMenuToggle={() => setSidebarOpen(true)}
          onMobileToggle={() => setShowMobile(true)}
        />
        <main id="main-content" className="flex-1 overflow-y-auto" tabIndex={-1}>
          <PageShell>
            <Suspense fallback={<PageLoading />}><PageContent page={page} /></Suspense>
          </PageShell>
        </main>
      </div>
    </div>
  );
}
