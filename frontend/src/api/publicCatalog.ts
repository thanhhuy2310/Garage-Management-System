import axios from "axios";
import type {ApiResponse} from "./types";
import type {GarageService} from "../types/garage";
const publicClient=axios.create({baseURL:import.meta.env.VITE_API_URL ?? ""});
export type InventoryStatus="ok"|"low"|"out";
export interface PublicPart {MaPhuTung:number;TenPhuTung:string;HangSanXuat:string|null;DonGia:number;SoLuongTon:number;TonToiThieu:number}
export interface PublicService {MaDichVu:number;TenDichVu:string;LoaiDichVu:string|null;DonGia:number;MoTa:string|null}
interface Part {id:number;name:string;manufacturer:string|null;unitPrice:number;stockQuantity:number;minStockLevel:number}
interface PartPage {items:Part[];totalPages:number}
export function getInventoryStatus(part:PublicPart):InventoryStatus {return part.SoLuongTon<=0?"out":part.SoLuongTon<=part.TonToiThieu?"low":"ok";}
function serviceLabel(value:string|null) {return value==="BAO_DUONG"?"Bảo dưỡng":value==="SUA_CHUA"?"Sửa chữa":value==="KIEM_TRA"?"Kiểm tra":value;}
export const publicCatalogApi={
  async load(signal:AbortSignal) {
    const [services,first]=await Promise.all([
      publicClient.get<ApiResponse<GarageService[]>>("/api/public/services",{signal}),
      publicClient.get<ApiResponse<PartPage>>("/api/public/parts",{signal,params:{page:0,size:100}}),
    ]);
    const parts=[...first.data.data.items];
    for(let page=1;page<first.data.data.totalPages;page++) {
      const next=await publicClient.get<ApiResponse<PartPage>>("/api/public/parts",{signal,params:{page,size:100}});
      parts.push(...next.data.data.items);
    }
    return {
      services:services.data.data.map((s):PublicService=>({MaDichVu:s.id,TenDichVu:s.name,LoaiDichVu:serviceLabel(s.type),DonGia:s.unitPrice,MoTa:s.description})),
      parts:parts.map((p):PublicPart=>({MaPhuTung:p.id,TenPhuTung:p.name,HangSanXuat:p.manufacturer,DonGia:p.unitPrice,SoLuongTon:p.stockQuantity,TonToiThieu:p.minStockLevel})),
    };
  },
};
