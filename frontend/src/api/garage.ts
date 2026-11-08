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
  async approvedRepairParts(id: number, signal?: AbortSignal) {
    return unwrap(await api.get<ApiResponse<{id:number;name:string;approvedQuantity:number;unitPrice:number;issuedQuantity:number;returnedQuantity:number;actualUsedQuantity:number;status:string}[]>>(`/api/repair-orders/${id}/approved-parts`, { signal }))
  },
  async technicianWorkload(signal?: AbortSignal) {
    return unwrap(await api.get<ApiResponse<import('../types/garage').TechnicianWorkload[]>>('/api/technicians/workload', { signal }))
  },
  async technicianSchedule(date: string, signal?: AbortSignal) {
    return unwrap(await api.get<ApiResponse<import('../types/garage').TechnicianWorkload[]>>('/api/technicians/workload', { signal, params: { date } }))
  },
  async technicianShifts(signal?: AbortSignal) {
    return unwrap(await api.get<ApiResponse<import('../types/garage').TechnicianShift[]>>('/api/technicians/shifts', { signal }))
  },
  async saveTechnicianSchedule(id: number, request: { date: string; shiftIds: number[]; vehicleLimit: number }) {
    return unwrap(await api.put<ApiResponse<null>>(`/api/technicians/${id}/schedule`, request))
  },
  async saveTechnicianShift(id: number | null, request: { name: string; start: string; end: string }) {
    return unwrap(await (id === null ? api.post<ApiResponse<null>>('/api/technicians/shifts', request) : api.put<ApiResponse<null>>(`/api/technicians/shifts/${id}`, request)))
  },
  async allServices(signal?: AbortSignal) {
    return unwrap(await api.get<ApiResponse<GarageService[]>>("/api/services", { signal, params: { includeInactive: true } }));
  },
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
  async assignTechnician(id: number, request: AssignmentRequest, previousTechnician?: number) {
    return unwrap(
      await api.post<ApiResponse<TechnicianAssignment>>(
        previousTechnician == null ? `/api/repair-orders/${id}/technicians` : `/api/repair-orders/${id}/technicians/${previousTechnician}/transfer`,
        request,
      ),
    )
  },
}
