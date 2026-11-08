import {InsuranceForm,statusName,val} from "../features/insurance/forms";
import {useCallback,useState} from "react";
import {Card,Input,Select} from "../components/ui";
import {QueryState} from "../components/garage/QueryState";
import {useGarageQuery} from "../hooks/useGarageQuery";
import {vehiclesApi,type Vehicle} from "../api/vehicles";
import {receptionsApi} from "../api/receptions";
import {insuranceApi,type Company,type Policy} from "../api/insurance";
import ClaimForm from "../features/insurance/ClaimForm";
import {formatMoney} from "../utils/garageFormat";
import InsuranceCase from "../features/insurance/InsuranceCase";

const optional=(f:FormData,key:string)=>val(f,key)||null;
const price=(f:FormData,key:string)=>val(f,key)===""?null:Number(val(f,key));
function CompanyForm({company,done}:{company?:Company;done:()=>void}){
  return <InsuranceForm title={company?"Cập nhật "+company.name:"Thêm công ty bảo hiểm"} done={done} save={f=>insuranceApi.save(company?"companies/"+company.id:"companies",{
    code:val(f,"code"),name:val(f,"name"),phone:optional(f,"phone"),email:optional(f,"email"),address:optional(f,"address"),
    assessorName:optional(f,"assessorName"),assessorContact:optional(f,"assessorContact"),active:f.get("active")==="on"},company?"put":"post")}>
    <Input name="code" label="Mã công ty" required maxLength={30} defaultValue={company?.code}/>
    <Input name="name" label="Tên công ty" required maxLength={200} defaultValue={company?.name}/>
    {(["phone","email","address","assessorName","assessorContact"] as const).map((k,i)=><Input key={k} name={k} label={["Điện thoại","Email","Địa chỉ","Đầu mối giám định","Liên hệ giám định"][i]} defaultValue={company?.[k]??""}/>)}
    <label><input type="checkbox" name="active" defaultChecked={company?.active??true}/> Đang hợp tác</label>
  </InsuranceForm>;
}

