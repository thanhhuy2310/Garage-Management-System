import { api, unwrap } from "./client"
import type { ApiResponse } from "./types"
import type {
  AssignmentRequest,
  GarageService,
  RepairOrder,
  RepairOrderDetail,
  ServiceRequest,
  Technician,
  TechnicianAssignment,
  ProgressRequest,
  ReceptionOption,
} from "../types/garage"

export const garageApi = {
  async receptions(signal?: AbortSignal) {
    return unwrap(
      await api.get<ApiResponse<ReceptionOption[]>>(
        "/api/repair-orders/receptions",
        { signal },
      ),
    )
  },
  async createRepair(request: {
    receptionId: number
    services: { serviceId: number; quantity: number }[]
  }) {
    return unwrap(
      await api.post<ApiResponse<RepairOrderDetail>>(
        "/api/repair-orders",
        request,
      ),
    )
  },
  async addRepairService(
    id: number,
    request: { serviceId: number; quantity: number },
  ) {
    return unwrap(
      await api.post<ApiResponse<RepairOrderDetail>>(
        `/api/repair-orders/${id}/services`,
        request,
      ),
    )
  },
  async updateProgress(
    id: number,
    request: ProgressRequest,
    serviceId?: number,
  ) {
    const path = serviceId ? `services/${serviceId}/progress` : "progress"
    return unwrap(
      await api.put<ApiResponse<RepairOrderDetail>>(
        `/api/repair-orders/${id}/${path}`,
        request,
      ),
    )
  },
  async services(signal?: AbortSignal) {
    return unwrap(
      await api.get<ApiResponse<GarageService[]>>("/api/services", { signal }),
    )
  },
  async createService(request: ServiceRequest) {
    return unwrap(
      await api.post<ApiResponse<GarageService>>("/api/services", request),
    )
  },
  async updateService(id: number, request: ServiceRequest) {
    return unwrap(
      await api.put<ApiResponse<GarageService>>(`/api/services/${id}`, request),
    )
  },
  async repairOrders(signal?: AbortSignal) {
    return unwrap(
      await api.get<ApiResponse<RepairOrder[]>>("/api/repair-orders", {
        signal,
      }),
    )
  },
  async repairOrder(id: number, signal?: AbortSignal) {
    return unwrap(
      await api.get<ApiResponse<RepairOrderDetail>>(
        `/api/repair-orders/${id}`,
        { signal },
      ),
    )
  },
  async technicians(signal?: AbortSignal) {
    return unwrap(
      await api.get<ApiResponse<Technician[]>>("/api/technicians", { signal }),
    )
  },
  async assignTechnician(id: number, request: AssignmentRequest) {
    return unwrap(
      await api.post<ApiResponse<TechnicianAssignment>>(
        `/api/repair-orders/${id}/technicians`,
        request,
      ),
    )
  },
}
