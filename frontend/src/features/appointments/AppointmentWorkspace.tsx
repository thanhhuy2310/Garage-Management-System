import { useCallback, useEffect, useState } from "react";
import { appointmentsApi, appointmentLabels, type Appointment, type Availability, type ScheduleSlot } from "../../api/appointments";
import { customersApi, type Customer } from "../../api/customers";
import { vehiclesApi, type Vehicle } from "../../api/vehicles";
import { garageApi } from "../../api/garage";
import { errorMessage } from "../../api/client";
import { readSession } from "../../api/session";
import type { GarageService } from "../../types/garage";
import { Button, Card, Input, Modal, Select, Textarea } from "../../components/ui";

const mutable = (a: Appointment) => ["CHO_XAC_NHAN", "DA_XAC_NHAN"].includes(a.status);
const weekdays = ["Thứ hai","Thứ ba","Thứ tư","Thứ năm","Thứ sáu","Thứ bảy","Chủ nhật"];
const today = () => new Intl.DateTimeFormat("en-CA",{timeZone:"Asia/Ho_Chi_Minh"}).format(new Date());
type Action = "create"|"move"|"cancel"|"confirm";

export default function AppointmentWorkspace({customerId,onBooked}: {customerId?: number; onBooked?: () => void}) {
  const customer = customerId !== undefined;
  const role = readSession()?.account.role;
  const [items,setItems] = useState<Appointment[]>([]);
  const [loading,setLoading] = useState(true);
  const [error,setError] = useState("");
  const [notice,setNotice] = useState("");
  const [search,setSearch] = useState("");
  const [status,setStatus] = useState("");
  const [busy,setBusy] = useState(false);
  const [action,setAction] = useState<Action|null>(null);
  const [selected,setSelected] = useState<Appointment|null>(null);
  const [customers,setCustomers] = useState<Customer[]>([]);
  const [owner,setOwner] = useState(customerId ?? 0);
  const [vehicles,setVehicles] = useState<Vehicle[]>([]);
  const [services,setServices] = useState<GarageService[]>([]);
  const [vehicle,setVehicle] = useState("");
  const [service,setService] = useState("");
  const [date,setDate] = useState("");
  const [time,setTime] = useState("");
  const [note,setNote] = useState("");
  const [formError,setFormError] = useState("");
  const [availability,setAvailability] = useState<Availability|null>(null);
  const [slotsLoading,setSlotsLoading] = useState(false);
  const [scheduleOpen,setScheduleOpen] = useState(false);
  const [schedule,setSchedule] = useState<ScheduleSlot[]>([]);
  const [day,setDay] = useState("1");
  const [scheduleTime,setScheduleTime] = useState("");
  const [capacity,setCapacity] = useState("");
  const needsTime = action==="create" || action==="move";

  const load = useCallback(async () => {
    setLoading(true); setError("");
    try { setItems(await appointmentsApi.list()); }
    catch(e) { setError(errorMessage(e)); }
    finally { setLoading(false); }
  },[]);
  useEffect(() => { void load(); },[load]);
  useEffect(() => {
    if(action!=="create") return;
    let active=true; setVehicles([]); setVehicle("");
    if(owner) vehiclesApi.listByCustomer(owner).then(v=>{if(active)setVehicles(v);})
      .catch(e=>{if(active)setFormError(errorMessage(e));});
    return ()=>{active=false;};
  },[owner,action]);
  useEffect(() => {
    setAvailability(null); setTime("");
    if(!date || !needsTime) return;
    const controller=new AbortController(); setSlotsLoading(true);
    appointmentsApi.availability(date,controller.signal).then(setAvailability)
      .catch(e=>{if(!controller.signal.aborted)setFormError(errorMessage(e));})
      .finally(()=>{if(!controller.signal.aborted)setSlotsLoading(false);});
    return ()=>controller.abort();
  },[date,needsTime]);
  async function open(next: Action,item: Appointment|null=null) {
    setNotice(""); setFormError(""); setSelected(item); setAction(next);
    setOwner(customerId??0); setVehicle(""); setService(""); setDate(""); setTime(""); setNote("");
    if(next!=="create")return;
    try {
      const [catalog,people]=await Promise.all([garageApi.services(),customer?Promise.resolve([]):customersApi.list()]);
      setServices(catalog); setCustomers(people.filter(c=>c.active));
    } catch(e) {setFormError(errorMessage(e));}
  }
  async function save(e: React.FormEvent) {
    e.preventDefault(); if(busy)return; setBusy(true); setFormError("");
    try {
      if(action==="create") await appointmentsApi.create({vehicleId:Number(vehicle),serviceId:service?Number(service):null,date,time,note});
      else if(action==="move" && selected) await appointmentsApi.move(selected,date,time,note);
      else if(selected && (action==="cancel" || action==="confirm")) await appointmentsApi.change(selected,action,note);
      setAction(null); setNotice("Đã lưu lịch hẹn. Trạng thái được tải lại từ hệ thống.");
      await load(); onBooked?.();
    } catch(e) {
      setFormError(errorMessage(e));
      if(needsTime && date) {
        try {setAvailability(await appointmentsApi.availability(date));setTime("");}
        catch { /* Preserve the mutation error. */ }
      }
    } finally {setBusy(false);}
  }
  async function openSchedule() {
    setFormError("");setScheduleOpen(true);
    try {setSchedule(await appointmentsApi.schedule());}catch(e){setFormError(errorMessage(e));}
  }
  async function saveSchedule(e: React.FormEvent) {
    e.preventDefault();if(busy)return;setBusy(true);setFormError("");
    try {setSchedule(await appointmentsApi.configure({dayOfWeek:Number(day),time:scheduleTime,capacity:Number(capacity)}));}
    catch(e){setFormError(errorMessage(e));}finally{setBusy(false);}
  }
  const filtered=items.filter(a=>(!status||a.status===status) &&
    (a.plate+" "+a.customerName+" "+a.id).toLocaleLowerCase("vi").includes(search.toLocaleLowerCase("vi")));
  const titles={create:"Đặt lịch mới",move:"Dời lịch hẹn",cancel:"Hủy lịch hẹn",confirm:"Xác nhận lịch hẹn"};
  return <div className="space-y-5">
    <div className="flex flex-wrap items-end gap-3">
      <Input label="Tìm lịch hẹn" placeholder="Biển số, khách hàng hoặc mã lịch" value={search} onChange={e=>setSearch(e.target.value)}/>
      <Select label="Trạng thái" value={status} onChange={e=>setStatus(e.target.value)} options={[{value:"",label:"Tất cả"},...Object.entries(appointmentLabels).map(([value,label])=>({value,label}))]}/>
      <Button onClick={()=>void open("create")}>Đặt lịch mới</Button>
      <Button variant="outline" onClick={()=>void load()} disabled={loading}>Tải lại</Button>
      {!customer && role==="MANAGER" && <Button variant="secondary" onClick={()=>void openSchedule()}>Cấu hình khung giờ</Button>}
    </div>
    {notice && <p role="status" className="rounded-md bg-success-soft p-3 text-success">{notice}</p>}
    {error && <p role="alert" className="text-danger">{error}</p>}
    {loading ? <p role="status">Đang tải lịch hẹn…</p> : !error && <Card>
      <div className="hidden overflow-x-auto md:block"><table className="w-full text-left text-sm">
        <thead><tr className="border-b border-border"><th className="p-3">Lịch hẹn</th><th className="p-3">Xe / khách hàng</th><th className="p-3">Dịch vụ</th><th className="p-3">Trạng thái</th><th className="p-3">Thao tác</th></tr></thead>
        <tbody>{filtered.map(item=><tr key={item.id} className="border-b border-border">
          <td className="p-3">LH{item.id}<br/>{item.date.split("-").reverse().join("/")} · {item.time.slice(0,5)}</td>
          <td className="p-3">{item.plate}<br/>{item.customerName}</td>
          <td className="p-3">{item.serviceName??"Tư vấn chung"}{item.note && <p className="mt-1 max-w-xs whitespace-pre-wrap text-muted-foreground">{item.note}</p>}</td>
          <td className="p-3">{appointmentLabels[item.status]??item.status}</td>
          <td className="p-3"><div className="flex flex-wrap gap-2">{mutable(item) && <>
            {!customer && item.status==="CHO_XAC_NHAN" && <Button size="sm" onClick={()=>void open("confirm",item)}>Xác nhận</Button>}
            <Button size="sm" variant="outline" onClick={()=>void open("move",item)}>Dời lịch</Button>
            <Button size="sm" variant="ghost" onClick={()=>void open("cancel",item)}>Hủy lịch</Button>
          </>}</div></td>
        </tr>)}</tbody>
      </table></div>
      <div className="space-y-3 p-3 md:hidden">{filtered.map(item=><article key={item.id} className="space-y-3 rounded-lg border border-border p-4">
        <div className="flex flex-wrap justify-between gap-2"><h3 className="font-semibold">LH{item.id} · {item.plate}</h3><span className="text-sm">{appointmentLabels[item.status]??item.status}</span></div>
        <p className="text-sm">{item.date.split("-").reverse().join("/")} · {item.time.slice(0,5)}</p>
        {!customer && <p className="text-sm">{item.customerName}</p>}
        <p className="text-sm font-medium">{item.serviceName??"Tư vấn chung"}</p>
        {item.note && <p className="whitespace-pre-wrap text-sm text-muted-foreground">{item.note}</p>}
        {mutable(item) && <div className="flex flex-wrap gap-2">
          {!customer && item.status==="CHO_XAC_NHAN" && <Button size="sm" onClick={()=>void open("confirm",item)}>Xác nhận</Button>}
          <Button size="sm" variant="outline" onClick={()=>void open("move",item)}>Dời lịch</Button>
          <Button size="sm" variant="ghost" onClick={()=>void open("cancel",item)}>Hủy lịch</Button>
        </div>}
      </article>)}</div>
      {!filtered.length && <p className="p-6 text-muted-foreground">Chưa có lịch hẹn phù hợp.</p>}
    </Card>}
    <Modal open={action!==null} onClose={()=>{if(!busy)setAction(null);}} title={action?titles[action]:"Lịch hẹn"}>
      <form className="space-y-4" onSubmit={save}>
        {selected && <p>LH{selected.id} · {selected.plate} · {selected.date} {selected.time.slice(0,5)}</p>}
        {action==="create" && <>
          {!customer && <Select required label="Khách hàng" value={owner||""} onChange={e=>setOwner(Number(e.target.value))} options={[{value:"",label:"Chọn khách hàng"},...customers.map(c=>({value:String(c.id),label:c.fullName+" · "+c.phone}))]}/>}
          <Select required label="Xe" value={vehicle} onChange={e=>setVehicle(e.target.value)} options={[{value:"",label:"Chọn xe"},...vehicles.map(v=>({value:String(v.id),label:v.licensePlate+" · "+(v.model??"")}))]}/>
          {owner>0 && !vehicles.length && <p className="text-sm text-muted-foreground">Nếu chưa có xe, hãy thêm xe ở mục Quản lý xe rồi mở lại đặt lịch.</p>}
          <Select label="Dịch vụ" value={service} onChange={e=>setService(e.target.value)} options={[{value:"",label:"Tư vấn chung"},...services.map(s=>({value:String(s.id),label:s.name}))]}/>
        </>}
        {needsTime && <>
          {action==="move" && <p>Lịch mới cần được gara xác nhận lại.</p>}
          <Input required label="Ngày hẹn" type="date" min={today()} value={date} onChange={e=>{setDate(e.target.value);setFormError("");}}/>
          {slotsLoading ? <p role="status">Đang kiểm tra khung giờ…</p> : availability && <>
            <Select required label="Giờ hẹn (giờ Việt Nam)" value={time} onChange={e=>setTime(e.target.value)} options={[{value:"",label:"Chọn giờ còn trống"},...availability.slots.filter(s=>s.remaining>0).map(s=>({value:s.time,label:s.time.slice(0,5)+" · còn "+s.remaining+" chỗ"}))]}/>
            {!availability.slots.some(s=>s.remaining>0) && <p role="status">{availability.configured?"Ngày này không còn khung giờ có thể đặt.":"Gara chưa mở khung giờ cho ngày này."}</p>}
          </>}
        </>}
        <Textarea label={action==="create"?"Yêu cầu của bạn":"Ghi chú / lý do"} maxLength={500} value={note} onChange={e=>setNote(e.target.value)}/>
        {formError && <p role="alert" className="text-danger">{formError}</p>}
        <div className="flex gap-2"><Button type="submit" disabled={busy||(needsTime&&(slotsLoading||!time))}>{busy?"Đang lưu…":action==="cancel"?"Xác nhận hủy":"Lưu lịch hẹn"}</Button><Button type="button" variant="outline" disabled={busy} onClick={()=>setAction(null)}>Đóng</Button></div>
      </form>
    </Modal>
    <Modal open={scheduleOpen} onClose={()=>{if(!busy)setScheduleOpen(false);}} title="Cấu hình khung giờ tiếp nhận">
      <form onSubmit={saveSchedule} className="space-y-4">
        <p className="text-sm text-muted-foreground">Nhập sức chứa thực tế cho từng giờ, lặp lại hàng tuần. Đặt 0 để ngừng nhận lịch mới; lịch đã đặt vẫn được giữ.</p>
        <Select label="Ngày trong tuần" value={day} onChange={e=>setDay(e.target.value)} options={weekdays.map((label,i)=>({value:String(i+1),label}))}/>
        <Input required label="Giờ bắt đầu" type="time" value={scheduleTime} onChange={e=>setScheduleTime(e.target.value)}/>
        <Input required label="Số xe có thể tiếp nhận" type="number" min="0" step="1" value={capacity} onChange={e=>setCapacity(e.target.value)}/>
        {formError && <p role="alert" className="text-danger">{formError}</p>}
        <Button type="submit" disabled={busy}>{busy?"Đang lưu…":"Lưu khung giờ"}</Button>
        <ul className="space-y-2">{schedule.map(s=><li key={s.dayOfWeek+s.time}><button type="button" className="min-h-11 text-left underline" onClick={()=>{setDay(String(s.dayOfWeek));setScheduleTime(s.time.slice(0,5));setCapacity(String(s.capacity));}}>{weekdays[s.dayOfWeek-1]} · {s.time.slice(0,5)} · {s.capacity} xe</button></li>)}</ul>
      </form>
    </Modal>
  </div>;
}
