import {api,unwrap} from "./client";
import type {ApiResponse} from "./types";
export type QuoteKind="SERVICE"|"PART";
export interface QuoteLine {id:number;kind:QuoteKind;itemId:number;name:string;quantity:number;unitPrice:number;amount:number}
export interface QuoteInput {kind:QuoteKind;itemId:number;quantity:number;unitPrice:number|null}
export interface Quotation {
  id:number;repairOrderId:number;customerId:number;customerName:string;vehicleId:number;plate:string;
  version:number;revision:number;status:string;createdAt:string;sentAt:string|null;decidedAt:string|null;
  createdBy:number|null;decidedBy:number|null;rejectionReason:string|null;total:number;lines:QuoteLine[];
}
export interface QuoteAudit {id:number;action:string;accountId:number|null;at:string;reason:string|null;snapshot:Quotation}
export const quoteLabels:Record<string,string>={NHAP:"Bản nháp",CHO_XAC_NHAN:"Chờ xác nhận",DA_XAC_NHAN:"Đã chấp thuận",KHONG_DONG_Y:"Đã từ chối"};
export const quotationsApi={
  async list(){return unwrap(await api.get<ApiResponse<Quotation[]>>("/api/quotations"));},
  async get(id:number){return unwrap(await api.get<ApiResponse<Quotation>>(`/api/quotations/${id}`));},
  async history(id:number){return unwrap(await api.get<ApiResponse<QuoteAudit[]>>(`/api/quotations/${id}/history`));},
  async create(repairOrderId:number,lines:QuoteInput[]){return unwrap(await api.post<ApiResponse<Quotation>>("/api/quotations",{repairOrderId,lines}));},
  async edit(quote:Quotation,lines:QuoteInput[]){return unwrap(await api.put<ApiResponse<Quotation>>(`/api/quotations/${quote.id}`,{version:quote.version,lines}));},
  async change(quote:Quotation,action:"send"|"revise",reason:string){return unwrap(await api.post<ApiResponse<Quotation>>(`/api/quotations/${quote.id}/${action}`,{version:quote.version,reason}));},
  async decide(quote:Quotation,accepted:boolean,reason:string){return unwrap(await api.post<ApiResponse<Quotation>>(`/api/quotations/${quote.id}/decision`,{version:quote.version,accepted,reason}));},
};
