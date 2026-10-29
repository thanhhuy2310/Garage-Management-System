import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";

export interface CustomerNotification {
  id: number;
  title: string;
  message: string;
  createdAt: string;
  type: "appointment" | "repair" | "maintenance" | "general";
  isRead: boolean;
  appointmentId: number | null;
  repairOrderId: number | null;
  maintenanceScheduleId: number | null;
}

export interface NotificationPage {
  items: CustomerNotification[];
  page: number;
  size: number;
  totalElements: number;
  totalPages: number;
}

export const notificationsApi = {
  async list(page: number, signal?: AbortSignal) {
    return unwrap(await api.get<ApiResponse<NotificationPage>>("/api/customers/me/notifications", {
      signal,
      params: { page, size: 20 },
    }));
  },
  async unreadCount(signal?: AbortSignal) {
    return unwrap(await api.get<ApiResponse<{ count: number }>>(
      "/api/customers/me/notifications/unread-count", { signal },
    ));
  },
  async markRead(id: number) {
    return unwrap(await api.patch<ApiResponse<CustomerNotification>>(
      `/api/customers/me/notifications/${id}/read`,
    ));
  },
  async markAllRead() {
    return unwrap(await api.patch<ApiResponse<{ updatedCount: number; unreadCount: number }>>(
      "/api/customers/me/notifications/read-all",
    ));
  },
};
