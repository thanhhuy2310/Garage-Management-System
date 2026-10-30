import {formatGarageDate} from "../../utils/garageFormat";
import {useCallback,useEffect,useState} from "react";
import {quotationsApi,quoteLabels,type Quotation,type QuoteAudit,type QuoteKind,type QuoteInput} from "../../api/quotations";
import {garageApi} from "../../api/garage";
import {sparePartsApi,type SparePart} from "../../api/spareParts";
import {errorMessage} from "../../api/client";
import type {GarageService,RepairOrder} from "../../types/garage";
import {Button,Card,Input,Modal,Select,Textarea} from "../../components/ui";

const money=(value:number)=>new Intl.NumberFormat("vi-VN",{style:"currency",currency:"VND",maximumFractionDigits:2}).format(value);
const when=formatGarageDate;
type Row={kind:QuoteKind;itemId:string;quantity:string;price:string};
type Action="send"|"revise"|"accept"|"reject";
const emptyRow=():Row=>({kind:"SERVICE",itemId:"",quantity:"1",price:""});
const actionLabel:Record<Action,string>={send:"Gửi khách xác nhận",revise:"Tạo lần điều chỉnh",accept:"Chấp thuận báo giá",reject:"Từ chối báo giá"};

export default function QuotationWorkspace({customer=false}:{customer?:boolean}) {
  const [items,setItems]=useState<Quotation[]>([]),[selected,setSelected]=useState<number|null>(null);
  const [loading,setLoading]=useState(true),[error,setError]=useState(""),[notice,setNotice]=useState("");
  const [search,setSearch]=useState(""),[status,setStatus]=useState("");
  const [history,setHistory]=useState<QuoteAudit[]|null>(null),[snapshot,setSnapshot]=useState<Quotation|null>(null);
  const [historyLoading,setHistoryLoading]=useState(false);
  const [editor,setEditor]=useState(false),[editing,setEditing]=useState<Quotation|null>(null);
  const [orderId,setOrderId]=useState(""),[orders,setOrders]=useState<RepairOrder[]>([]);
  const [services,setServices]=useState<GarageService[]>([]),[parts,setParts]=useState<SparePart[]>([]);
  const [rows,setRows]=useState<Row[]>([emptyRow()]),[catalogLoading,setCatalogLoading]=useState(false);
  const [busy,setBusy]=useState(false),[formError,setFormError]=useState("");
  const [action,setAction]=useState<{name:Action;quote:Quotation}|null>(null),[reason,setReason]=useState("");
  const current=items.find(q=>q.id===selected),detail=snapshot??current;
  const load=useCallback(async()=>{
    setLoading(true);setError("");
    try {const data=await quotationsApi.list();setItems(data);setSelected(id=>data.some(q=>q.id===id)?id:data[0]?.id??null);}
    catch(e){setError(errorMessage(e));}finally{setLoading(false);}
  },[]);
  useEffect(()=>{void load();},[load]);
  useEffect(()=>{
    if(!editor || editing || !orderId)return;
    let active=true;setCatalogLoading(true);
    garageApi.repairOrder(Number(orderId)).then(data=>{if(active)setRows(data.services.length?data.services.map(s=>
      ({kind:"SERVICE" as const,itemId:String(s.id),quantity:String(s.quantity),price:String(s.unitPrice)})):[emptyRow()]);})
      .catch(e=>{if(active)setFormError(errorMessage(e));}).finally(()=>{if(active)setCatalogLoading(false);});
    return()=>{active=false;};
  },[editor,editing,orderId]);
  async function openEditor(quote:Quotation|null){
    setEditing(quote);setOrderId(quote?String(quote.repairOrderId):"");setFormError("");setEditor(true);setCatalogLoading(true);
    setRows(quote?quote.lines.map(l=>({kind:l.kind,itemId:String(l.itemId),quantity:String(l.quantity),price:String(l.unitPrice)})):[emptyRow()]);
    try {
      const [catalog,repairs,firstParts]=await Promise.all([garageApi.services(),garageApi.repairOrders(),sparePartsApi.list({size:100})]);
      const allParts=[...firstParts.items];
      for(let page=1;page<firstParts.totalPages;page++)allParts.push(...(await sparePartsApi.list({page,size:100})).items);
      setServices(catalog);setOrders(repairs.filter(r=>!["HOAN_TAT","HUY","DA_HUY"].includes(r.status)));setParts(allParts);
    }catch(e){setFormError(errorMessage(e));}finally{setCatalogLoading(false);}
  }
  function updateRow(index:number,update:Partial<Row>){setRows(old=>old.map((r,i)=>i===index?{...r,...update}:r));}
  async function saved(item:Quotation,message:string){
    setEditor(false);setAction(null);setSnapshot(null);setHistory(null);await load();setSelected(item.id);setNotice(message);
  }
  async function save(event:React.FormEvent){
    event.preventDefault();if(busy)return;setBusy(true);setFormError("");
    try{
      const lines:QuoteInput[]=rows.map(r=>({kind:r.kind,itemId:Number(r.itemId),quantity:Number(r.quantity),unitPrice:r.price===""?null:Number(r.price)}));
      const item=editing?await quotationsApi.edit(editing,lines):await quotationsApi.create(Number(orderId),lines);
      await saved(item,"Đã lưu bản nháp. Gửi khách xác nhận khi nội dung đã đầy đủ.");
    }catch(e){setFormError(errorMessage(e));}finally{setBusy(false);}
  }
  function openAction(name:Action,quote:Quotation){setAction({name,quote});setReason("");setFormError("");}
  async function execute(event:React.FormEvent){
    event.preventDefault();if(!action||busy)return;setBusy(true);setFormError("");
    try{
      const {name,quote}=action;
      const updated=name==="accept"||name==="reject"?await quotationsApi.decide(quote,name==="accept",reason):await quotationsApi.change(quote,name,reason);
      await saved(updated,name==="revise"?"Đã tạo bản nháp điều chỉnh. Sửa nội dung rồi gửi khách duyệt lại.":"Đã lưu thay đổi báo giá.");
    }catch(e){setFormError(errorMessage(e));}finally{setBusy(false);}
  }
  async function showHistory(){
    if(!current)return;setHistoryLoading(true);setError("");
    try{setHistory(await quotationsApi.history(current.id));}catch(e){setError(errorMessage(e));}finally{setHistoryLoading(false);}
  }
  const filtered=items.filter(q=>(!status||q.status===status)&&`${q.id} ${q.plate} ${q.customerName}`.toLocaleLowerCase("vi").includes(search.toLocaleLowerCase("vi")));
  return <div className="space-y-5">
    <div className="flex flex-wrap items-end gap-3">
      <Input label="Tìm báo giá" placeholder="Biển số, tên khách hoặc mã báo giá" value={search} onChange={e=>setSearch(e.target.value)}/>
      <Select label="Trạng thái" value={status} onChange={e=>setStatus(e.target.value)} options={[{value:"",label:"Tất cả"},...Object.entries(quoteLabels).filter(([value])=>!customer||value!=="NHAP").map(([value,label])=>({value,label}))]}/>
      <Button variant="outline" onClick={()=>{setSnapshot(null);setHistory(null);void load();}}>Tải lại</Button>
      {!customer&&<Button onClick={()=>void openEditor(null)}>Tạo báo giá</Button>}
    </div>
    {notice&&<p role="status" className="rounded-lg bg-success-soft p-3">{notice}</p>}
    {error&&<p role="alert" className="rounded-lg bg-danger-soft p-3 text-danger">{error}</p>}
    {loading?<p role="status">Đang tải báo giá…</p>:<div className="grid gap-5 xl:grid-cols-3">
      <div className="space-y-3">
        {!filtered.length&&<Card className="p-5">Chưa có báo giá phù hợp.</Card>}
        {filtered.map(q=><button type="button" key={q.id} aria-pressed={selected===q.id} onClick={()=>{setSelected(q.id);setHistory(null);setSnapshot(null);}}
          className={`w-full rounded-lg border bg-surface p-4 text-left ${selected===q.id?"border-primary ring-1 ring-primary":"border-border"}`}>
          <div className="flex flex-wrap justify-between gap-2"><strong>BG{q.id} · {q.plate}</strong><span className="text-sm">{quoteLabels[q.status]??q.status}</span></div>
          <p className="mt-2 text-sm text-muted-foreground">{q.customerName} · Lần {q.revision}</p><p className="mt-2 font-bold text-primary">{money(q.total)}</p>
        </button>)}
      </div>
      {detail&&<Card className="space-y-5 p-4 sm:p-6 xl:col-span-2">
        {snapshot&&<div className="rounded-lg bg-info-soft p-3"><p>Đang xem nội dung đã lưu trong lịch sử.</p><Button variant="outline" onClick={()=>setSnapshot(null)}>Về bản hiện hành</Button></div>}
        <div><h2 className="text-xl font-bold">Báo giá BG{detail.id}</h2><p className="mt-1">{quoteLabels[detail.status]??detail.status} · Lần {detail.revision}</p></div>
        <dl className="grid gap-3 text-sm sm:grid-cols-2"><div><dt className="text-muted-foreground">Khách hàng</dt><dd>{detail.customerName}</dd></div>
          <div><dt className="text-muted-foreground">Xe / phiếu sửa chữa</dt><dd>{detail.plate} · PSC{detail.repairOrderId}</dd></div>
          <div><dt className="text-muted-foreground">Ngày gửi</dt><dd>{when(detail.sentAt)}</dd></div><div><dt className="text-muted-foreground">Khách phản hồi</dt><dd>{when(detail.decidedAt)}</dd></div></dl>
        <ul className="divide-y divide-border">{detail.lines.map(l=><li key={l.id} className="flex flex-wrap justify-between gap-3 py-3">
          <div className="min-w-0"><p className="font-semibold break-words">{l.name}</p><p className="text-sm text-muted-foreground">{l.kind==="SERVICE"?"Dịch vụ":"Phụ tùng dự kiến"} · {l.quantity} × {money(l.unitPrice)}</p></div><strong>{money(l.amount)}</strong>
        </li>)}</ul>
        <p className="flex flex-wrap justify-between gap-2 border-t border-border pt-4 text-lg font-bold"><span>Tổng báo giá</span><span>{money(detail.total)}</span></p>
        {detail.rejectionReason&&<p>Lý do từ chối: {detail.rejectionReason}</p>}
        {!snapshot&&current&&<div className="flex flex-wrap gap-2">
          {!customer&&current.status==="NHAP"&&<><Button onClick={()=>void openEditor(current)}>Sửa bản nháp</Button><Button variant="secondary" onClick={()=>openAction("send",current)}>Gửi khách xác nhận</Button></>}
          {!customer&&current.status!=="NHAP"&&<Button onClick={()=>openAction("revise",current)}>Tạo lần điều chỉnh</Button>}
          {customer&&current.status==="CHO_XAC_NHAN"&&<><Button onClick={()=>openAction("accept",current)}>Chấp thuận báo giá</Button><Button variant="outline" onClick={()=>openAction("reject",current)}>Từ chối báo giá</Button></>}
          <Button variant="outline" disabled={historyLoading} onClick={()=>void showHistory()}>{historyLoading?"Đang tải…":"Lịch sử thay đổi"}</Button>
        </div>}
        {history&&<div className="space-y-2"><h3 className="font-semibold">Các nội dung đã lưu</h3>{history.map(h=><button type="button" key={h.id} className="block w-full rounded border border-border p-3 text-left" onClick={()=>setSnapshot(h.snapshot)}>
          Lần {h.snapshot.revision} · {quoteLabels[h.snapshot.status]??h.snapshot.status} · {when(h.at)}<span className="block text-sm text-muted-foreground">{h.reason??"Xem nội dung chi tiết"}</span>
        </button>)}</div>}
      </Card>}
    </div>}
    <Modal open={editor} onClose={()=>{if(!busy)setEditor(false);}} title={editing?`Sửa bản nháp BG${editing.id}`:"Tạo báo giá từ phiếu sửa chữa"} width="max-w-3xl">
      <form onSubmit={save} className="space-y-4">
        {!editing&&<Select label="Phiếu sửa chữa" required value={orderId} onChange={e=>setOrderId(e.target.value)} options={[{value:"",label:"Chọn phiếu"},...orders.filter(o=>!items.some(q=>q.repairOrderId===o.id)).map(o=>({value:String(o.id),label:`PSC${o.id} · ${o.licensePlate} · ${o.customerName}`}))]}/>}
        {catalogLoading?<p role="status">Đang tải hạng mục…</p>:<fieldset disabled={busy} className="space-y-4">
          {rows.map((row,index)=>{const catalog=row.kind==="SERVICE"?services:parts;return <div key={index} className="space-y-3 rounded-lg border border-border p-3">
            <div className="grid gap-3 sm:grid-cols-2"><Select label={`Loại hạng mục ${index+1}`} value={row.kind} onChange={e=>updateRow(index,{kind:e.target.value as QuoteKind,itemId:"",price:""})} options={[{value:"SERVICE",label:"Dịch vụ"},{value:"PART",label:"Phụ tùng dự kiến"}]}/>
              <Select label={`Hạng mục ${index+1}`} required value={row.itemId} onChange={e=>{const item=catalog.find(c=>String(c.id)===e.target.value);updateRow(index,{itemId:e.target.value,price:item?String(item.unitPrice):""});}} options={[{value:"",label:"Chọn hạng mục"},...catalog.map(c=>({value:String(c.id),label:c.name}))]}/></div>
            <div className="grid gap-3 sm:grid-cols-2"><Input label={`Số lượng ${index+1}`} required type="number" min="1" max="100000" step="1" value={row.quantity} onChange={e=>updateRow(index,{quantity:e.target.value})}/>
              <Input label={`Đơn giá ${index+1}`} type="number" min="0" step="1000" value={row.price} onChange={e=>updateRow(index,{price:e.target.value})} helperText="Giá tròn nghìn đồng. Để trống để lấy giá danh mục."/></div>
            <Button type="button" variant="outline" disabled={rows.length===1} onClick={()=>setRows(old=>old.filter((_,i)=>i!==index))}>Bỏ hạng mục {index+1}</Button>
          </div>;})}
          <Button type="button" variant="outline" disabled={rows.length>=100} onClick={()=>setRows(old=>[...old,emptyRow()])}>Thêm hạng mục</Button>
        </fieldset>}
        <p className="text-sm text-muted-foreground">Hệ thống tính lại tổng tiền khi lưu. Phụ tùng dự kiến chưa làm giảm tồn kho.</p>
        {formError&&<p role="alert" className="text-danger">{formError}</p>}
        <Button type="submit" disabled={busy||catalogLoading||!orderId}>{busy?"Đang lưu…":"Lưu bản nháp"}</Button>
      </form>
    </Modal>
    <Modal open={!!action} onClose={()=>{if(!busy)setAction(null);}} title={action?actionLabel[action.name]:"Báo giá"}>
      {action&&<form onSubmit={execute} className="space-y-4"><p>BG{action.quote.id} · {action.quote.plate} · Lần {action.quote.revision}</p><p className="font-bold">Tổng tiền: {money(action.quote.total)}</p>
        {action.name==="revise"&&<p>Nội dung cũ được giữ trong lịch sử. Gara cần gửi lại và nhận xác nhận của khách trước khi thực hiện hạng mục.</p>}
        <Textarea label={action.name==="revise"?"Lý do điều chỉnh":"Ghi chú"} required={action.name==="revise"} maxLength={500} value={reason} onChange={e=>setReason(e.target.value)}/>
        {formError&&<p role="alert" className="text-danger">{formError}</p>}<Button type="submit" disabled={busy}>{busy?"Đang lưu…":"Xác nhận thao tác"}</Button>
      </form>}
    </Modal>
  </div>;
}
