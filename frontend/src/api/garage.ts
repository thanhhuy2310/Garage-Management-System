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
} from "../types/garage"

export const garageApi = {
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
