export interface ApiResponse<T> {
  success: boolean;
  message: string;
  data: T;
}

export type BackendRole =
  | "CUSTOMER"
  | "RECEPTIONIST"
  | "TECHNICIAN"
  | "WAREHOUSE"
  | "MANAGER"
  | "ADMIN";

export interface Account {
  id: number;
  username: string;
  role: BackendRole;
  active: boolean;
  customerId: number | null;
  employeeId: number | null;
}

export interface LoginResponse {
  accessToken: string;
  tokenType: string;
  expiresIn: number;
  account: Account;
}
