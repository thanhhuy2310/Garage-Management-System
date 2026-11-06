import {useCallback,useState} from "react";
import {Card,Input,Select,Button} from "../../components/ui";
import {QueryState} from "../../components/garage/QueryState";
import {useGarageQuery} from "../../hooks/useGarageQuery";
import {insuranceApi,type Evidence} from "../../api/insurance";
import {quotationsApi} from "../../api/quotations";
import {billingApi} from "../../api/billing";
import {errorMessage} from "../../api/client";
import {formatMoney} from "../../utils/garageFormat";
import {InsuranceForm,statusName,val} from "./forms";

const steps:Record<string,string>={MOI_TAO:"DA_THONG_BAO",DA_THONG_BAO:"CHO_GIAM_DINH",CHO_GIAM_DINH:"DANG_XU_LY"};
const categories:Record<string,string>={GIAM_DINH:"Biên bản giám định",QUYET_DINH:"Văn bản quyết định chi trả",CHUYEN_TIEN:"Chứng từ đã chuyển tiền",KHAC:"Chứng từ khác"};
function DocumentChoice({docs,category}:{docs:Evidence[];category:string}){
  return <Select name="document" label={categories[category]} required options={[{value:"",label:"Chọn chứng từ đã lưu"},...docs.filter(d=>d.category===category).map(d=>({value:String(d.id),label:d.filename+" (#"+d.id+")"}))]}/>;
}
function Lines({rows}:{rows:{lineId:number;name:string;cap:number}[]}){
  return <>{rows.map(row=><Input key={row.lineId} name={"line"+row.lineId} label={row.name+" · tối đa "+formatMoney(row.cap)} type="number" step="0.01" min={0} max={row.cap} defaultValue={0} required/>)}</>;
}
export default function InsuranceCase({id}:{id:number}){
  const [notice,setNotice]=useState(""),[downloadError,setDownloadError]=useState("");
  const [requestId,setRequestId]=useState(()=>crypto.randomUUID());
  const load=useCallback(async()=>{
    const [claim,work]=await Promise.all([insuranceApi.claim(id),insuranceApi.casework(id)]);
    const quote=work.orderId?(await quotationsApi.list()).find(q=>q.repairOrderId===work.orderId):undefined;
    const invoice=work.invoiceId?await billingApi.invoice(work.invoiceId):null;
    return {claim,work,quote,invoice};
  },[id]);
  const query=useGarageQuery(load);
  if(!query.data)return <QueryState {...query} onRetry={query.reload}/>;
  const {claim,work,quote,invoice}=query.data;
  const base="claims/"+id,finance=base+"/finance",version=work.version;
  const current=work.proposals.find(p=>p.quoteId===quote?.id&&p.revision===quote.revision);
  const open=work.status!=="DA_DONG";
  const done=()=>{setNotice("Đã lưu thay đổi.");query.reload();};
  const amounts=(f:FormData,rows:{lineId:number}[])=>rows.map(r=>({lineId:r.lineId,amount:Number(f.get("line"+r.lineId))}));
  const lines=quote?.lines.map(l=>({lineId:l.id,name:l.name,cap:l.amount}))??[];
  const assessments=work.assessments.filter((a,i,all)=>all.findIndex(other=>other.item===a.item)===i);
  const balance=work.balance;
  const approved=current?.documentId?current.lines.reduce((sum,line)=>sum+(line.approved??0),0):0;
  const decisionLabel=current?.documentId?(approved>0?'Đã duyệt':'Từ chối'):'Chờ duyệt';
  return <Card className="space-y-4 p-4" key={version}><h3 className="font-semibold">{claim.code} · {statusName(work.status)}</h3>
    <h4 className="font-semibold">1. Kiểm tra bảo hiểm sửa chữa</h4>
    <p>{claim.incidentLocation} · {claim.damageDescription}</p><p>Phiếu tiếp nhận TN{claim.receptionId}{work.orderId&&" · Phiếu sửa chữa "+work.orderId}{work.invoiceId&&" · Hóa đơn "+work.invoiceId}</p>
    {notice&&<p role="status">{notice}</p>}
    <h4 className="font-semibold">2. Ghi nhận kết quả: {decisionLabel}</h4>
    {open&&quote&&!current&&["CHO_XAC_NHAN","DA_XAC_NHAN"].includes(quote.status)&&<InsuranceForm title="Ghi nhận mức bảo hiểm đã duyệt" done={done} save={f=>insuranceApi.save(finance+"/manual-decision",{
      allocation:{version,quoteId:quote.id,revision:quote.revision,direct:val(f,"payee")==="garage",lines:amounts(f,lines)},
      documentId:Number(f.get("document")),reference:val(f,"reference"),reason:val(f,"reason")})}>
      <p>Tổng báo giá {formatMoney(quote.total)}. Nhập mức đã duyệt cho từng hạng mục. Hạng mục khách tự trả để 0.</p>
      <p>Nhập số tiền cuối cùng sau miễn thường theo quyết định. Nếu từ chối toàn bộ, nhập 0 cho mọi hạng mục và ghi rõ lý do.</p>
      <DocumentChoice docs={work.documents} category="QUYET_DINH"/>
      <Select label="Bên nhận tiền bảo hiểm" name="payee" required options={[{value:"",label:"Chọn theo quyết định"},{value:"garage",label:"Gara nhận trực tiếp"},{value:"customer",label:"Hoàn tiền cho khách"}]}/>
      <Input name="reference" label="Số văn bản quyết định" required/><Input name="reason" label="Nội dung đã đối chiếu" required/>
      <Lines rows={lines}/>
    </InsuranceForm>}
    <details><summary>Theo dõi giám định riêng</summary>
    {open&&<InsuranceForm title="Cập nhật bước xử lý và giám định viên" done={done} save={f=>insuranceApi.save(base+"/follow-up",{version,status:val(f,"status"),assessor:val(f,"assessor"),contact:val(f,"contact"),note:val(f,"note")},"put")}>
      <Select name="status" label="Bước xử lý" options={[work.status,steps[work.status]].filter(Boolean).map(s=>({value:s,label:statusName(s)}))}/>
      <Input name="assessor" label="Giám định viên hoặc đầu mối" defaultValue={claim.assessorName??""} required/>
      <Input name="contact" label="Thông tin liên hệ" defaultValue={claim.assessorContact??""}/><Input name="note" label="Nội dung thay đổi" required/>
    </InsuranceForm>}
    </details>
    <h4 className="font-semibold">Chứng từ xác nhận</h4>
    {open&&<InsuranceForm title="Lưu chứng từ" done={done} save={f=>insuranceApi.upload(id,version,f)}>
      <Select name="category" label="Loại chứng từ" options={Object.entries(categories).map(([value,label])=>({value,label}))}/>
      <Input type="file" name="file" label="Tệp PDF, JPEG hoặc PNG (tối đa 1 MB)" accept=".pdf,.jpg,.jpeg,.png" required/>
    </InsuranceForm>}
    {work.documents.map(d=><p key={d.id}><button type="button" className="text-primary underline" onClick={()=>{setDownloadError("");insuranceApi.download(id,d).catch(e=>setDownloadError(errorMessage(e)));}}>{d.filename}</button> · {categories[d.category]}</p>)}
    {downloadError&&<p role="alert">{downloadError}</p>}
    <details><summary>Giám định và đề nghị chi trả nâng cao</summary>
    {open&&["DANG_XU_LY","CHO_GIAM_DINH"].includes(work.status)&&<InsuranceForm title="Ghi kết quả giám định" done={done} save={f=>insuranceApi.save(base+"/assessments",{version,item:val(f,"item")||null,documentId:Number(f.get("document")),damage:val(f,"damage"),finding:val(f,"finding")})}>
      <Select name="item" label="Hạng mục" options={[{value:"",label:"Hạng mục mới"},...assessments.map(a=>({value:a.item,label:"Điều chỉnh "+a.damage}))]}/>
      <DocumentChoice docs={work.documents} category="GIAM_DINH"/><Input name="damage" label="Hư hỏng" required/><Input name="finding" label="Kết luận giám định" required/>
    </InsuranceForm>}
    {work.assessments.map(a=><p key={a.id}>{a.damage} · lần {a.revision} · {a.finding} · chứng từ #{a.documentId}</p>)}
    <h4 className="font-semibold">Báo giá và quyết định chi trả</h4>
    <p>{quote?"Báo giá #"+quote.id+" · lần "+quote.revision+" · "+formatMoney(quote.total):"Chưa có báo giá cho hồ sơ."} <a className="text-primary underline" href="/admin/quotation">Mở báo giá sửa chữa</a></p>
    {open&&quote&&!current&&assessments.length>0&&["CHO_XAC_NHAN","DA_XAC_NHAN"].includes(quote.status)&&<InsuranceForm title="Lập đề nghị chi trả theo báo giá" done={done} save={f=>insuranceApi.save(finance+"/proposals",{version,quoteId:quote.id,revision:quote.revision,direct:val(f,"payee")==="garage",lines:amounts(f,lines)})}>
      <Select label="Người nhận tiền bảo hiểm" name="payee" required options={[{value:"",label:"Chọn theo hồ sơ"},{value:"garage",label:"Doanh nghiệp chuyển tiền cho gara"},{value:"owner",label:"Khách trả gara, tự nhận bồi thường"}]}/>
      <Lines rows={lines}/></InsuranceForm>}
    </details>
    <h4 className="font-semibold">3. Phân bổ thanh toán</h4>
    {quote&&<div className="rounded-lg border border-border p-3">
      <p>Tổng báo giá: {formatMoney(quote.total)}</p>
      <p>Bảo hiểm đã duyệt: {formatMoney(approved)}</p>
      <p>Khách thanh toán gara theo báo giá: {formatMoney(quote.total-(current?.direct?approved:0))}</p>
      <p>{current?.direct?'Bảo hiểm trả trực tiếp gara.':'Khách trả gara đầy đủ; bảo hiểm hoàn tiền cho khách nếu được duyệt.'}</p>
      <p className="text-sm">Hóa đơn cuối cùng tính theo hạng mục thực hiện và phụ tùng thực dùng. Khoản chưa duyệt không được giảm trừ.</p>
    </div>}
    {work.proposals.map(p=><div className="rounded-lg border p-3" key={p.id}><b>Báo giá #{p.quoteId}, lần {p.revision}</b> · {p.direct?"Gara nhận tiền":"Khách nhận bồi thường"}
      <p>{p.reference?"Quyết định "+p.reference:"Đang chờ doanh nghiệp trả lời"}</p>
      {p.lines.map(l=><p key={l.lineId}>{l.name} · đề nghị {formatMoney(l.requested)} · chấp thuận {l.approved==null?"chưa có":formatMoney(l.approved)}{l.payable!=null&&" · phải thu bảo hiểm "+formatMoney(l.payable)}</p>)}</div>)}
    {open&&current&&!current.documentId&&<InsuranceForm title="Ghi nhận quyết định của doanh nghiệp bảo hiểm" done={done} save={f=>insuranceApi.save(finance+"/decisions",{version,proposalId:current.id,documentId:Number(f.get("document")),reference:val(f,"reference"),reason:val(f,"reason"),lines:amounts(f,current.lines)})}>
      <DocumentChoice docs={work.documents} category="QUYET_DINH"/><Input name="reference" label="Số văn bản" required/><Input name="reason" label="Căn cứ chấp thuận hoặc giảm trừ" required/>
      <Lines rows={current.lines.map(l=>({lineId:l.lineId,name:l.name,cap:l.requested}))}/></InsuranceForm>}
    <h4 className="font-semibold">Hóa đơn và công nợ</h4>
    <a className="text-primary underline" href="/admin/invoice">Mở hóa đơn và thu phần khách hàng</a>
    {open&&invoice&&current?.documentId&&!balance&&<InsuranceForm title="Chốt số phải thu theo hóa đơn thực tế" done={done} save={f=>insuranceApi.save(finance+"/settlements",{version,proposalId:current.id,invoiceId:invoice.invoice.id,lines:amounts(f,current.lines)})}>
      <p>Tổng hóa đơn {formatMoney(invoice.invoice.total)}. Phần còn lại sau phân bổ do khách thanh toán.</p>
      <Lines rows={current.lines.map(l=>{const actual=invoice.lines.find(a=>a.type===(l.kind==="SERVICE"?"DICH_VU":"PHU_TUNG")&&a.id===l.itemId);
        return {lineId:l.lineId,name:l.name,cap:current.direct&&actual?Math.min(l.approved??0,actual.unitPrice*actual.quantity):0};})}/></InsuranceForm>}
    {balance&&<div><p>Khách phải trả {formatMoney(balance.customerDue)} · đã trả {formatMoney(balance.customerPaid)} · còn {formatMoney(balance.customerDue-balance.customerPaid)}</p>
      <p>Bảo hiểm phải trả {formatMoney(balance.insurerDue)} · đã nhận {formatMoney(balance.insurerPaid)} · còn {formatMoney(balance.insurerDue-balance.insurerPaid)}</p></div>}
    {open&&invoice&&balance&&balance.insurerPaid<balance.insurerDue&&<InsuranceForm title="Đối soát khoản bảo hiểm đã chuyển" done={()=>{setRequestId(crypto.randomUUID());done();}} save={f=>billingApi.pay(invoice.invoice.id,{amount:Number(f.get("amount")),payer:"INSURER",method:"CHUYEN_KHOAN",requestId,bankAccountId:null,documentId:Number(f.get("document")),reference:val(f,"reference")})}>
      <DocumentChoice docs={work.documents} category="CHUYEN_TIEN"/><Input name="reference" label="Mã giao dịch ngân hàng" required/><Input name="amount" label="Số tiền thực nhận" type="number" step="0.01" min="0.01" max={balance.insurerDue-balance.insurerPaid} required/>
    </InsuranceForm>}
    {work.receipts.map(r=><p key={r.id}>{r.receivedAt} · {r.reference} · {formatMoney(r.amount)}</p>)}
    {open&&balance&&balance.customerPaid===balance.customerDue&&balance.insurerPaid===balance.insurerDue&&<InsuranceForm title="Đóng hồ sơ đã đối soát" label="Đóng hồ sơ" done={done} save={()=>insuranceApi.save(finance+"/close?version="+version,{})}><p>Đã thu đủ phần của khách và doanh nghiệp bảo hiểm.</p></InsuranceForm>}
    <details><summary>Nhật ký hồ sơ</summary>{claim.events.map(e=><p key={e.id}>{e.occurredAt} · NV{e.employeeId} · {e.action} · {e.note}</p>)}</details>
  </Card>;
}
