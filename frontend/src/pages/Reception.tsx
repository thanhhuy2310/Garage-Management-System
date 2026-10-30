import React, {useCallback,useEffect,useState} from "react";
import {Card,Button,Input,Select,Textarea,Modal} from "../components/ui";
import {customersApi,type Customer,type CustomerPayload} from "../api/customers";
import {vehiclesApi,toVehiclePayload,type Vehicle} from "../api/vehicles";
import {appointmentsApi,type Appointment} from "../api/appointments";
import {receptionsApi,type Reception,type ReceptionInput} from "../api/receptions";
import {garageApi} from "../api/garage";
import {errorMessage} from "../api/client";
import type {GarageService} from "../types/garage";
import {formatGarageDate} from "../utils/garageFormat";
import VehicleForm from "../features/vehicles/VehicleForm";
const STEPS=["Thông tin khách","Thông tin xe","Lịch hẹn","Tình trạng xe","Phiếu tiếp nhận"];
const empty:ReceptionInput={customerId:0,vehicleId:0,appointmentId:null,mileage:null,initialCondition:"",customerRequest:"",notes:""};
const emptyCustomer:CustomerPayload={fullName:"",phone:"",email:"",address:""};
export default function ReceptionPage(){
  const [step,setStep]=useState(0),[input,setInput]=useState<ReceptionInput>(empty);
  const [customers,setCustomers]=useState<Customer[]>([]),[vehicles,setVehicles]=useState<Vehicle[]>([]);
  const [appointments,setAppointments]=useState<Appointment[]>([]),[records,setRecords]=useState<Reception[]>([]);
  const [services,setServices]=useState<GarageService[]>([]),[serviceIds,setServiceIds]=useState<number[]>([]);
  const [selected,setSelected]=useState<Reception|null>(null),[editing,setEditing]=useState(false),[repairForm,setRepairForm]=useState(false);
  const [loading,setLoading]=useState(true),[vehicleLoading,setVehicleLoading]=useState(false),[busy,setBusy]=useState(false);
  const [error,setError]=useState(""),[notice,setNotice]=useState(""),[search,setSearch]=useState("");
  const [addCustomer,setAddCustomer]=useState(false),[addVehicle,setAddVehicle]=useState(false),[customerForm,setCustomerForm]=useState(emptyCustomer);
  const load=useCallback(async()=>{
    setLoading(true);setError("");
    try{const [c,a,r,s]=await Promise.all([customersApi.list(),appointmentsApi.list(),receptionsApi.list(),garageApi.services()]);setCustomers(c);setAppointments(a);setRecords(r);setServices(s);}
    catch(e){setError(errorMessage(e));}finally{setLoading(false);}
  },[]);
  useEffect(()=>{void load();},[load]);
  useEffect(()=>{
    if(!input.customerId){setVehicles([]);return;}
    let active=true;setVehicleLoading(true);
    vehiclesApi.listByCustomer(input.customerId).then(v=>{if(active)setVehicles(v);}).catch(e=>{if(active)setError(errorMessage(e));}).finally(()=>{if(active)setVehicleLoading(false);});
    return()=>{active=false;};
  },[input.customerId]);
  const customer=customers.find(c=>c.id===input.customerId),vehicle=vehicles.find(v=>v.id===input.vehicleId);
  function update<K extends keyof ReceptionInput>(key:K,value:ReceptionInput[K]){setInput(old=>({...old,[key]:value}));}
  function next(){
    setError("");
    if(step===0&&!input.customerId){setError("Vui lòng chọn khách hàng.");return;}
    if(step===1&&(!vehicle||vehicleLoading)){setError("Vui lòng chọn xe của khách hàng.");return;}
    if(step===1&&input.mileage!==null&&(!Number.isInteger(input.mileage)||input.mileage<0)){setError("Số km phải là số nguyên không âm.");return;}
    if(step===2&&!input.customerRequest.trim()){setError("Vui lòng nhập yêu cầu của khách hàng.");return;}
    if(step===3&&!input.initialCondition.trim()){setError("Vui lòng ghi tình trạng ban đầu của xe.");return;}
    setStep(step+1);
  }
  async function save(){
    if(busy)return;setBusy(true);setError("");
    try{const result=editing&&selected?await receptionsApi.update(selected,input):await receptionsApi.create(input);
      const saved=await receptionsApi.get(result.id);setSelected(saved);setEditing(false);await load();setNotice("Đã lưu phiếu tiếp nhận.");
    }catch(e){setError(errorMessage(e));}finally{setBusy(false);}
  }
  async function open(id:number){setError("");try{setSelected(await receptionsApi.get(id));setEditing(false);}catch(e){setError(errorMessage(e));}}
  async function createCustomer(event:React.FormEvent){event.preventDefault();if(busy)return;setBusy(true);setError("");
    try{const c=await customersApi.create(customerForm);setCustomers(old=>[c,...old]);setInput({...empty,customerId:c.id});setAddCustomer(false);setCustomerForm(emptyCustomer);}
    catch(e){setError(errorMessage(e));}finally{setBusy(false);}}
  async function createRepair(){if(!selected||busy)return;setBusy(true);setError("");
    try{await garageApi.createRepair({receptionId:selected.id,services:serviceIds.map(serviceId=>({serviceId,quantity:1}))});setSelected(await receptionsApi.get(selected.id));setRepairForm(false);await load();setNotice("Đã lập phiếu sửa chữa từ phiếu tiếp nhận.");}
    catch(e){setError(errorMessage(e));}finally{setBusy(false);}}
  if(loading&&!records.length&&!customers.length)return <p role="status">Đang tải dữ liệu tiếp nhận…</p>;
  return <div className="mx-auto max-w-5xl space-y-6">
    {error&&<p role="alert" className="rounded-lg bg-danger-soft p-3 text-danger">{error}</p>}
    {notice&&<p role="status" className="rounded-lg bg-success-soft p-3">{notice}</p>}
    {selected&&!editing?<Card className="space-y-4 p-5">
      <h2 className="text-xl font-bold">Phiếu tiếp nhận TN{selected.id}</h2>
      <p>{selected.customerName} · {selected.licensePlate}</p>
      <p>Lịch hẹn: {selected.appointmentId?`LH${selected.appointmentId}`:"Xe đến trực tiếp"} · {formatGarageDate(selected.receivedAt)}</p>
      <p>Số km tiếp nhận: {selected.mileage?.toLocaleString("vi-VN")??"Chưa ghi nhận"}</p>
      <p>Tình trạng: {selected.initialCondition}</p><p>Yêu cầu: {selected.customerRequest}</p><p>Ghi chú: {selected.notes||"Không có"}</p>
      <p>{selected.repairOrderId?`Đã lập phiếu sửa chữa PSC${selected.repairOrderId}`:"Chưa lập phiếu sửa chữa"}</p>
      <div className="flex flex-wrap gap-3">
        {!selected.repairOrderId&&<><Button disabled={busy} onClick={()=>{setInput({customerId:selected.customerId,vehicleId:selected.vehicleId,appointmentId:selected.appointmentId,mileage:selected.mileage,initialCondition:selected.initialCondition??"",customerRequest:selected.customerRequest??"",notes:selected.notes??""});setEditing(true);setStep(1);setNotice("");}}>Cập nhật tiếp nhận</Button>
          <Button disabled={busy} onClick={()=>{setServiceIds([]);setRepairForm(true);}}>Lập phiếu sửa chữa</Button></>}
        {selected.repairOrderId&&<a className="font-semibold text-primary underline" href="/admin/repair">Mở quản lý sửa chữa</a>}
        <Button variant="outline" onClick={()=>{setSelected(null);setInput(empty);setStep(0);setNotice("");}}>Tiếp nhận xe khác</Button>
      </div>
    </Card>:<>
      <div className="flex gap-2 overflow-x-auto pb-2">{STEPS.map((label,index)=><div key={label} className={`flex items-center gap-2 whitespace-nowrap ${index===step?"font-bold text-primary":"text-muted-foreground"}`}><span className="rounded-full border px-3 py-1">{index+1}</span>{label}</div>)}</div>
      <div className="grid gap-6 xl:grid-cols-3"><Card className="space-y-4 p-5 xl:col-span-2">
        <h3 className="font-semibold">{STEPS[step]}</h3>
        {step===0&&<><Select label="Khách hàng" required value={String(input.customerId||"")} onChange={e=>setInput({...empty,customerId:Number(e.target.value)})} options={[{value:"",label:"Chọn khách hàng"},...customers.filter(c=>c.active).map(c=>({value:String(c.id),label:`${c.fullName} – ${c.phone}`}))]}/><Button variant="outline" onClick={()=>setAddCustomer(true)}>Thêm khách hàng mới</Button></>}
        {step===1&&<>{vehicleLoading?<p role="status">Đang tải xe…</p>:<Select label="Chọn xe" disabled={editing} value={String(input.vehicleId||"")} onChange={e=>{const v=vehicles.find(v=>v.id===Number(e.target.value));setInput(old=>({...old,vehicleId:v?.id??0,mileage:v?.mileage??null,appointmentId:null}));}} options={[{value:"",label:"Chọn xe của khách hàng"},...vehicles.map(v=>({value:String(v.id),label:`${v.licensePlate} – ${v.brand??""} ${v.model??""}`}))]}/>}
          <Input label="Số km hiện tại" type="number" min="0" step="1" value={input.mileage??""} onChange={e=>update("mileage",e.target.value===""?null:Number(e.target.value))}/>
          {!editing&&<Button variant="outline" disabled={!input.customerId} onClick={()=>setAddVehicle(true)}>Thêm xe cho khách</Button>}</>}
        {step===2&&<><Select label="Lịch hẹn liên quan" disabled={editing} value={input.appointmentId??""} onChange={e=>{const id=e.target.value?Number(e.target.value):null;const a=appointments.find(a=>a.id===id);setInput(old=>({...old,appointmentId:id,customerRequest:a?.note||old.customerRequest}));}} options={[{value:"",label:"Xe đến trực tiếp"},...appointments.filter(a=>a.vehicleId===input.vehicleId&&(a.status==="DA_XAC_NHAN"||a.id===input.appointmentId)).map(a=>({value:String(a.id),label:`LH${a.id} · ${a.date} ${a.time.slice(0,5)}`}))]}/><Textarea label="Yêu cầu của khách hàng" required maxLength={1000} value={input.customerRequest} onChange={e=>update("customerRequest",e.target.value)}/></>}
        {step===3&&<><Textarea label="Tình trạng xe ban đầu" required maxLength={1000} value={input.initialCondition} onChange={e=>update("initialCondition",e.target.value)} placeholder="Ngoại thất, phụ kiện kèm theo, dấu hiệu bất thường…"/><Textarea label="Ghi chú" maxLength={1000} value={input.notes} onChange={e=>update("notes",e.target.value)}/></>}
        {step===4&&<><p>{customer?.fullName} · {vehicle?.licensePlate}</p><p>Tình trạng: {input.initialCondition}</p><p>Yêu cầu: {input.customerRequest}</p><p>{input.appointmentId?`Liên kết lịch LH${input.appointmentId}`:"Xe đến trực tiếp"}</p></>}
        <div className="flex justify-between"><Button variant="outline" disabled={busy||step===(editing?1:0)} onClick={()=>setStep(step-1)}>Quay lại</Button>{step<4?<Button disabled={busy||vehicleLoading} onClick={next}>Tiếp theo</Button>:<Button disabled={busy} onClick={()=>void save()}>{busy?"Đang lưu…":editing?"Lưu cập nhật":"Lập phiếu tiếp nhận"}</Button>}</div>
      </Card><Card className="h-fit space-y-3 p-5"><h3 className="font-semibold">Tóm tắt</h3><p>{customer?.fullName??"Chưa chọn khách"}</p><p>{vehicle?.licensePlate??"Chưa chọn xe"}</p><p>{input.mileage?.toLocaleString("vi-VN")??"—"} km</p><p>{input.customerRequest||"Chưa nhập yêu cầu"}</p></Card></div>
    </>}
    <Card className="space-y-3 p-5"><div className="flex flex-wrap items-end gap-3"><Input label="Tìm phiếu tiếp nhận" value={search} onChange={e=>setSearch(e.target.value)} placeholder="Mã phiếu, biển số hoặc tên khách"/><Button variant="outline" disabled={loading} onClick={()=>void load()}>Tải lại danh sách</Button></div>
      {!records.length&&<p>Chưa có phiếu tiếp nhận.</p>}{records.filter(r=>`${r.id} ${r.licensePlate} ${r.customerName}`.toLocaleLowerCase("vi").includes(search.toLocaleLowerCase("vi"))).map(r=><button type="button" key={r.id} onClick={()=>void open(r.id)} className="block w-full rounded border border-border p-3 text-left">TN{r.id} · {r.licensePlate} · {r.customerName}<span className="block text-sm text-muted-foreground">{formatGarageDate(r.receivedAt)} · {r.repairOrderId?`PSC${r.repairOrderId}`:"Chưa lập phiếu sửa chữa"}</span></button>)}
    </Card>
    <Modal open={addCustomer} onClose={()=>{if(!busy)setAddCustomer(false);}} title="Thêm khách hàng mới"><form onSubmit={createCustomer} className="space-y-3"><Input label="Họ tên" required maxLength={150} value={customerForm.fullName} onChange={e=>setCustomerForm({...customerForm,fullName:e.target.value})}/><Input label="Số điện thoại" required value={customerForm.phone} onChange={e=>setCustomerForm({...customerForm,phone:e.target.value})}/><Input label="Email" type="email" value={customerForm.email} onChange={e=>setCustomerForm({...customerForm,email:e.target.value})}/><Input label="Địa chỉ" value={customerForm.address} onChange={e=>setCustomerForm({...customerForm,address:e.target.value})}/>{error&&<p role="alert">{error}</p>}<Button type="submit" disabled={busy}>Lưu khách hàng</Button></form></Modal>
    <Modal open={addVehicle} onClose={()=>setAddVehicle(false)} title="Thêm xe cho khách">{addVehicle&&<VehicleForm initialValue={{customerId:input.customerId,plate:"",brand:"",model:"",year:null,mileage:null}} onCancel={()=>setAddVehicle(false)} onSubmit={async value=>{const v=await vehiclesApi.create(toVehiclePayload(input.customerId,value));setVehicles(old=>[v,...old]);setInput(old=>({...old,vehicleId:v.id,mileage:v.mileage,appointmentId:null}));setAddVehicle(false);}}/>}</Modal>
    <Modal open={repairForm} onClose={()=>{if(!busy)setRepairForm(false);}} title="Lập phiếu sửa chữa"><div className="space-y-4"><p>Chọn dịch vụ cần kiểm tra/sửa chữa cho TN{selected?.id}.</p>{services.map(s=><label key={s.id} className="flex gap-2"><input type="checkbox" checked={serviceIds.includes(s.id)} onChange={e=>setServiceIds(old=>e.target.checked?[...old,s.id]:old.filter(id=>id!==s.id))}/>{s.name}</label>)}{error&&<p role="alert">{error}</p>}<Button disabled={busy||!serviceIds.length} onClick={()=>void createRepair()}>Tạo phiếu sửa chữa</Button></div></Modal>
  </div>;
}
