// TV3-TUAN8
import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";

export type StockStatus = "CON_HANG" | "SAP_HET" | "HET_HANG";

export interface PageResult<T> {
  items: T[];
  /** Bắt đầu từ 0, giống Spring Data. */
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

export interface InventoryItem {
  id: number;
  warehouseId: number;
  name: string;
  manufacturer: string | null;
  unitPrice: number;
  stockQuantity: number;
  minStockLevel: number;
  stockStatus: StockStatus;
}

export interface InventoryPage extends PageResult<InventoryItem> {
  lowStockCount: number;
}

export type MovementType = "NHAP" | "XUAT" | "KIEM_KE";

export interface StockMovement {
  id: number;
  partId: number;
  partName: string;
  receiptId: number | null;
  issueId: number | null;
  time: string;
  type: MovementType;
  quantity: number;
  quantityBefore: number | null;
  quantityAfter: number | null;
  note: string | null;
}

export interface ImportItemPayload {
  partId: number;
  quantity: number;
  unitPrice: number;
}

export interface ImportPayload {
  supplier: string;
  importDate?: string | null;
  note: string | null;
  items: ImportItemPayload[];
}

export interface StockImport {
  id: number;
  importDate: string;
  supplier: string;
  warehouseStaffId: number;
  note: string | null;
  items: { partId: number; partName: string; quantity: number; unitPrice: number; lineTotal: number }[];
  totalAmount: number;
}

export interface IssuePayload {
  repairOrderId: number;
  requestedTechnicianId: number | null;
  reason: string;
  items: { partId: number; quantity: number }[];
}

export type IssueItemState = "CHO_XAC_NHAN" | "DA_XAC_NHAN";

export interface IssueItem {
  partId: number;
  partName: string;
  issuedQuantity: number;
  unitPrice: number | null;
  state: IssueItemState;
  confirmedAt: string | null;
  confirmedTechnicianId: number | null;
  actualUsedQuantity: number | null;
  returnedQuantity: number | null;
  stockAfter: number | null;
}

export interface StockIssue {
  id: number;
  repairOrderId: number | null;
  warehouseStaffId: number;
  requestedTechnicianId: number | null;
  issueDate: string;
  reason: string;
  items: IssueItem[];
}

export type CheckStatus = "DANG_KIEM_KE" | "CHO_PHE_DUYET" | "DA_HOAN_TAT" | "DA_TU_CHOI";

export interface CheckSummary {
  id: number;
  checkDate: string;
  createdBy: number;
  approvedBy: number | null;
  status: CheckStatus;
  note: string | null;
  itemCount: number;
  differenceCount: number;
}

export interface CheckItem {
  partId: number;
  partName: string;
  systemQuantity: number;
  actualQuantity: number | null;
  difference: number | null;
  reason: string | null;
  adjustmentApproved: boolean;
}

export interface InventoryCheck {
  id: number;
  checkDate: string;
  createdBy: number;
  approvedBy: number | null;
  approvedAt: string | null;
  status: CheckStatus;
  note: string | null;
  decisionReason: string | null;
  items: CheckItem[];
}

export interface PageParams {
  page?: number;
  size?: number;
}

export const inventoryApi = {
  async stock(params: PageParams & { search?: string; status?: StockStatus | "ALL" }): Promise<InventoryPage> {
    return unwrap(await api.get<ApiResponse<InventoryPage>>("/api/inventory", { params }));
  },

  async movements(params: PageParams & { partId?: number; type?: MovementType | "ALL" }): Promise<PageResult<StockMovement>> {
    return unwrap(await api.get<ApiResponse<PageResult<StockMovement>>>("/api/inventory/movements", { params }));
  },
};

export const warehouseApi = {
  async imports(params: PageParams = {}): Promise<PageResult<StockImport>> {
    return unwrap(await api.get<ApiResponse<PageResult<StockImport>>>("/api/warehouse/imports", { params }));
  },

  async createImport(payload: ImportPayload): Promise<StockImport> {
    return unwrap(await api.post<ApiResponse<StockImport>>("/api/warehouse/imports", payload));
  },

  async issues(params: PageParams = {}): Promise<PageResult<StockIssue>> {
    return unwrap(await api.get<ApiResponse<PageResult<StockIssue>>>("/api/warehouse/exports", { params }));
  },

  async createIssue(payload: IssuePayload): Promise<StockIssue> {
    return unwrap(await api.post<ApiResponse<StockIssue>>("/api/warehouse/exports", payload));
  },

  async confirmUsage(
    issueId: number,
    partId: number,
    payload: { actualUsed: number; technicianId?: number | null },
  ): Promise<IssueItem> {
    return unwrap(await api.post<ApiResponse<IssueItem>>(`/api/warehouse/exports/${issueId}/items/${partId}/confirm`, payload));
  },

  async checks(params: PageParams = {}): Promise<PageResult<CheckSummary>> {
    return unwrap(await api.get<ApiResponse<PageResult<CheckSummary>>>("/api/warehouse/checks", { params }));
  },

  async check(id: number): Promise<InventoryCheck> {
    return unwrap(await api.get<ApiResponse<InventoryCheck>>(`/api/warehouse/checks/${id}`));
  },

  async createCheck(payload: { note: string | null; partIds: number[] }): Promise<InventoryCheck> {
    return unwrap(await api.post<ApiResponse<InventoryCheck>>("/api/warehouse/checks", payload));
  },

  async setActual(checkId: number, partId: number, payload: { actualQuantity: number; reason: string | null }): Promise<InventoryCheck> {
    return unwrap(await api.put<ApiResponse<InventoryCheck>>(`/api/warehouse/checks/${checkId}/items/${partId}`, payload));
  },

  async approveCheck(id: number, reason: string | null): Promise<InventoryCheck> {
    return unwrap(await api.post<ApiResponse<InventoryCheck>>(`/api/warehouse/checks/${id}/approve`, { reason }));
  },

  async rejectCheck(id: number, reason: string): Promise<InventoryCheck> {
    return unwrap(await api.post<ApiResponse<InventoryCheck>>(`/api/warehouse/checks/${id}/reject`, { reason }));
  },
};
