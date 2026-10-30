import {api,unwrap} from "./client";
import type {ApiResponse} from "./types";
export interface ReceptionInput {
  customerId:number; vehicleId:number; appointmentId:number|null; mileage:number|null;
  initialCondition:string; customerRequest:string; notes:string;
}
export interface Reception extends ReceptionInput {
  id:number; customerName:string; licensePlate:string; receivedAt:string; updatedAt:string|null;
  receivedBy:number|null; version:number; repairOrderId:number|null; repairStatus:string|null;
}
export const receptionsApi={
  async list(){return unwrap(await api.get<ApiResponse<Reception[]>>("/api/receptions"));},
  async get(id:number){return unwrap(await api.get<ApiResponse<Reception>>(`/api/receptions/${id}`));},
  async create(input:ReceptionInput){return unwrap(await api.post<ApiResponse<Reception>>("/api/receptions",input));},
  async update(item:Reception,input:ReceptionInput){return unwrap(await api.put<ApiResponse<Reception>>(`/api/receptions/${item.id}`,{...input,version:item.version}));},
};
