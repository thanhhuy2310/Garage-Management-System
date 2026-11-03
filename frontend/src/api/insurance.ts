import { api, unwrap } from "./client";
import type { ApiResponse } from "./types";
export interface Company { id:number; code:string; name:string; active:boolean; phone:string|null; email:string|null; address:string|null; assessorName:string|null; assessorContact:string|null }
export interface Policy {id:number; companyId:number; policyNumber:string; verificationStatus:string; startDate:string; endDate:string; deductible:number|null; insuredAmount:number|null; certificateReference:string|null; registeredOwnerName:string|null; certificateOwnerName:string|null; repairShopTerms:string|null; partsTerms:string|null}
export interface Claim {id:number;code:string;receptionId:number;policyId:number;status:string;assessorName:string|null;assessorContact:string|null;incidentLocation:string;damageDescription:string;events:{id:number;employeeId:number;action:string;note:string;occurredAt:string}[]}
export interface Evidence {id:number;category:string;filename:string}
export interface Assessment {id:number;item:string;revision:number;damage:string;finding:string;documentId:number}
export interface Share {lineId:number;name:string;kind:string;itemId:number;total:number;requested:number;approved:number|null;payable:number|null}
export interface Proposal {id:number;quoteId:number;revision:number;direct:boolean;documentId:number|null;reference:string|null;lines:Share[]}
export interface Balance {insurerDue:number;customerDue:number;insurerPaid:number;customerPaid:number}
export interface Casework {version:number;status:string;orderId:number|null;invoiceId:number|null;documents:Evidence[];assessments:Assessment[];proposals:Proposal[];balance:Balance|null;receipts:{id:number;amount:number;receivedAt:string;reference:string}[]}
async function get<T>(path:string) {return unwrap(await api.get<ApiResponse<T>>("/api/insurance/"+path));}
export const insuranceApi={
  companies:()=>get<Company[]>("companies"),
  policies:(vehicle:number)=>get<Policy[]>("policies?vehicleId="+vehicle),
  claims:(vehicle:number)=>get<Claim[]>("claims?vehicleId="+vehicle),
  claim:(id:number)=>get<Claim>("claims/"+id),
  casework:(id:number)=>get<Casework>(`claims/${id}/finance`),
  async save<T>(path:string,body:unknown,method:"post"|"put"="post"){return unwrap(await api[method]<ApiResponse<T>>("/api/insurance/"+path,body));},
  async upload(id:number,version:number,data:FormData){
    data.set("version",String(version));
    return api.post(`/api/insurance/claims/${id}/documents`,data,{headers:{"Content-Type":"multipart/form-data"}});
  },
  async download(id:number,doc:Evidence){
    const response=await api.get<Blob>(`/api/insurance/claims/${id}/documents/${doc.id}`,{responseType:"blob"});
    const url=URL.createObjectURL(response.data);
    const link=document.createElement("a");link.href=url;link.download=doc.filename;link.click();
    setTimeout(()=>URL.revokeObjectURL(url),1000);
  },
};
