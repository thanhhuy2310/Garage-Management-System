import {useState,type ReactNode} from "react";
import {Button} from "../../components/ui";
import {errorMessage} from "../../api/client";
export function InsuranceForm({title,children,save,done,label="Lưu"}:{title:string;children:ReactNode;save:(f:FormData)=>Promise<unknown>;done:()=>void;label?:string}){
  const [busy,setBusy]=useState(false),[error,setError]=useState("");
  return <details className="rounded-lg border p-4"><summary className="cursor-pointer font-semibold">{title}</summary>
    <form className="mt-3 space-y-3" onSubmit={async e=>{e.preventDefault();if(busy)return;const form=e.currentTarget;
      setBusy(true);setError("");try{await save(new FormData(form));form.reset();done();}catch(ex){setError(errorMessage(ex));}finally{setBusy(false);}
    }}><fieldset disabled={busy} className="space-y-3">{children}<Button type="submit">{busy?"Đang lưu…":label}</Button></fieldset>
    {error&&<p role="alert" className="text-danger">{error}</p>}</form></details>;
}
export const val=(f:FormData,key:string)=>String(f.get(key)??"").trim();
const statuses:Record<string,string>={MOI_TAO:"Mới tạo",DA_THONG_BAO:"Đã thông báo",CHO_GIAM_DINH:"Chờ giám định",DANG_XU_LY:"Đang xử lý",DA_DONG:"Đã đóng",TU_CHOI:"Từ chối",DA_XAC_MINH:"Đã xác minh",CHUA_XAC_MINH:"Chưa xác minh",KHONG_HOP_LE:"Không hợp lệ"};
export const statusName=(s:string)=>statuses[s]??s;
