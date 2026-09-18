import React, { useState } from "react";
import Sidebar from "./components/Sidebar";
import Header from "./components/Header";
import Login from "./pages/Login";
import Dashboard from "./pages/Dashboard";
import Appointments from "./pages/Appointments";
import Reception from "./pages/Reception";
import RepairOrders from "./pages/RepairOrders";
import Quotation from "./pages/Quotation";
import Customers from "./pages/Customers";
import Vehicles from "./pages/Vehicles";
import Services from "./pages/Services";
import Inventory from "./pages/Inventory";
import Invoice from "./pages/Invoice";
import History from "./pages/History";
import Notifications from "./pages/Notifications";
import Reports from "./pages/Reports";
import Staff from "./pages/Staff";
import Settings from "./pages/Settings";
import TechnicianView from "./pages/TechnicianView";
import DesignSystem from "./pages/DesignSystem";
import MobileApp from "./pages/MobileApp";

type Page =
  | "dashboard" | "appointments" | "reception" | "repair" | "quotation"
  | "customers" | "vehicles" | "services" | "inventory" | "invoice"
  | "history" | "notifications" | "reports" | "staff" | "settings"
  | "technician" | "design-system" | "mobile";

function PageContent({ page }: { page: Page }) {
  switch (page) {
    case "dashboard":    return <Dashboard />;
    case "appointments": return <Appointments />;
    case "reception":    return <Reception />;
    case "repair":       return <RepairOrders />;
    case "quotation":    return <Quotation />;
    case "customers":    return <Customers />;
    case "vehicles":     return <Vehicles />;
    case "services":     return <Services />;
    case "inventory":    return <Inventory />;
    case "invoice":      return <Invoice />;
    case "history":      return <History />;
    case "notifications":return <Notifications />;
    case "reports":      return <Reports />;
    case "staff":        return <Staff />;
    case "settings":     return <Settings />;
    case "technician":   return <TechnicianView />;
    case "design-system": return <DesignSystem />;
    case "mobile":       return <MobileApp />;
    default:             return <Dashboard />;
  }
}

type Role = "manager" | "technician" | "receptionist" | "cashier" | "warehouse" | "admin";

const ROLE_LABELS: Record<Role, string> = {
  admin: "Quản trị viên",
  manager: "Quản lý",
  receptionist: "NV tiếp nhận",
  technician: "Kỹ thuật viên",
  warehouse: "NV kho",
  cashier: "Thu ngân",
};

// Sidebar items each role can see
const ROLE_NAV: Record<Role, string[]> = {
  admin: ["dashboard","appointments","reception","repair","quotation","customers","vehicles","services","inventory","invoice","history","notifications","reports","staff","settings","design-system"],
  manager: ["dashboard","appointments","reception","repair","quotation","customers","vehicles","services","inventory","invoice","history","notifications","reports","staff"],
  receptionist: ["appointments","reception","repair","quotation","customers","vehicles","invoice","notifications"],
  technician: ["technician","inventory","notifications"],
  warehouse: ["inventory","notifications"],
  cashier: ["invoice","history","notifications"],
};

export default function App() {
  const [loggedIn, setLoggedIn] = useState(false);
  const [role, setRole] = useState<Role>("manager");
  const [page, setPage] = useState<Page>("dashboard");
  const [showMobile, setShowMobile] = useState(false);
  const [showRolePicker, setShowRolePicker] = useState(false);

  const handleLogin = () => {
    setLoggedIn(true);
    setPage(role === "technician" ? "technician" : "dashboard");
  };

  if (!loggedIn) {
    return (
      <div className="relative">
        <Login onLogin={handleLogin} />
        {/* Demo role selector */}
        <div className="fixed bottom-6 right-6 z-50">
          {showRolePicker && (
            <div className="mb-2 bg-white rounded-xl border border-[#dde3ec] shadow-xl p-3 min-w-[200px]">
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2 px-1">Đăng nhập với vai trò</p>
              {(Object.entries(ROLE_LABELS) as [Role, string][]).map(([key, label]) => (
                <button key={key} onClick={() => { setRole(key); setShowRolePicker(false); }}
                  className={`w-full flex items-center justify-between px-3 py-2 rounded-lg text-sm hover:bg-slate-50 transition-all ${role === key ? "text-[#1e3a6e] font-semibold" : "text-slate-700"}`}>
                  {label}
                  {role === key && <span className="text-[#1e3a6e]">✓</span>}
                </button>
              ))}
            </div>
          )}
          <button onClick={() => setShowRolePicker(p => !p)}
            className="w-full px-4 py-2 bg-[#1e3a6e] text-white text-sm font-medium rounded-xl shadow-lg hover:bg-[#162d56] transition-all flex items-center gap-2">
            <span>Vai trò: {ROLE_LABELS[role]}</span>
            <span className="text-white/60">▼</span>
          </button>
        </div>
      </div>
    );
  }

  if (showMobile) {
    return (
      <div className="min-h-screen bg-[#f0f4f8]">
        <div className="fixed top-0 left-0 right-0 z-40 bg-[#1e3a6e] text-white flex items-center justify-between px-6 h-12">
          <div className="flex items-center gap-3">
            <div className="w-7 h-7 bg-amber-500 rounded-lg flex items-center justify-center">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2">
                <path d="M5 17H3a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v9a2 2 0 0 1-2 2h-2"/>
                <circle cx="7.5" cy="17.5" r="2.5"/><circle cx="17.5" cy="17.5" r="2.5"/>
              </svg>
            </div>
            <span className="font-bold text-sm">Ứng dụng Khách Hàng – Mobile Preview</span>
            <span className="text-xs text-white/50 bg-white/10 px-2 py-0.5 rounded-full">390×844</span>
          </div>
          <button onClick={() => setShowMobile(false)}
            className="flex items-center gap-2 px-3 py-1.5 bg-white/15 hover:bg-white/25 rounded-lg text-sm font-medium transition-all">
            ← Về giao diện quản lý
          </button>
        </div>
        <div className="pt-12">
          <MobileApp />
        </div>
      </div>
    );
  }

  const allowedPages = ROLE_NAV[role] ?? ROLE_NAV.manager;

  const handleNavigate = (key: string) => {
    if (allowedPages.includes(key) || key === "mobile") {
      setPage(key as Page);
    }
  };

  return (
    <div className="flex h-screen bg-[#f0f4f8] overflow-hidden">
      <Sidebar active={page} onNavigate={handleNavigate} role={role} allowedPages={allowedPages} />

      <div className="flex-1 flex flex-col overflow-hidden ml-[220px]">
        <Header page={page} role={role} onMobileToggle={() => setShowMobile(true)} />
        <main className="flex-1 overflow-y-auto">
          <PageContent page={page} />
        </main>
      </div>
    </div>
  );
}

