import {useState} from "react";
import {Card,Button,Tabs,Icons} from "../components/ui";
import {contactMessagesApi} from "../api/contactMessages";
import {errorMessage} from "../api/client";
import {useGarageQuery} from "../hooks/useGarageQuery";
import {QueryState} from "../components/garage/QueryState";
import {formatGarageDate} from "../utils/garageFormat";

export default function Notifications(){
  const query=useGarageQuery(contactMessagesApi.list);
  const [filter,setFilter]=useState("all"),[busy,setBusy]=useState(false),[error,setError]=useState("");
  const messages=query.data??[];
  const filtered=messages.filter(m=>filter==="all"||(filter==="read"?m.read:!m.read));
  async function markRead(id?:number){
    if(busy)return;setBusy(true);setError("");
    try{if(id===undefined)await contactMessagesApi.readAll();else await contactMessagesApi.read(id);
      query.setData(await contactMessagesApi.list());
    }catch(e){setError(errorMessage(e));}finally{setBusy(false);}
  }
  return <div className="space-y-5">
    <p className="text-sm text-slate-600">Lời nhắn khách hàng gửi từ trang Liên hệ.</p>
    <QueryState {...query} onRetry={query.reload}/>
    {error&&<p role="alert" className="text-red-700">{error}</p>}
    {query.data&&<>
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <Tabs tabs={[{key:"all",label:"Tất cả",count:messages.length},{key:"unread",label:"Chưa đọc",count:messages.filter(m=>!m.read).length},{key:"read",label:"Đã đọc"}]} active={filter} onChange={setFilter}/>
        <Button variant="ghost" size="sm" disabled={busy||messages.every(m=>m.read)} onClick={()=>void markRead()}>Đánh dấu tất cả đã đọc</Button>
      </div>
      <div className="max-w-3xl space-y-2">
        {filtered.length===0&&<Card className="py-16 text-center text-slate-500">Không có lời nhắn nào.</Card>}
        {filtered.map(m=><button key={m.id} type="button" disabled={busy} onClick={()=>{if(!m.read)void markRead(m.id);}}
          aria-label={`${m.read?"Lời nhắn đã đọc":"Đánh dấu đã đọc"}: ${m.fullName}`}
          className={`flex w-full items-start gap-4 rounded-lg border bg-surface p-4 text-left transition-all hover:border-primary/50 ${!m.read?"border-info/30 bg-info-soft/50":"border-border"}`}>
          <span className="flex h-10 w-10 shrink-0 items-center justify-center rounded-xl bg-info-soft text-info">{Icons.send}</span>
          <div className="min-w-0 flex-1">
            <div className="flex justify-between gap-2"><p className="text-sm font-semibold">{m.fullName} · {m.phone}</p>{!m.read&&<span aria-label="Chưa đọc" className="mt-1.5 h-2 w-2 rounded-full bg-info"/>}</div>
            {m.plate&&<p className="mt-1 text-xs text-slate-500">Biển số: {m.plate}</p>}
            <p className="mt-1 whitespace-pre-wrap break-words text-sm text-slate-600">{m.message}</p>
            <p className="mt-1 text-xs text-slate-400">#{m.id} · {formatGarageDate(m.createdAt)}</p>
          </div>
        </button>)}
      </div>
    </>}
  </div>;
}
