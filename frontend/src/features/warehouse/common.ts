import { formatGarageDate, formatMoney } from "../../utils/garageFormat";
// TV3-TUAN8
import { useEffect, useState } from "react";
import { readSession } from "../../api/session";

export const formatPrice = formatMoney;
export const formatDateTime = formatGarageDate;

export const PER_PAGE = 10;

/** Quyền thao tác trên màn kho theo vai trò backend (backend vẫn là nơi kiểm tra quyền thật). */
export function useWarehouseRole() {
  const role = readSession()?.account.role ?? "";
  return {
    role,
    canWrite: role === "WAREHOUSE" || role === "MANAGER",
    canConfirmUsage: role === "TECHNICIAN",
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
