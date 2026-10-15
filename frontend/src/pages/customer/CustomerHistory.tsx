import { useCallback, useState } from "react";
import { Badge, Card } from "../../components/ui";
import { QueryState } from "../../components/garage/QueryState";
import { useGarageQuery } from "../../hooks/useGarageQuery";
import { customerRepairsApi } from "../../api/customerRepairs";
import { formatGarageDate, formatMoney } from "../../utils/garageFormat";
function Details({id}: {id: number}) {
  const load = useCallback((signal: AbortSignal) => customerRepairsApi.detail(id, signal), [id]);
  const query = useGarageQuery(load);
  return <div><QueryState {...query} onRetry={query.reload}/>{query.data && <ul className="mt-2 space-y-2">
    {[...query.data.services, ...query.data.parts].map((line, index) => <li key={index} className="flex justify-between gap-3 rounded-lg bg-surface-subtle p-3 text-sm"><span>{line.name} ×{line.quantity}</span><span>{formatMoney(line.lineTotal)}</span></li>)}
  </ul>}</div>;
}
export default function CustomerHistory() {
  const query = useGarageQuery(customerRepairsApi.history);
  const [expanded, setExpanded] = useState<number | null>(null);
  return <div className="space-y-6">
    <div><h2 className="ui-section-title">Lịch sử sửa chữa / bảo dưỡng</h2><p className="ui-secondary-text text-sm">Chi phí thực tế từ phiếu sửa chữa hoàn tất</p></div>
    <QueryState {...query} onRetry={query.reload}/>
    {query.data?.length === 0 && <Card className="p-10 text-center">Chưa có lịch sử sửa chữa.</Card>}
    <ul className="space-y-4">{query.data?.map(repair => <li key={repair.repairOrderId}><Card className="p-5">
      <div className="flex justify-between"><div><p className="mono text-lg font-bold text-primary">{repair.licensePlate}</p><p className="text-xs text-muted-foreground">{repair.brand} {repair.model} · Phiếu {repair.repairOrderId} · {formatGarageDate(repair.completedAt)}</p></div><Badge variant="completed" label="Hoàn tất"/></div>
      {repair.result && <p className="mt-2 text-sm">Kết quả: {repair.result}</p>}
      <div className="mt-3 flex justify-between rounded-lg bg-surface-subtle p-3"><span>Tổng chi phí</span><strong>{formatMoney(repair.totalCost)}</strong></div>
      <button className="mt-2 min-h-11 text-sm text-primary" aria-expanded={expanded === repair.repairOrderId} onClick={() => setExpanded(expanded === repair.repairOrderId ? null : repair.repairOrderId)}>{expanded === repair.repairOrderId ? "Thu gọn chi tiết" : "Xem chi tiết hạng mục"}</button>
      {expanded === repair.repairOrderId && <Details id={repair.repairOrderId}/>}
    </Card></li>)}</ul>
  </div>;
}
