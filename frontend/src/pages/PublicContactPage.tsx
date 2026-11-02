import {contactMessagesApi,type ContactInput} from "../api/contactMessages";
import {errorMessage} from "../api/client";
import { useState } from "react";
import PublicFooter from "../components/PublicFooter";
import PublicHeader, { type PublicPageKey } from "../components/PublicHeader";
import { Button, Card, Icons, Input, Textarea } from "../components/ui";
import { GARAGE_NAME } from "../data";

const CONTACT_ROWS = [
  { label: "Địa chỉ", value: "123 Lê Lợi, Q.1, TP.HCM", icon: Icons.car },
  { label: "Hotline", value: "0901 234 567", href: "tel:0901234567", icon: Icons.phone },
  { label: "Giờ làm việc", value: "T2 – T7 · 07:30 – 17:30", icon: Icons.calendar },
];

interface PublicContactPageProps {
  onNavigate: (page: PublicPageKey) => void;
  onLogin: () => void;
  onBook: () => void;
  accountLabel?: string;
}

export default function PublicContactPage({ onNavigate, onLogin, onBook, accountLabel }: PublicContactPageProps) {
  const [sent, setSent] = useState<number|null>(null);
  const [busy,setBusy]=useState(false),[error,setError]=useState("");
  const [input,setInput]=useState<ContactInput>(()=>({requestId:crypto.randomUUID(),fullName:"",phone:"",plate:"",message:""}));
  async function submit(event:React.FormEvent){
    event.preventDefault();if(busy)return;setBusy(true);setError("");
    try{const receipt=await contactMessagesApi.send(input);setSent(receipt.id);}
    catch(e){setError(errorMessage(e));}finally{setBusy(false);}
  }

  return (
    <div className="min-h-screen bg-background">
      <PublicHeader active="contact" onNavigate={onNavigate} onLogin={onLogin} onBook={onBook} accountLabel={accountLabel} />
      <main>
        <div className="border-b border-border bg-surface-subtle">
          <div className="mx-auto w-full max-w-6xl px-4 py-10 sm:px-6 sm:py-14">
            <p className="text-xs font-bold uppercase tracking-widest text-accent">Liên hệ</p>
            <h1 className="ui-page-title mt-2 text-3xl sm:text-4xl">Liên hệ với gara</h1>
            <p className="ui-secondary-text mt-2 max-w-2xl text-sm">
              Gửi thông tin tình trạng xe, hỏi giá hoặc đặt lịch. {GARAGE_NAME} phản hồi trong giờ làm việc.
            </p>
          </div>
        </div>

        <div className="mx-auto grid w-full max-w-6xl gap-4 px-4 py-10 lg:grid-cols-2">
          <Card className="space-y-5 p-4 sm:p-6">
            <h2 className="ui-card-title">Thông tin liên hệ</h2>
            {CONTACT_ROWS.map((row) => (
              <div key={row.label} className="flex items-center gap-3 rounded-lg bg-surface-subtle p-3">
                <span className="flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg bg-primary-soft text-primary" aria-hidden="true">
                  {row.icon}
                </span>
                <div>
                  <p className="text-xs text-muted-foreground">{row.label}</p>
                  {row.href ? (
                    <a href={row.href} className="font-semibold text-primary hover:underline">{row.value}</a>
                  ) : (
                    <p className="font-semibold text-foreground">{row.value}</p>
                  )}
                </div>
              </div>
            ))}
            <Button onClick={onBook} className="w-full" icon={Icons.calendar}>Đặt lịch sửa chữa</Button>
          </Card>

          <Card className="p-4 sm:p-6">
            {sent ? (
              <div className="flex h-full min-h-64 flex-col items-center justify-center text-center">
                <span className="flex h-12 w-12 items-center justify-center rounded-full bg-success-soft text-success" aria-hidden="true">
                  {Icons.checkCircle}
                </span>
                <h2 className="ui-card-title mt-4">Đã nhận lời nhắn</h2>
                <p className="ui-secondary-text mt-1 max-w-sm text-sm">
                  Mã lời nhắn: {sent}. Gara sẽ liên hệ lại trong giờ làm việc. Trường hợp gấp, gọi hotline 0901 234 567.
                </p>
              </div>
            ) : (
              <form
                onSubmit={submit}
                className="space-y-4"
              >
                <h2 className="ui-card-title">Gửi lời nhắn</h2>
                {error&&<p role="alert" className="text-red-700">{error}</p>}
                <div className="grid gap-4 sm:grid-cols-2">
                  <Input label="Họ tên *" placeholder="Nguyễn Văn An" required maxLength={100} value={input.fullName} onChange={e=>setInput({...input,fullName:e.target.value})} />
                  <Input label="Số điện thoại *" placeholder="0901 234 567" required maxLength={20} value={input.phone} onChange={e=>setInput({...input,phone:e.target.value})} />
                </div>
                <Input label="Biển số xe" placeholder="51G-123.45" maxLength={20} value={input.plate} onChange={e=>setInput({...input,plate:e.target.value})} />
                <Textarea label="Nội dung *" placeholder="Xe kêu lạ khi đạp phanh, muốn kiểm tra..." required maxLength={2000} value={input.message} onChange={e=>setInput({...input,message:e.target.value})} />
                <div className="flex justify-end">
                  <Button type="submit" icon={Icons.send} disabled={busy}>{busy?"Đang gửi…":"Gửi lời nhắn"}</Button>
                </div>
              </form>
            )}
          </Card>
        </div>
      </main>
      <PublicFooter onNavigate={onNavigate} onBook={onBook} />
    </div>
  );
}
