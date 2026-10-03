// TV3-TUAN7
import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";

export type RepairDetailType = "SERVICE" | "SPARE_PART";

export interface RepairDetail {
  type: RepairDetailType;
  itemId: number;
  itemName: string;
  quantity: number;
  unitPrice: number;
  lineTotal: number;
  /** Chỉ dòng dịch vụ có trạng thái tiến độ (do nghiệp vụ kỹ thuật viên cập nhật). */
  status: string | null;
}

export interface RepairDetails {
  repairOrderId: number;
  repairOrderStatus: string;
  editable: boolean;
  items: RepairDetail[];
  serviceTotal: number;
  partsTotal: number;
  totalAmount: number;
}

export interface RepairDetailCreatePayload {
  type: RepairDetailType;
  itemId: number;
  quantity: number;
  /** Bỏ trống = lấy đơn giá hiện tại của danh mục. */
  unitPrice?: number | null;
}

export interface RepairDetailUpdatePayload {
  quantity: number;
  /** Bỏ trống = giữ nguyên đơn giá của dòng. */
  unitPrice?: number | null;
}

const PATH_SEGMENT: Record<RepairDetailType, string> = {
  SERVICE: "service",
  SPARE_PART: "spare-part",
};

const base = (repairOrderId: number) => `/api/repair-orders/${repairOrderId}/details`;
const itemUrl = (repairOrderId: number, type: RepairDetailType, itemId: number) =>
  `${base(repairOrderId)}/${PATH_SEGMENT[type]}/${itemId}`;

export const repairDetailsApi = {
  async list(repairOrderId: number): Promise<RepairDetails> {
    return unwrap(await api.get<ApiResponse<RepairDetails>>(base(repairOrderId)));
  },

  async create(repairOrderId: number, payload: RepairDetailCreatePayload): Promise<RepairDetail> {
    return unwrap(await api.post<ApiResponse<RepairDetail>>(base(repairOrderId), payload));
  },

  async update(
    repairOrderId: number,
    type: RepairDetailType,
    itemId: number,
    payload: RepairDetailUpdatePayload,
  ): Promise<RepairDetail> {
    return unwrap(await api.put<ApiResponse<RepairDetail>>(itemUrl(repairOrderId, type, itemId), payload));
  },

  async remove(repairOrderId: number, type: RepairDetailType, itemId: number): Promise<void> {
    await api.delete<ApiResponse<void>>(itemUrl(repairOrderId, type, itemId));
  },
};
