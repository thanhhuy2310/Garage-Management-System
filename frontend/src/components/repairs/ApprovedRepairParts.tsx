import {useCallback} from 'react'
import {garageApi} from '../../api/garage'
import {useGarageQuery} from '../../hooks/useGarageQuery'
import {Card,Button} from '../ui'
import {QueryState} from '../garage/QueryState'
import {formatMoney} from '../../utils/garageFormat'
export default function ApprovedRepairParts({orderId}:{orderId:number}) {
  const load=useCallback((signal:AbortSignal)=>garageApi.approvedRepairParts(orderId,signal),[orderId])
  const query=useGarageQuery(load)
  return <Card className="space-y-3 p-5"><h3 className="font-semibold">Phụ tùng theo báo giá đã duyệt</h3>
    <Button variant="ghost" disabled={query.loading} onClick={query.reload}>Làm mới phụ tùng</Button>
    <QueryState loading={query.loading} error={query.error} onRetry={query.reload}/>
    {query.data?.length===0&&<p>Chưa có phụ tùng trong báo giá được khách xác nhận.</p>}
    <ul className="divide-y divide-border">{query.data?.map(p=><li key={p.id} className="space-y-2 py-3">
      <p className="font-medium">{p.name} · {p.status}</p>
      <p>Được duyệt: {p.approvedQuantity} · Đơn giá: {formatMoney(p.unitPrice)}</p>
      <p>Đã cấp: {p.issuedQuantity} · Đã hoàn trả: {p.returnedQuantity} · Thực dùng: {p.actualUsedQuantity}</p>
    </li>)}</ul>
  </Card>
}
