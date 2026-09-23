import { api, unwrap } from "./client";
import type { Account, ApiResponse, LoginResponse } from "./types";

export interface LoginRequest {
  username: string;
  password: string;
}

export const authApi = {
  async login(payload: LoginRequest): Promise<LoginResponse> {
    return unwrap(await api.post<ApiResponse<LoginResponse>>("/api/auth/login", payload));
  },

  async me(): Promise<Account> {
    return unwrap(await api.get<ApiResponse<Account>>("/api/auth/me"));
  },

  async logout(): Promise<void> {
    await api.post<ApiResponse<null>>("/api/auth/logout");
  },
};

export type { Account, LoginResponse } from "./types";
