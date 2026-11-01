import {api,unwrap} from "./client";
import type {ApiResponse} from "./types";
export interface DashboardData {
  date:string;receivedToday:number;collectedToday:number;
  dailyRevenue:{period:string;revenue:number}[];
  monthlyRevenue:{period:string;revenue:number}[];
  popularServices:{id:number;name:string;count:number}[];
}
export const dashboardApi={async get(){return unwrap(await api.get<ApiResponse<DashboardData>>("/api/reports/dashboard"));}};
