import {api,unwrap} from './client'
import type {ApiResponse} from './types'
export interface CustomerInvoice {
  id:number;repairOrderId:number;vehicleId:number;licensePlate:string;createdAt:string
  total:number;insuranceSupport:number;customerDue:number|null;customerPaid:number;remaining:number|null;status:string;awaitingInsurance:boolean
  lines:{type:string;id:number;name:string;quantity:number;unitPrice:number}[]
  payments:{paidAt:string;amount:number;method:string;payer:string}[]
}
export interface VehicleStats {
  vehicle:{id:number;licensePlate:string;brand:string|null;model:string|null;currentlyOwned:boolean};completedVisits:number;repairVisits:number;maintenanceVisits:number
  totalCost:number;customerCost:number;awaitingInvoicesOrInsurance:number;lastRepair:string|null
}
export interface CustomerStats {
  vehicleCount:number;completedVisits:number;repairVisits:number;maintenanceVisits:number;totalCost:number;customerCost:number;awaitingInvoicesOrInsurance:number
  vehicles:VehicleStats[];months:{year:number;month:number;completedVisits:number;totalCost:number;customerCost:number}[]
}
export const customerFinanceApi={
  async invoices(signal?:AbortSignal){return unwrap(await api.get<ApiResponse<CustomerInvoice[]>>('/api/customers/me/invoices',{signal}))},
  async statistics(vehicleId?:number,year?:number,signal?:AbortSignal){return unwrap(await api.get<ApiResponse<CustomerStats>>('/api/customers/me/statistics',{signal,params:{vehicleId,year}}))},
}
