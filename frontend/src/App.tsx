import { lazy, Suspense, useEffect, useState } from "react";
import type { PublicPageKey } from "./components/PublicHeader";
import AdminLayout from "./layouts/AdminLayout";
import PublicLayout from "./layouts/PublicLayout";
import Login from "./pages/Login";
import { navigateTo, ROUTE_PATHS, useAppRoute, type AdminPage, type Role } from "./router";

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
const PublicHome = lazy(() => import("./pages/PublicHome"));
const CustomerPortal = lazy(() => import("./pages/customer/CustomerPortal"));

export type Page = AdminPage;

const ROLE_LABELS: Record<Role, string> = {
  customer: "Khách hàng",
  admin: "Quản trị viên",
  manager: "Quản lý",
  receptionist: "NV tiếp nhận",
  technician: "Kỹ thuật viên",
  warehouse: "NV kho",
};

const ROLE_NAV: Record<Role, AdminPage[]> = {
  customer: [],
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

function PageContent({ page }: { page: AdminPage }) {
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
  }
}

function PageLoading() {
  return (
    <div className="flex min-h-[240px] items-center justify-center text-sm text-muted-foreground" role="status">
      <span className="mr-3 h-5 w-5 animate-spin rounded-full border-2 border-border border-t-primary" />
      Đang tải nội dung...
    </div>
  );
}

function RolePicker({ role, onChange }: { role: Role; onChange: (role: Role) => void }) {
  const [open, setOpen] = useState(false);
  return (
    <div className="fixed bottom-4 right-4 z-50 sm:bottom-6 sm:right-6">
      {open && (
        <div className="mb-2 min-w-[220px] rounded-lg border border-border bg-surface p-3 shadow-xl">
          <p className="mb-2 px-1 text-xs font-semibold uppercase tracking-wide text-muted-foreground">Đăng nhập với vai trò</p>
          {(Object.entries(ROLE_LABELS) as [Role, string][]).map(([key, label]) => (
            <button
              key={key}
              type="button"
              onClick={() => { onChange(key); setOpen(false); }}
              className={`flex min-h-10 w-full items-center justify-between rounded-md px-3 text-sm hover:bg-muted ${role === key ? "font-semibold text-primary" : "text-foreground"}`}
            >
              {label}{role === key && <span aria-hidden="true">✓</span>}
            </button>
          ))}
        </div>
      )}
      <button
        type="button"
        onClick={() => setOpen((value) => !value)}
        className="flex min-h-11 items-center gap-2 rounded-md bg-primary px-4 text-sm font-semibold text-white shadow-lg hover:bg-primary-hover"
        aria-expanded={open}
      >
        Vai trò: {ROLE_LABELS[role]} <span aria-hidden="true">▾</span>
      </button>
    </div>
  );
}

export default function App() {
  const route = useAppRoute();
  const [loggedIn, setLoggedIn] = useState(false);
  const [role, setRole] = useState<Role>("manager");
  const allowedPages = ROLE_NAV[role];
  const landingPage = role === "technician" ? "technician" : allowedPages[0];

  useEffect(() => {
    if (!loggedIn) return;
    if (role === "customer") {
      if (route.area !== "customer") navigateTo(ROUTE_PATHS.customer(), true);
      return;
    }
    if (landingPage && (route.area !== "admin" || !allowedPages.includes(route.page))) {
      navigateTo(ROUTE_PATHS.admin(landingPage), true);
    }
  }, [allowedPages, landingPage, loggedIn, role, route]);

  const handleLogin = () => {
    setLoggedIn(true);
    if (role === "customer") navigateTo(ROUTE_PATHS.customer());
    else if (landingPage) navigateTo(ROUTE_PATHS.admin(landingPage));
  };

  const handleLogout = () => {
    setLoggedIn(false);
    navigateTo("/login", true);
  };

  if (!loggedIn) {
    if (route.area === "public" && route.page !== "login") {
      const publicPage = route.page as PublicPageKey;
      const goPublic = (page: PublicPageKey) => navigateTo(ROUTE_PATHS.public(page));
      const goLogin = () => navigateTo("/login");
      const goBooking = () => {
        setRole("customer");
        navigateTo("/login");
      };
      return (
        <PublicLayout>
          <Suspense fallback={<PageLoading />}>
            <PublicHome page={publicPage} onNavigate={goPublic} onLogin={goLogin} onBook={goBooking} />
          </Suspense>
        </PublicLayout>
      );
    }
    return (
      <div className="relative">
        <Login onLogin={handleLogin} onBack={() => navigateTo("/")} account={{ label: ROLE_LABELS[role], username: ROLE_USERNAMES[role] }} />
        <RolePicker role={role} onChange={setRole} />
      </div>
    );
  }

  if (role === "customer") {
    const customerPage = route.area === "customer" ? route.page : "overview";
    return (
      <Suspense fallback={<PageLoading />}>
        <CustomerPortal
          page={customerPage}
          onNavigate={(next) => navigateTo(ROUTE_PATHS.customer(next))}
          onLogout={handleLogout}
        />
      </Suspense>
    );
  }

  const page = route.area === "admin" && allowedPages.includes(route.page) ? route.page : landingPage;
  if (!page) return null;

  return (
    <AdminLayout
      page={page}
      role={role}
      allowedPages={allowedPages}
      onNavigate={(next) => navigateTo(ROUTE_PATHS.admin(next))}
      onLogout={handleLogout}
    >
      <Suspense fallback={<PageLoading />}><PageContent page={page} /></Suspense>
    </AdminLayout>
  );
}
