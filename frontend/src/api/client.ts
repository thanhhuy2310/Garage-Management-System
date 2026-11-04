import axios from "axios";
import { clearSession } from "./session";
import type { ApiResponse } from "./types";
import { readRoute } from "../router";

export const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL ?? "",
  withCredentials: true,
  headers: { "Content-Type": "application/json", "X-Garage-Client": "web" },
});


api.interceptors.response.use(
  (response) => response,
  (error) => {
    const requestUrl = error.config?.url as string | undefined;
    if (error.response?.status === 401 && !requestUrl?.endsWith("/api/auth/login")) {
      clearSession();
      // Public pages remain usable when a remembered session expires.
      if (readRoute().area !== "public") window.location.assign("/login");
    }
    return Promise.reject(error);
  },
);

export function unwrap<T>(response: { data: ApiResponse<T> }): T {
  return response.data.data;
}

export function errorMessage(error: unknown, fallback = "Không thể thực hiện yêu cầu. Vui lòng thử lại."): string {
  if (axios.isAxiosError<ApiResponse<unknown>>(error)) {
    return error.response?.data?.message ?? fallback;
  }
  return fallback;
}
