import { Card, TimelineItem } from "../../components/ui";
import { QueryState } from "../../components/garage/QueryState";
import { useGarageQuery } from "../../hooks/useGarageQuery";
import { customerRepairsApi } from "../../api/customerRepairs";
import { formatGarageDate, repairStatusLabel } from "../../utils/garageFormat";
export default function CustomerTracking() {
  const query = useGarageQuery(customerRepairsApi.repairs);
  const repairs = query.data?.filter(({order}) => !["HOAN_TAT", "DA_HUY", "HUY"].includes(order.status)) ?? [];
  return <div className="space-y-6">
    <div><h2 className="ui-section-title">Tiến độ sửa chữa</h2><p className="ui-secondary-text text-sm">Nhật ký cập nhật từ gara</p></div>
    <QueryState {...query} onRetry={query.reload} />
    {query.data && repairs.length === 0 && <Card className="p-10 text-center">Không có xe nào đang sửa chữa.</Card>}
    <ul className="grid gap-4 lg:grid-cols-2">{repairs.map(({order, progress, assignments}) => <li key={order.id}>
      <Card className="h-full space-y-3 p-5">
        <p className="mono text-lg font-bold text-primary">{order.licensePlate}</p>
        <p className="text-sm">{order.brand} {order.model} · Phiếu {order.id}</p>
        <p className="font-semibold">{repairStatusLabel(order.status)}</p>
        {order.customerRequest && <p className="text-sm">Yêu cầu: {order.customerRequest}</p>}
        <p className="text-sm">Kỹ thuật viên: {assignments.map(a => a.technician.fullName).join(", ") || "Chưa phân công"}</p>
        {progress.length === 0 && <p className="text-sm text-muted-foreground">Chưa có nhật ký cập nhật.</p>}
        {progress.map(p => <TimelineItem key={p.id} label={`${repairStatusLabel(p.status)} — ${p.notes}`} time={formatGarageDate(p.createdAt)} done />)}
      </Card>
    </li>)}</ul>
  </div>;
}
