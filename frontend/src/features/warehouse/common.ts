// TV3-TUAN8
import { useEffect, useState } from "react";
import { readSession } from "../../api/session";

export const formatPrice = (value: number) =>
  new Intl.NumberFormat("vi-VN", { style: "currency", currency: "VND", maximumFractionDigits: 0 }).format(value);

export const formatDateTime = (value: string | null) => (value ? new Date(value).toLocaleString("vi-VN") : "—");

export const PER_PAGE = 10;

/** Quyền thao tác trên màn kho theo vai trò backend (backend vẫn là nơi kiểm tra quyền thật). */
export function useWarehouseRole() {
  const role = readSession()?.account.role ?? "";
  return {
    role,
    canWrite: role === "WAREHOUSE" || role === "MANAGER" || role === "ADMIN",
    canConfirmUsage: role === "MANAGER" || role === "ADMIN" || role === "TECHNICIAN",
    isManager: role === "MANAGER",
    needsTechnicianId: role !== "TECHNICIAN",
  };
}

export function useDebounced<T>(value: T, delay = 300): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const timer = window.setTimeout(() => setDebounced(value), delay);
    return () => window.clearTimeout(timer);
  }, [value, delay]);
  return debounced;
}
