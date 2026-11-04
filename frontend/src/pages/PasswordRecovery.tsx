import {useState,type FormEvent} from "react";
import {api,errorMessage,unwrap} from "../api/client";
import type {ApiResponse} from "../api/types";
import AuthLayout from "../components/auth/AuthLayout";
import {Input,Button} from "../components/ui";

export default function PasswordRecovery({back}:{back:()=>void}) {
  const [step,setStep]=useState(0),[email,setEmail]=useState(""),[ticket,setTicket]=useState("");
  const [busy,setBusy]=useState(false),[error,setError]=useState("");
  async function submit(event:FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if(busy)return;
    const values=new FormData(event.currentTarget);
    setBusy(true);setError("");
    try {
      if(step===0)await api.post("/api/auth/recovery/request",{email:email.trim()});
      if(step===1)setTicket(unwrap(await api.post<ApiResponse<string>>("/api/auth/recovery/verify",{email,code:values.get("code")})));
      if(step===2){
        if(values.get("password")!==values.get("confirmation")){setError("Mật khẩu xác nhận chưa khớp.");return;}
        await api.post("/api/auth/recovery/complete",{email,ticket,password:values.get("password"),confirmation:values.get("confirmation")});
        setTicket("");
      }
      setStep(step+1);
    }catch(ex){setError(errorMessage(ex));}finally{setBusy(false);}
  }
  return <AuthLayout><h2 className="mb-4 text-2xl font-semibold">Quên mật khẩu</h2>
    {step===3?<p role="status">Đã đổi mật khẩu. Bạn có thể đăng nhập bằng mật khẩu mới.</p>:
    <form onSubmit={submit} key={step} className="space-y-4">
      {step===0&&<Input label="Email liên kết với tài khoản" type="email" autoComplete="email" value={email} onChange={e=>setEmail(e.target.value)} maxLength={150} required/>}
      {step===1&&<><p>Nếu email {email} liên kết với tài khoản, hãy kiểm tra hộp thư và nhập mã trong 15 phút.</p>
        <Input label="Mã xác minh" name="code" autoComplete="one-time-code" inputMode="numeric" pattern="[0-9]{6}" maxLength={6} required/>
        <Button type="button" variant="outline" disabled={busy} onClick={()=>{setStep(0);setError("");}}>Nhập lại email hoặc yêu cầu mã mới</Button></>}
      {step===2&&<><Input type="password" name="password" label="Mật khẩu mới" autoComplete="new-password" minLength={8} maxLength={72} required/>
        <Input type="password" name="confirmation" label="Nhập lại mật khẩu mới" autoComplete="new-password" required/></>}
      {error&&<p role="alert" className="text-danger">{error}</p>}
      <Button disabled={busy} type="submit">{busy?"Đang xử lý…":["Gửi mã xác minh","Xác minh","Đổi mật khẩu"][step]}</Button>
    </form>}
    <Button className="mt-4" variant="outline" onClick={back}>Về đăng nhập</Button></AuthLayout>;
}
