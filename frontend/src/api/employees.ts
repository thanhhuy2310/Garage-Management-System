import { api, unwrap } from "./client";
import type { ApiResponse, BackendRole } from "./types";

export interface EmployeeInput {
  fullName: string;
  phone: string;
  email: string;
  position: string;
  technician: boolean;
}
export interface Employee extends Omit<EmployeeInput, "phone" | "email"> {
  id: number;
  phone: string | null;
  email: string | null;
  username: string | null;
  accountRole: BackendRole | null;
  accountActive: boolean | null;
}
export const employeesApi = {
  async list() { return unwrap(await api.get<ApiResponse<Employee[]>>("/api/employees")); },
  async get(id: number) { return unwrap(await api.get<ApiResponse<Employee>>(`/api/employees/${id}`)); },
  async create(input: EmployeeInput) { return unwrap(await api.post<ApiResponse<Employee>>("/api/employees", input)); },
  async update(id: number, input: EmployeeInput) { return unwrap(await api.put<ApiResponse<Employee>>(`/api/employees/${id}`, input)); },
};
