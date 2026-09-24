import { api, unwrap } from "./client";
import type { Account, ApiResponse, BackendRole } from "./types";

export type StaffRole = Exclude<BackendRole, "CUSTOMER">;

export interface EmployeeOption {
  id: number;
  fullName: string;
  position: string;
  technician: boolean;
  hasAccount: boolean;
}

export interface CreateStaffAccountRequest {
  username: string;
  password: string;
  role: StaffRole;
  active: boolean;
  customerId: null;
  employeeId: number;
}

export const accountsApi = {
  async list(): Promise<Account[]> {
    return unwrap(await api.get<ApiResponse<Account[]>>("/api/accounts"));
  },

  async staffOptions(): Promise<EmployeeOption[]> {
    return unwrap(await api.get<ApiResponse<EmployeeOption[]>>("/api/accounts/staff-options"));
  },

  async create(payload: CreateStaffAccountRequest): Promise<Account> {
    return unwrap(await api.post<ApiResponse<Account>>("/api/accounts", payload));
  },

  async changeStatus(id: number, active: boolean): Promise<Account> {
    return unwrap(await api.patch<ApiResponse<Account>>(`/api/accounts/${id}/status`, { active }));
  },

  async changeRole(id: number, role: StaffRole): Promise<Account> {
    return unwrap(await api.patch<ApiResponse<Account>>(`/api/accounts/${id}/role`, { role }));
  },
};
