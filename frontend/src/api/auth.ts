import { api, unwrap } from "./client";
import type { Account, ApiResponse, LoginResponse } from "./types";

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  fullName: string;
  phone: string;
  email?: string;
  address?: string;
  username: string;
  password: string;
}

export interface ChangePasswordRequest {
  currentPassword: string;
  newPassword: string;
}

export const authApi = {
  async login(payload: LoginRequest, remember = false): Promise<LoginResponse> {
    return unwrap(await api.post<ApiResponse<LoginResponse>>("/api/auth/login", payload, {params:{remember}}));
  },

  async register(payload: RegisterRequest): Promise<LoginResponse> {
    return unwrap(await api.post<ApiResponse<LoginResponse>>("/api/auth/register", payload));
  },

  async me(): Promise<Account> {
    return unwrap(await api.get<ApiResponse<Account>>("/api/auth/me"));
  },

  async logout(): Promise<void> {
    await api.post<ApiResponse<null>>("/api/auth/logout");
  },

  async changePassword(payload: ChangePasswordRequest): Promise<void> {
    await api.put<ApiResponse<null>>("/api/auth/change-password", payload);
  },
};

export type { Account, LoginResponse } from "./types";
