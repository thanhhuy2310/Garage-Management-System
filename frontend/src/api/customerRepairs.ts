import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";
import type { RepairOrderDetail } from "../types/garage";
export interface HistoryItem { repairOrderId: number; vehicleId: number; licensePlate: string; brand: string; model: string; completedAt: string | null; totalCost: number; result: string | null; summary: string }
export interface HistoryLine { name: string; quantity: number; unitPrice: number; lineTotal: number }
export interface HistoryDetail { item: HistoryItem; services: HistoryLine[]; parts: HistoryLine[]; serviceTotal: number; partsTotal: number }
export interface HistoryPage { items: HistoryItem[]; page: number; size: number; totalElements: number; totalPages: number }
export interface HistoryVehicle { vehicleId: number; licensePlate: string; brand: string; model: string; completedCount: number }
export const customerRepairsApi = {
  async repairs(signal?: AbortSignal) { return unwrap(await api.get<ApiResponse<RepairOrderDetail[]>>("/api/customer/repairs", { signal })); },
  async history(params: { page?: number; size?: number; vehicleId?: number } = {}, signal?: AbortSignal) {
    const query = new URLSearchParams({ page: String(params.page ?? 0), size: String(params.size ?? 10) });
    if (params.vehicleId != null) query.set("vehicleId", String(params.vehicleId));
    return unwrap(await api.get<ApiResponse<HistoryPage>>(`/api/customers/me/history?${query}`, { signal }));
  },
  async historyVehicles(signal?: AbortSignal) {
    return unwrap(await api.get<ApiResponse<HistoryVehicle[]>>("/api/customers/me/history/vehicles", { signal }));
  },
  async detail(id: number, signal?: AbortSignal) { return unwrap(await api.get<ApiResponse<HistoryDetail>>(`/api/customers/me/history/${id}`, { signal })); },
};
