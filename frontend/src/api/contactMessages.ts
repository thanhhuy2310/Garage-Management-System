import axios from "axios";
import {api,unwrap} from "./client";
import type {ApiResponse} from "./types";
const publicClient=axios.create({baseURL:import.meta.env.VITE_API_URL??""});
export interface ContactInput {requestId:string;fullName:string;phone:string;plate:string;message:string}
export interface ContactMessage extends Omit<ContactInput,"requestId"> {id:number;createdAt:string;read:boolean}
interface Page {items:ContactMessage[];totalPages:number}
export const contactMessagesApi={
  async send(input:ContactInput){return (await publicClient.post<ApiResponse<{id:number;createdAt:string}>>("/api/public/contact-messages",input)).data.data;},
  async list(){
    const items:ContactMessage[]=[];let page=0;
    while(true){const result=unwrap(await api.get<ApiResponse<Page>>("/api/contact-messages",{params:{page,size:100}}));items.push(...result.items);if(++page>=result.totalPages)return items;}
  },
  async read(id:number){return unwrap(await api.patch<ApiResponse<ContactMessage>>(`/api/contact-messages/${id}/read`));},
  async readAll(){return unwrap(await api.patch<ApiResponse<{updated:number}>>("/api/contact-messages/read-all"));},
};
