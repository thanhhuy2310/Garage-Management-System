// TV3-TUAN7
import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";

export interface SparePart {
  id: number;
  warehouseId: number;
  name: string;
  manufacturer: string | null;
  unitPrice: number;
  /** Chỉ đọc: tồn kho do nghiệp vụ nhập/xuất kho thay đổi, không sửa ở danh mục. */
  stockQuantity: number;
  minStockLevel: number;
}

export interface SparePartPayload {
  warehouseId: number;
  name: string;
  manufacturer: string | null;
  unitPrice: number;
  minStockLevel: number;
}

export interface SparePartPage {
  items: SparePart[];
  /** Bắt đầu từ 0, giống Spring Data. */
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

export interface Warehouse {
  id: number;
  name: string;
}

export interface SparePartListParams {
  page?: number;
  size?: number;
  search?: string;
}

export type StockStatus = "ok" | "low" | "out";

/** Cùng quy tắc với dbo.fn_TrangThaiTonKho: 0 = hết hàng, <= mức tối thiểu = sắp hết. */
export function stockStatus(part: Pick<SparePart, "stockQuantity" | "minStockLevel">): StockStatus {
  if (part.stockQuantity === 0) return "out";
  if (part.stockQuantity <= part.minStockLevel) return "low";
  return "ok";
}

export const STOCK_LABELS: Record<StockStatus, string> = {
  ok: "Còn hàng",
  low: "Sắp hết",
  out: "Hết hàng",
};

export const sparePartsApi = {
  async list(params: SparePartListParams = {}): Promise<SparePartPage> {
    return unwrap(await api.get<ApiResponse<SparePartPage>>("/api/spare-parts", { params }));
  },

  async getById(id: number): Promise<SparePart> {
    return unwrap(await api.get<ApiResponse<SparePart>>(`/api/spare-parts/${id}`));
  },

  async create(payload: SparePartPayload): Promise<SparePart> {
    return unwrap(await api.post<ApiResponse<SparePart>>("/api/spare-parts", payload));
  },

  async update(id: number, payload: SparePartPayload): Promise<SparePart> {
    return unwrap(await api.put<ApiResponse<SparePart>>(`/api/spare-parts/${id}`, payload));
  },

  async warehouses(): Promise<Warehouse[]> {
    return unwrap(await api.get<ApiResponse<Warehouse[]>>("/api/spare-parts/warehouses"));
  },
};
