import { useEffect, useState } from "react";

export type Role = "customer" | "receptionist" | "technician" | "warehouse" | "manager" | "admin";

export type AdminPage =
  | "dashboard" | "appointments" | "reception" | "repair" | "quotation"
  | "customers" | "vehicles" | "services" | "inventory" | "invoice"
  | "history" | "notifications" | "reports" | "staff" | "settings"
  | "technician" | "design-system";

export type PublicPage = "home" | "about" | "services" | "parts" | "contact" | "login";
export type CustomerPage = "overview" | "appointments" | "quotations" | "tracking" | "history" | "notifications" | "profile";

export type AppRoute =
  | { area: "public"; page: PublicPage }
  | { area: "customer"; page: CustomerPage }
  | { area: "admin"; page: AdminPage };

export const ADMIN_PAGES = new Set<AdminPage>([
  "dashboard", "appointments", "reception", "repair", "quotation",
  "customers", "vehicles", "services", "inventory", "invoice",
  "history", "notifications", "reports", "staff", "settings",
  "technician", "design-system",
]);

const PUBLIC_ROUTES: Record<string, PublicPage> = {
  "/": "home",
  "/about": "about",
  "/services": "services",
  "/parts": "parts",
  "/contact": "contact",
  "/login": "login",
};

const CUSTOMER_PAGES = new Set<CustomerPage>([
  "overview", "appointments", "quotations", "tracking", "history", "notifications", "profile",
]);

export const ROUTE_PATHS = {
  public: (page: PublicPage) => page === "home" ? "/" : `/${page}`,
  customer: (page: CustomerPage = "overview") => page === "overview" ? "/customer" : `/customer/${page}`,
  admin: (page: AdminPage) => `/admin/${page}`,
};

export function readRoute(): AppRoute {
  const path = window.location.pathname.replace(/\/+$/, "") || "/";

  if (PUBLIC_ROUTES[path]) return { area: "public", page: PUBLIC_ROUTES[path] };

  if (path === "/customer") return { area: "customer", page: "overview" };
  if (path.startsWith("/customer/")) {
    const page = path.slice("/customer/".length) as CustomerPage;
    if (CUSTOMER_PAGES.has(page)) return { area: "customer", page };
  }

  if (path.startsWith("/admin/")) {
    const page = path.slice("/admin/".length) as AdminPage;
    if (ADMIN_PAGES.has(page)) return { area: "admin", page };
  }

  // Preserve links from the earlier hash-based prototype while routing all new links by path.
  const legacyPage = window.location.hash.replace(/^#\/?/, "") as AdminPage;
  if (ADMIN_PAGES.has(legacyPage)) return { area: "admin", page: legacyPage };

  return { area: "public", page: "home" };
}

const ROUTE_EVENT = "garage:navigate";

export function navigateTo(path: string, replace = false) {
  window.history[replace ? "replaceState" : "pushState"](null, "", path);
  window.dispatchEvent(new Event(ROUTE_EVENT));
  window.scrollTo({ top: 0, behavior: "instant" });
}

export function useAppRoute() {
  const [route, setRoute] = useState<AppRoute>(() => readRoute());

  useEffect(() => {
    const sync = () => setRoute(readRoute());
    window.addEventListener("popstate", sync);
    window.addEventListener(ROUTE_EVENT, sync);
    return () => {
      window.removeEventListener("popstate", sync);
      window.removeEventListener(ROUTE_EVENT, sync);
    };
  }, []);

  return route;
}
