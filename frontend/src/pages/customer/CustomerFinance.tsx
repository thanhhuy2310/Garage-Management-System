import {useCallback,useState} from 'react'
import {customerFinanceApi,type VehicleStats} from '../../api/customerFinance'
import {useGarageQuery} from '../../hooks/useGarageQuery'
import {Card,Button,Input,Select} from '../../components/ui'
import {QueryState} from '../../components/garage/QueryState'
import {formatMoney,formatGarageDate} from '../../utils/garageFormat'
const status:Record<string,string>={CHO_DOI_CHIEU:'Chờ đối chiếu bảo hiểm',DA_THANH_TOAN:'Đã thanh toán',THANH_TOAN_MOT_PHAN:'Thanh toán một phần',CHUA_THANH_TOAN:'Chưa thanh toán'}
function vehicleLabel(vehicle: VehicleStats['vehicle']) {
  return vehicle.currentlyOwned ? vehicle.licensePlate : `${vehicle.licensePlate} (đã chuyển chủ)`
}
export function CustomerInvoices(){
  const query=useGarageQuery(customerFinanceApi.invoices)
  return <div className="space-y-4"><div className="flex justify-between"><h2 className="text-xl font-semibold">Hóa đơn của tôi</h2><Button disabled={query.loading} onClick={query.reload}>Làm mới</Button></div>
    <p>Thanh toán theo hướng dẫn của gara. Số tiền đã thu được cập nhật sau khi nhân viên xác nhận.</p>
    <QueryState loading={query.loading} error={query.error} onRetry={query.reload}/>
    {query.data?.length===0&&<Card className="p-5">Bạn chưa có hóa đơn.</Card>}
    {query.data?.map(h=><Card key={h.id} className="space-y-3 p-5">
      <h3 className="font-semibold">HĐ{h.id} · {h.licensePlate}</h3><p>{formatGarageDate(h.createdAt)} · {status[h.status]??h.status}</p>
      <p>Tổng hóa đơn: {formatMoney(h.total)} · Bảo hiểm hỗ trợ theo duyệt: {formatMoney(h.insuranceSupport)}</p>
      <p>Khách cần thanh toán gara: {h.customerDue===null?'Chờ đối chiếu':formatMoney(h.customerDue)} · Đã trả: {formatMoney(h.customerPaid)} · Còn lại: {h.remaining===null?'Chờ đối chiếu':formatMoney(h.remaining)}</p>
      {h.insuranceSupport>0&&h.customerDue===h.total&&<p>Bảo hiểm hoàn tiền trực tiếp cho khách; khách vẫn thanh toán đầy đủ cho gara.</p>}
      <details><summary className="cursor-pointer font-medium">Chi tiết dịch vụ, phụ tùng và thanh toán</summary>
        <ul className="divide-y divide-border">{h.lines.map(l=><li key={`${l.type}-${l.id}`} className="py-2">{l.type==='PHU_TUNG'?'Phụ tùng':'Dịch vụ'}: {l.name} · {l.quantity} × {formatMoney(l.unitPrice)} = {formatMoney(l.quantity*l.unitPrice)}</li>)}</ul>
        {h.payments.length===0?<p>Chưa ghi nhận thanh toán.</p>:h.payments.map((p,i)=><p key={i}>{formatGarageDate(p.paidAt)} · {p.payer==='INSURER'?'Bảo hiểm':'Khách hàng'} · {p.method==='TIEN_MAT'?'Tiền mặt':'Chuyển khoản'} · {formatMoney(p.amount)}</p>)}
      </details>
    </Card>)}
  </div>
}
export function CustomerStatistics(){
  const [vehicle,setVehicle]=useState(''),[year,setYear]=useState('')
  const loadOptions=useCallback((signal:AbortSignal)=>customerFinanceApi.statistics(undefined,undefined,signal),[])
  const options=useGarageQuery(loadOptions)
  const load=useCallback((signal:AbortSignal)=>customerFinanceApi.statistics(vehicle?Number(vehicle):undefined,year?Number(year):undefined,signal),[vehicle,year])
  const query=useGarageQuery(load),data=query.data
  return <div className="space-y-4"><h2 className="text-xl font-semibold">Thống kê xe của tôi</h2>
    <div className="grid gap-3 sm:grid-cols-3"><Select label="Xe" value={vehicle} onChange={e=>setVehicle(e.target.value)} options={[{value:'',label:'Tất cả xe'},...(options.data?.vehicles??[]).map(v=>({value:String(v.vehicle.id),label:vehicleLabel(v.vehicle)}))]}/>
    <Input label="Năm (bỏ trống để xem tất cả)" type="number" min={1900} max={9999} value={year} onChange={e=>setYear(e.target.value)}/><Button disabled={query.loading} onClick={query.reload}>Làm mới thống kê</Button></div>
    <QueryState loading={query.loading} error={query.error||options.error} onRetry={()=>{query.reload();options.reload()}}/>
    {data&&!query.error&&<>
      <Card className="space-y-2 p-5"><p>Số xe hiện sở hữu: {data.vehicleCount} · Lượt hoàn thành: {data.completedVisits}</p><p>Sửa chữa: {data.repairVisits} · Bảo dưỡng: {data.maintenanceVisits}</p>
      <p>Tổng chi phí: {formatMoney(data.totalCost)} · Phần khách chịu sau bảo hiểm đã chốt: {formatMoney(data.customerCost)}</p>
      <p className="text-sm">Một lượt có cả sửa chữa và bảo dưỡng được tính ở cả hai loại, nhưng chỉ tính một lần trong tổng lượt và chi phí.</p>
      {data.awaitingInvoicesOrInsurance>0&&<p>{data.awaitingInvoicesOrInsurance} lượt chưa lập hóa đơn hoặc chưa chốt bảo hiểm; phần khách chịu chưa được cộng cho các lượt này.</p>}
      {data.completedVisits===0&&<p>Chưa có lượt hoàn thành trong phạm vi đã chọn.</p>}</Card>
      {data.vehicles.map(v=><Card key={v.vehicle.id} className="space-y-2 p-4"><h3 className="font-medium">{vehicleLabel(v.vehicle)} · {[v.vehicle.brand,v.vehicle.model].filter(Boolean).join(' ')}</h3>
        <p>{v.completedVisits} lượt · {v.repairVisits} sửa chữa · {v.maintenanceVisits} bảo dưỡng</p><p>Chi phí: {formatMoney(v.totalCost)} · Khách chịu đã chốt: {formatMoney(v.customerCost)}</p><p>Lần gần nhất: {v.lastRepair?formatGarageDate(v.lastRepair):'Chưa có'}</p></Card>)}
      <Card className="p-4"><h3 className="font-semibold">Chi phí theo tháng</h3>{data.months.map(m=><p key={`${m.year}-${m.month}`}>Tháng {m.month}/{m.year}: {m.completedVisits} lượt · {formatMoney(m.totalCost)} · Khách chịu: {formatMoney(m.customerCost)}</p>)}</Card>
    </>}
  </div>
}
