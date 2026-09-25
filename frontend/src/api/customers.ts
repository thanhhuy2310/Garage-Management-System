import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";

export interface Customer {
  id: number;
  fullName: string;
  phone: string;
  email: string | null;
  address: string | null;
  active: boolean;
}

export interface CustomerPayload {
  fullName: string;
  phone: string;
  email: string;
  address: string;
}

export const customersApi = {
  async list(): Promise<Customer[]> {
    return unwrap(await api.get<ApiResponse<Customer[]>>("/api/customers"));
  },

  async create(payload: CustomerPayload): Promise<Customer> {
    return unwrap(await api.post<ApiResponse<Customer>>("/api/customers", payload));
  },

  async update(id: number, payload: CustomerPayload): Promise<Customer> {
    return unwrap(await api.put<ApiResponse<Customer>>(`/api/customers/${id}`, payload));
  },

  async changeStatus(id: number, active: boolean): Promise<Customer> {
    return unwrap(await api.patch<ApiResponse<Customer>>(`/api/customers/${id}/status`, { active }));
  },
};
