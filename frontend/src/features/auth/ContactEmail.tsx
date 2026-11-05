import {useState,type FormEvent} from "react";
import {api,errorMessage} from "../../api/client";
import {Button,Input} from "../../components/ui";

export default function ContactEmail({saved}:{saved:()=>void}){
  const [address,setAddress]=useState(""),[requested,setRequested]=useState(false);
  const [busy,setBusy]=useState(false),[error,setError]=useState("");
  async function submit(event:FormEvent<HTMLFormElement>){
    event.preventDefault();if(busy)return;
    const form=event.currentTarget, values=new FormData(form);
    setBusy(true);setError("");
    try{
      if(requested){
        await api.post("/api/auth/contact-email/verify",{email:address,code:values.get("code")});
        saved();
      }else{
        await api.post("/api/auth/contact-email/request",{email:address,password:values.get("password")});
        form.reset();setRequested(true);
      }
    }catch(ex){setError(errorMessage(ex));}finally{setBusy(false);}
  }
  return <details><summary>Cập nhật email khôi phục</summary><form onSubmit={submit} className="mt-3 space-y-3">
    <Input type="email" label="Email mới" value={address} onChange={e=>setAddress(e.target.value)} required readOnly={requested}/>
    {requested?<Input name="code" label="Mã xác minh trong email mới" autoComplete="one-time-code" pattern="[0-9]{6}" required/>:
    <Input name="password" type="password" autoComplete="current-password" label="Mật khẩu hiện tại" required/>}
    {error&&<p role="alert">{error}</p>}<Button type="submit" disabled={busy}>{requested?"Xác minh email":"Gửi mã xác minh"}</Button>
    {requested&&<Button type="button" disabled={busy} onClick={()=>{setRequested(false);setError("");}}>Đổi email hoặc gửi lại</Button>}
  </form></details>;
}
