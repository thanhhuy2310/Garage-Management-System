import {useCallback} from 'react'
import {receptionsApi} from '../../api/receptions'
import {insuranceApi} from '../../api/insurance'
import {useGarageQuery} from '../../hooks/useGarageQuery'
import {QueryState} from '../../components/garage/QueryState'
import {Card} from '../../components/ui'
import InsuranceCase from './InsuranceCase'
import {statusName} from './forms'

export default function RepairInsurance({receptionId}:{receptionId:number}) {
  const load=useCallback(async()=>{
    const reception=await receptionsApi.get(receptionId)
    const [policies,claims,companies]=await Promise.all([insuranceApi.policies(reception.vehicleId),insuranceApi.claims(reception.vehicleId),insuranceApi.companies()])
    return {policies,companies,claim:claims.find(c=>c.receptionId===receptionId)}
  },[receptionId])
  const query=useGarageQuery(load)
  return <Card className="space-y-3 p-5"><h3 className="font-semibold">Bảo hiểm sửa chữa</h3>
    <QueryState loading={query.loading} error={query.error} onRetry={query.reload}/>
    {query.data&&<>
      {!query.data.policies.length&&<p>Xe chưa có hợp đồng bảo hiểm được lưu. Có thể sửa chữa và thanh toán thông thường.</p>}
      {query.data.policies.map(p=><p key={p.id}>{query.data?.companies.find(c=>c.id===p.companyId)?.name} · {p.policyNumber} · {p.startDate} – {p.endDate} · {statusName(p.verificationStatus)} · Chủ hợp đồng: {p.certificateOwnerName}</p>)}
      {query.data.claim?<InsuranceCase id={query.data.claim.id}/>:<p>Chưa đăng ký sử dụng bảo hiểm cho lần sửa chữa này. <a href="/admin/insurance" className="text-primary underline">Kiểm tra hợp đồng và mở hồ sơ bảo hiểm</a></p>}
    </>}
  </Card>
}