function VehicleInsurance({vehicle,companies}:{vehicle:Vehicle;companies:Company[]}){
  const [selected,setSelected]=useState(0),[notice,setNotice]=useState("");
  const load=useCallback(async()=>{const [policies,claims,all]=await Promise.all([insuranceApi.policies(vehicle.id),insuranceApi.claims(vehicle.id),receptionsApi.list()]);
    return {policies,claims,receptions:all.filter(r=>r.vehicleId===vehicle.id&&!claims.some(c=>c.receptionId===r.id))};
  },[vehicle.id]);
  const query=useGarageQuery(load);
  function saved(){setNotice("Đã lưu vào hồ sơ xe.");query.reload();}
  if(!query.data)return <QueryState {...query} onRetry={query.reload}/>;
  const {policies,claims,receptions}=query.data;
  return <div className="space-y-4">
    {notice&&<p role="status">{notice}</p>}
    <InsuranceForm title="Thêm hợp đồng vật chất xe" done={saved} save={f=>insuranceApi.save<Policy>("policies",{
      vehicleId:vehicle.id,policyholderCustomerId:vehicle.customerId,insuranceType:"VAT_CHAT_XE",companyId:Number(f.get("company")),
      policyNumber:val(f,"number"),startDate:val(f,"from"),endDate:val(f,"to"),registeredOwnerName:val(f,"registration"),
      certificateOwnerName:val(f,"certificate"),insuredAmount:price(f,"insured"),deductible:price(f,"deductible"),
      certificateReference:optional(f,"reference"),repairShopTerms:optional(f,"garage"),partsTerms:optional(f,"parts")})}>
      <Select name="company" label="Doanh nghiệp bảo hiểm" required options={companies.filter(c=>c.active).map(c=>({value:String(c.id),label:c.name}))}/>
      <Input name="number" label="Số hợp đồng" required/><Input name="registration" label="Tên chủ xe trên đăng ký" required/>
      <Input name="certificate" label="Tên trên giấy chứng nhận bảo hiểm" required/>
      <Input name="from" label="Hiệu lực từ" type="date" required/><Input name="to" label="Đến ngày" type="date" required/>
      <details><summary>Thông tin hợp đồng nâng cao (không bắt buộc)</summary>
      <Input name="insured" label="Số tiền bảo hiểm" type="number" min={0}/><Input name="deductible" label="Miễn thường theo hợp đồng" type="number" min={0}/>
      <Input name="reference" label="Tham chiếu chứng nhận"/><Input name="garage" label="Điều khoản chọn gara"/><Input name="parts" label="Điều khoản phụ tùng"/>
      </details>
    </InsuranceForm>
    {policies.map(p=><Card key={p.id} className="space-y-2 p-4"><b>{p.policyNumber} · {statusName(p.verificationStatus)}</b>
      <p>{companies.find(c=>c.id===p.companyId)?.name} · {p.startDate} – {p.endDate}</p><p>Chủ xe: {p.registeredOwnerName??"Chưa bổ sung"} · Chứng nhận: {p.certificateOwnerName??"Chưa bổ sung"}</p>
      <p>Miễn thường: {p.deductible===null?"Theo chứng nhận":formatMoney(p.deductible)} · {p.partsTerms}</p>
      {p.verificationStatus==="CHUA_XAC_MINH"&&<InsuranceForm title="Xác minh hợp đồng" done={saved} save={f=>insuranceApi.save(`policies/${p.id}/verification`,{status:val(f,"status"),note:val(f,"note"),registeredOwnerName:optional(f,"registration"),certificateOwnerName:optional(f,"certificate")})}>
        <Select name="status" label="Kết quả đối chiếu" options={[{value:"DA_XAC_MINH",label:"Đã xác minh"},{value:"KHONG_HOP_LE",label:"Không hợp lệ"}]}/>
        {!p.registeredOwnerName&&<Input name="registration" label="Tên trên đăng ký xe" required/>}
        {!p.certificateOwnerName&&<Input name="certificate" label="Tên trên giấy chứng nhận" required/>}
        <Input name="note" label="Căn cứ xác minh" required/></InsuranceForm>}</Card>)}
    {policies.length>0&&receptions.length>0&&<ClaimForm policies={policies} receptions={receptions} onCreated={setSelected} onSaved={saved}/>}
    {!receptions.length&&<p>Mở hồ sơ mới từ phiếu tiếp nhận của xe. <a href="/admin/reception">Xem tiếp nhận</a></p>}
    <h3 className="font-semibold">Hồ sơ tổn thất</h3>
    {claims.length===0?<p>Xe chưa có hồ sơ tổn thất.</p>:<Select label="Chọn hồ sơ" value={String(selected||claims[0].id)} onChange={e=>setSelected(Number(e.target.value))} options={claims.map(c=>({value:String(c.id),label:c.code+" · "+statusName(c.status)}))}/>}
    {claims.length>0&&<InsuranceCase key={selected||claims[0].id} id={selected||claims[0].id}/>}
  </div>;
}

export default function Insurance(){
  const company=useGarageQuery(insuranceApi.companies);
  const [editing,setEditing]=useState(0),[search,setSearch]=useState(""),[vehicle,setVehicle]=useState<Vehicle|null>(null);
  const searchVehicles=useCallback(()=>vehiclesApi.list({search,page:0,size:50}),[search]);
  const cars=useGarageQuery(searchVehicles);
  return <div className="space-y-5"><h2 className="ui-page-title">Bảo hiểm vật chất xe</h2>
    <QueryState {...company} onRetry={company.reload}/>
    <Card className="p-4 space-y-3"><CompanyForm done={company.reload}/>
      <Select label="Công ty cần cập nhật" value={String(editing)} onChange={e=>setEditing(Number(e.target.value))} options={[{value:"0",label:"Chọn công ty"},...(company.data??[]).map(c=>({value:String(c.id),label:c.name}))]}/>
      {company.data?.filter(c=>c.id===editing).map(c=><CompanyForm key={c.id} company={c} done={company.reload}/>)}</Card>
    <Card className="p-4 space-y-3"><Input label="Tìm xe theo biển số" value={search} onChange={e=>{setSearch(e.target.value);setVehicle(null);}}/>
      <QueryState {...cars} onRetry={cars.reload}/>
      <Select label="Xe làm hồ sơ" value={String(vehicle?.id??0)} onChange={e=>setVehicle(cars.data?.items.find(v=>v.id===Number(e.target.value))??null)} options={[{value:"0",label:"Chọn xe"},...(cars.data?.items??[]).map(v=>({value:String(v.id),label:v.licensePlate}))]}/></Card>
    {vehicle&&<VehicleInsurance key={vehicle.id} vehicle={vehicle} companies={company.data??[]}/>}
  </div>;
}
