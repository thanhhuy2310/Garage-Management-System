import axios from "axios";
import { api, errorMessage, unwrap } from "./client";
import type { ApiResponse } from "./types";

export interface Vehicle {
  id: number;
  customerId: number;
  licensePlate: string;
  brand: string | null;
  model: string | null;
  year: number | null;
  mileage: number | null;
}

export interface VehiclePayload {
  customerId: number;
  licensePlate: string;
  brand: string | null;
  model: string | null;
  year: number | null;
  mileage: number | null;
}

export interface VehiclePage {
  items: Vehicle[];
  /** Bắt đầu từ 0, giống Spring Data. */
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

export interface VehicleListParams {
  page?: number;
  size?: number;
  search?: string;
}

/** Giá trị nhập từ form xe (dùng chung cho nhân viên và khách hàng). */
export interface VehicleFormValue {
  customerId?: number | null;
  plate: string;
  brand: string;
  model: string;
  year: number | null;
  mileage: number | null;
}

export function toVehiclePayload(customerId: number, value: VehicleFormValue): VehiclePayload {
  return {
    customerId,
    licensePlate: value.plate.trim(),
    brand: value.brand.trim() || null,
    model: value.model.trim() || null,
    year: value.year,
    mileage: value.mileage,
  };
}

export const vehiclesApi = {
  async list(params: VehicleListParams = {}): Promise<VehiclePage> {
    return unwrap(await api.get<ApiResponse<VehiclePage>>("/api/vehicles", { params }));
  },

  async getById(id: number): Promise<Vehicle> {
    return unwrap(await api.get<ApiResponse<Vehicle>>(`/api/vehicles/${id}`));
  },

  async create(payload: VehiclePayload): Promise<Vehicle> {
    return unwrap(await api.post<ApiResponse<Vehicle>>("/api/vehicles", payload));
  },

  async update(id: number, payload: VehiclePayload): Promise<Vehicle> {
    return unwrap(await api.put<ApiResponse<Vehicle>>(`/api/vehicles/${id}`, payload));
  },

  async listByCustomer(customerId: number): Promise<Vehicle[]> {
    return unwrap(await api.get<ApiResponse<Vehicle[]>>(`/api/customers/${customerId}/vehicles`));
  },
};

/**
 * Lỗi 400 của backend trả message chung "Dữ liệu không hợp lệ." kèm map lỗi theo field
 * trong data; ưu tiên hiển thị lỗi field đầu tiên. Các lỗi khác (404/409...) dùng message của API.
 */
export function vehicleErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError<ApiResponse<unknown>>(error)) {
    const details = error.response?.data?.data;
    if (details && typeof details === "object") {
      const first = Object.values(details as Record<string, unknown>).find((value) => typeof value === "string");
      if (typeof first === "string") return first;
    }
  }
  return errorMessage(error, fallback);
}
