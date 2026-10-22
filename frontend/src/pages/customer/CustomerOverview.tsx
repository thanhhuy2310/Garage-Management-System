import { Button, Card, Icons } from "../../components/ui";
import { QueryState } from "../../components/garage/QueryState";
import type { CustomerPage } from "../../router";
import { useCustomerVehicles } from "../../features/vehicles/customerVehicleRepository";
import { useGarageQuery } from "../../hooks/useGarageQuery";
import { customerRepairsApi } from "../../api/customerRepairs";
import { repairStatusLabel } from "../../utils/garageFormat";
export default function CustomerOverview({onNavigate, customerId}: {onNavigate: (page: CustomerPage) => void; customerId: number}) {
 const vehicles = useCustomerVehicles(customerId);
 const repairs = useGarageQuery(customerRepairsApi.repairs);
 const active = repairs.data?.filter(({order}) => !["HOAN_TAT", "DA_HUY", "HUY"].includes(order.status));
 const summaries = [{label: "Xe của tôi", value: vehicles.loading || vehicles.error ? "—" : vehicles.vehicles.length, icon: Icons.car}, {label: "Xe đang trong xưởng", value: active?.length ?? "—", icon: Icons.wrench}, {label: "Lịch hẹn sắp tới", value: "Chưa kết nối", icon: Icons.calendar}, {label: "Thông báo chưa đọc", value: "Chưa kết nối", icon: Icons.bell}];
 return <div className="space-y-6">
  <div><p className="text-xs font-bold uppercase tracking-widest text-accent">Khu vực khách hàng</p><h1 className="ui-page-title mt-1 text-brand-dark">Tổng quan xe &amp; dịch vụ</h1></div>
  <QueryState loading={vehicles.loading} error={vehicles.error} onRetry={vehicles.reload}/><QueryState {...repairs} onRetry={repairs.reload}/>
  <section aria-label="Chỉ số tổng quan" className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">{summaries.map(item => <Card key={item.label} className="flex min-h-28 items-center gap-4 p-4"><span className="text-primary">{item.icon}</span><div><p className="text-xl font-bold">{item.value}</p><p className="text-xs text-muted-foreground">{item.label}</p></div></Card>)}</section>
  <Card className="space-y-3 p-5"><h2 className="ui-card-title">Tiến độ hiện tại</h2>{active?.length === 0 && <p>Không có xe nào đang sửa chữa.</p>}{active?.map(({order}) => <p key={order.id}>{order.licensePlate} · {repairStatusLabel(order.status)}</p>)}<Button onClick={() => onNavigate("tracking")}>Theo dõi chi tiết</Button></Card>
  <section className="flex flex-wrap gap-3"><Button onClick={() => onNavigate("vehicles")}>Xe của tôi</Button><Button variant="outline" onClick={() => onNavigate("history")}>Lịch sử sửa chữa</Button></section>
 </div>;
}
