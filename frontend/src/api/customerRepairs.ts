import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";
import type { RepairOrderDetail } from "../types/garage";
export interface HistoryItem { repairOrderId: number; licensePlate: string; brand: string; model: string; completedAt: string | null; totalCost: number; result: string | null; summary: string }
export interface HistoryLine { name: string; quantity: number; unitPrice: number; lineTotal: number }
export interface HistoryDetail { item: HistoryItem; services: HistoryLine[]; parts: HistoryLine[]; serviceTotal: number; partsTotal: number }
export const customerRepairsApi = {
  async repairs(signal?: AbortSignal) { return unwrap(await api.get<ApiResponse<RepairOrderDetail[]>>("/api/customer/repairs", { signal })); },
  async history(signal?: AbortSignal) { return unwrap(await api.get<ApiResponse<HistoryItem[]>>("/api/customers/me/history", { signal })); },
  async detail(id: number, signal?: AbortSignal) { return unwrap(await api.get<ApiResponse<HistoryDetail>>(`/api/customers/me/history/${id}`, { signal })); },
};
