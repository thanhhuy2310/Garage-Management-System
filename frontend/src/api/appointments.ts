import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";

export interface Appointment {
  id: number; customerId: number; customerName: string; vehicleId: number; plate: string;
  serviceId: number | null; serviceName: string | null; date: string; time: string;
  note: string | null; status: string; version: number;
}
export interface BookingInput { vehicleId: number; serviceId: number | null; date: string; time: string; note: string }
export interface BookingSlot { time: string; capacity: number; remaining: number }
export interface Availability { date: string; configured: boolean; slots: BookingSlot[] }
export interface ScheduleSlot { dayOfWeek: number; time: string; capacity: number }
export const appointmentLabels: Record<string,string> = {
  CHO_XAC_NHAN: "Chờ xác nhận", DA_XAC_NHAN: "Đã xác nhận", DA_DEN: "Đã tiếp nhận",
  HUY: "Đã hủy", DA_HUY: "Đã hủy", HOAN_TAT: "Hoàn tất",
};
export const appointmentsApi = {
  async list() { return unwrap(await api.get<ApiResponse<Appointment[]>>("/api/appointments")); },
  async availability(date: string, signal?: AbortSignal) {
    return unwrap(await api.get<ApiResponse<Availability>>("/api/appointments/availability", {params:{date},signal}));
  },
  async create(input: BookingInput) { return unwrap(await api.post<ApiResponse<Appointment>>("/api/appointments",input)); },
  async move(item: Appointment,date: string,time: string,reason: string) {
    return unwrap(await api.patch<ApiResponse<Appointment>>(`/api/appointments/${item.id}/reschedule`,{date,time,reason,version:item.version}));
  },
  async change(item: Appointment,action:"cancel"|"confirm",reason: string) {
    return unwrap(await api.patch<ApiResponse<Appointment>>(`/api/appointments/${item.id}/${action}`,{version:item.version,reason}));
  },
  async schedule() { return unwrap(await api.get<ApiResponse<ScheduleSlot[]>>("/api/appointments/schedule")); },
  async configure(input: ScheduleSlot) { return unwrap(await api.put<ApiResponse<ScheduleSlot[]>>("/api/appointments/schedule",input)); },
};
