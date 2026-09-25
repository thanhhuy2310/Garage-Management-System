import { lazy, Suspense, useEffect, useState } from "react";
import type { PublicPageKey } from "./components/PublicHeader";
import AdminLayout from "./layouts/AdminLayout";
import PublicLayout from "./layouts/PublicLayout";
import Login from "./pages/Login";
import Register from "./pages/Register";
import { navigateTo, ROUTE_PATHS, useAppRoute, type AdminPage, type Role } from "./router";
import { authApi, type LoginResponse } from "./api/auth";
import { clearSession, readSession, saveSession, updateStoredAccount, type StoredSession } from "./api/session";

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

const ROLE_NAV: Record<Role, AdminPage[]> = {
  customer: [],
  receptionist: ["customers", "vehicles", "appointments", "reception", "repair", "quotation", "invoice", "history"],
  technician: ["technician"],
  warehouse: ["inventory"],
  manager: ["dashboard", "staff", "services", "repair", "reports"],
  admin: ["settings"],
};

function accountRole(role: string): Role | null {
  const normalized = role.toLowerCase();
  return normalized in ROLE_NAV ? normalized as Role : null;
}

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

export default function App() {
  const route = useAppRoute();
  const [session, setSession] = useState<StoredSession | null>(() => readSession());
  const role = session ? accountRole(session.account.role) : null;
  const loggedIn = Boolean(session && role);
  const allowedPages = role ? ROLE_NAV[role] : [];
  const landingPage = role === "technician" ? "technician" : allowedPages[0];

  useEffect(() => {
    if (!session) return;

    authApi.me()
      .then((account) => {
        updateStoredAccount(account);
        setSession((current) => current ? { ...current, account } : current);
      })
      .catch(() => {
        clearSession();
        setSession(null);
      });
  }, []);

  useEffect(() => {
    if (!loggedIn || !role) return;
    if (role === "customer") {
      if (route.area !== "customer") navigateTo(ROUTE_PATHS.customer(), true);
      return;
    }
    if (landingPage && (route.area !== "admin" || !allowedPages.includes(route.page))) {
      navigateTo(ROUTE_PATHS.admin(landingPage), true);
    }
  }, [allowedPages, landingPage, loggedIn, role, route]);

  const handleLogin = (response: LoginResponse, remember: boolean) => {
    const nextRole = accountRole(response.account.role);
    if (!nextRole) return;

    const nextSession = saveSession(response, remember);
    setSession(nextSession);
    if (nextRole === "customer") navigateTo(ROUTE_PATHS.customer());
    else {
      const nextLandingPage = nextRole === "technician" ? "technician" : ROLE_NAV[nextRole][0];
      if (nextLandingPage) navigateTo(ROUTE_PATHS.admin(nextLandingPage));
    }
  };

  const handleLogout = async () => {
    try {
      await authApi.logout();
    } finally {
      clearSession();
      setSession(null);
      navigateTo("/login", true);
    }
  };

  if (!loggedIn) {
    if (route.area === "public" && route.page !== "login" && route.page !== "register") {
      const publicPage = route.page as PublicPageKey;
      const goPublic = (page: PublicPageKey) => navigateTo(ROUTE_PATHS.public(page));
      const goLogin = () => navigateTo("/login");
      const goBooking = () => navigateTo("/login");
      return (
        <PublicLayout>
          <Suspense fallback={<PageLoading />}>
            <PublicHome page={publicPage} onNavigate={goPublic} onLogin={goLogin} onBook={goBooking} />
          </Suspense>
        </PublicLayout>
      );
    }
    if (route.area === "public" && route.page === "register") {
      return <Register onRegistered={handleLogin} onLogin={() => navigateTo("/login")} />;
    }
    return <Login onLogin={handleLogin} onBack={() => navigateTo("/")} onRegister={() => navigateTo("/register")} />;
  }

  if (role === "customer") {
    const customerPage = route.area === "customer" ? route.page : "overview";
    return (
      <Suspense fallback={<PageLoading />}>
        <CustomerPortal
          page={customerPage}
          customerId={session?.account.customerId ?? 0}
          onNavigate={(next) => navigateTo(ROUTE_PATHS.customer(next))}
          onLogout={handleLogout}
        />
      </Suspense>
    );
  }

  if (!role) return null;

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
