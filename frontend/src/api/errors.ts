// TV3-TUAN7
import axios from "axios";
import { errorMessage } from "./client";
import type { ApiResponse } from "./types";

/**
 * Backend trả lỗi 400 với message chung kèm map lỗi theo field trong data:
 * ưu tiên hiển thị lỗi field đầu tiên. Các lỗi khác (404/409...) dùng message của API.
 */
export function detailedErrorMessage(error: unknown, fallback: string): string {
  if (axios.isAxiosError<ApiResponse<unknown>>(error)) {
    const details = error.response?.data?.data;
    if (details && typeof details === "object") {
      const first = Object.values(details as Record<string, unknown>).find((value) => typeof value === "string");
      if (typeof first === "string") return first;
    }
  }
  return errorMessage(error, fallback);
}
