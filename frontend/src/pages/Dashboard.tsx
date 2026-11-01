import { garageApi } from "../api/garage";
import { inventoryApi } from "../api/warehouse";
import { useGarageQuery } from "../hooks/useGarageQuery";
import { QueryState } from "../components/garage/QueryState";
const loadLowStock = async () => {
 const [low, out] = await Promise.all([inventoryApi.stock({status: "SAP_HET", size: 100}), inventoryApi.stock({status: "HET_HANG", size: 100})]);
 return {items: [...out.items, ...low.items], count: low.totalElements + out.totalElements};
};
import React, { useState } from "react";
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, Tooltip, ResponsiveContainer
} from "recharts";
import { Card, StatCard, Badge, Icons } from "../components/ui";
import { appointmentsApi, appointmentLabels } from "../api/appointments";
import { quotationsApi } from "../api/quotations";
import { dashboardApi } from "../api/dashboard";
import { formatMoney as formatCurrency } from "../utils/garageFormat";

const PIE_COLORS = ["#2563eb", "#b45309", "#047857", "#f97316", "#7c3aed", "#526176"];

type ChartPeriod = "week" | "month";

export default function Dashboard() {
  const repairs = useGarageQuery(garageApi.repairOrders);
  const stock = useGarageQuery(loadLowStock);
  const appointments = useGarageQuery(appointmentsApi.list);
  const quotations = useGarageQuery(quotationsApi.list);
  const dashboard = useGarageQuery(dashboardApi.get);
  const today = dashboard.data?.date ?? "";
  const statusMap: Record<string, string> = {MOI_TAO: "pending", CHO_SUA: "pending", DANG_KIEM_TRA: "pending", DANG_SUA: "in_progress", CHO_PHU_TUNG: "waiting_parts", HOAN_TAT: "completed", HUY: "cancelled", DA_HUY: "cancelled"};
  const repairRows = (repairs.data ?? []).map(r => ({id: r.id, vehicle: r.licensePlate, customer: r.customerName, status: statusMap[r.status] ?? "pending"}));
  const inventoryRows = (stock.data?.items ?? []).map(p => ({id: p.id, name: p.name, stock: p.stockQuantity, minStock: p.minStockLevel, status: p.stockStatus === "HET_HANG" ? "out" : "low"}));
const repairStatusCount = {
  pending: repairRows.filter(r => r.status === "pending").length,
  in_progress: repairRows.filter(r => r.status === "in_progress").length,
  waiting_parts: repairRows.filter(r => r.status === "waiting_parts").length,
  completed: repairRows.filter(r => r.status === "completed").length,
};

const pieData = [
  { name: "Đang sửa", value: repairStatusCount.in_progress, color: "#2563eb" },
  { name: "Chờ phụ tùng", value: repairStatusCount.waiting_parts, color: "#f97316" },
  { name: "Chờ xử lý", value: repairStatusCount.pending, color: "#b45309" },
  { name: "Hoàn tất", value: repairStatusCount.completed, color: "#047857" },
];

const lowStock = inventoryRows.filter(i => i.status === "low" || i.status === "out");
const todayAppointments = (appointments.data ?? []).filter(a => a.date === today && !["HUY", "DA_HUY"].includes(a.status));
const pendingQuotations = (quotations.data ?? []).filter(q => q.status === "CHO_XAC_NHAN");
const chartRevenue = (dashboard.data?.dailyRevenue ?? []).map(p => ({date: p.period.slice(5).split("-").reverse().join("/"),revenue: p.revenue}));
const chartMonthly = (dashboard.data?.monthlyRevenue ?? []).map(p => ({month: p.period.slice(5)+"/"+p.period.slice(0,4),revenue: p.revenue}));
const chartServices = (dashboard.data?.popularServices ?? []).map(p => ({name:p.name,value:p.count}));
  const [chartPeriod, setChartPeriod] = useState<ChartPeriod>("week");
  const data = chartPeriod === "week" ? chartRevenue.map(p => ({label:p.date,revenue:p.revenue})) : chartMonthly.map(p => ({label:p.month,revenue:p.revenue}));
  const xKey = "label";
  const queries = [repairs,stock,appointments,quotations,dashboard];
  if (queries.some(q => q.loading || q.error)) return <div className="space-y-3">{queries.map((q,i) => <QueryState key={i} {...q} onRetry={q.reload}/>)}</div>;

  return (
    <div className="space-y-6">
      <QueryState {...repairs} onRetry={repairs.reload}/><QueryState {...stock} onRetry={stock.reload}/>
      {/* Page heading */}
      <div className="flex flex-col gap-1 sm:flex-row sm:items-end sm:justify-between">
        <div>
          <h2 className="ui-page-title">Tổng quan gara</h2>
          <p className="ui-secondary-text text-sm">Phiếu sửa chữa, tồn kho và doanh thu thực thu · {today}</p>
        </div>
        <span className="mono w-fit rounded-md bg-surface-subtle px-2 py-1 text-xs text-muted-foreground">{today}</span>
      </div>

      {/* Primary KPI group */}
      <div>
        <h3 className="ui-section-title mb-3 text-sm">Chỉ số tổng quan</h3>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Tiếp nhận hôm nay" value={dashboard.data!.receivedToday} icon={Icons.truck} color="navy" />
        <StatCard label="Đang sửa chữa" value={repairs.data ? repairStatusCount.in_progress + repairStatusCount.waiting_parts : "—"} icon={Icons.wrench} color="blue" />
        <StatCard label="Lịch hẹn hôm nay" value={todayAppointments.length} icon={Icons.calendar} color="navy" />
          <StatCard label="Thực thu hôm nay" value={formatCurrency(dashboard.data!.collectedToday)} icon={Icons.creditCard} color="green" />
        </div>
      </div>

      {/* Secondary KPI group */}
      <div>
        <h3 className="ui-section-title mb-3 text-sm">Cần xử lý</h3>
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <StatCard label="Đã hoàn tất" value={repairs.data ? repairStatusCount.completed : "—"} icon={Icons.checkCircle} color="green" />
        <StatCard label="Báo giá chờ xác nhận" value={pendingQuotations.length} icon={Icons.fileText} color="amber" />
          <StatCard label="Phụ tùng sắp hết" value={stock.data?.count ?? "—"} icon={Icons.alertTriangle} color="red" />
        </div>
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        {/* Revenue chart */}
        <Card className="p-4 sm:p-5 xl:col-span-2">
          <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <h3 className="text-base font-semibold text-foreground">Doanh thu thực thu</h3>
            <div className="flex gap-1 bg-slate-100 p-0.5 rounded-lg">
              {(["week", "month"] as ChartPeriod[]).map(p => (
                <button key={p} onClick={() => setChartPeriod(p)} aria-pressed={chartPeriod === p}
                  className={`min-h-11 rounded-md px-4 text-sm font-medium transition-all ${chartPeriod === p ? "bg-white shadow-sm text-primary" : "text-slate-600 hover:text-slate-900"}`}>
                  {p === "week" ? "7 ngày" : "7 tháng"}
                </button>
              ))}
            </div>
          </div>
          <div role="img" aria-label={`Biểu đồ doanh thu trong ${chartPeriod === "week" ? "7 ngày" : "7 tháng"} gần nhất`}>
            <ResponsiveContainer width="100%" height={280}>
              <AreaChart data={data} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#17365f" stopOpacity={0.18} />
                  <stop offset="95%" stopColor="#17365f" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey={xKey} tick={{ fontSize: 12, fill: "#526176" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: "#526176" }} axisLine={false} tickLine={false}
                tickFormatter={(v) => v >= 1000000 ? `${(v / 1000000).toFixed(0)}M` : `${(v / 1000).toFixed(0)}k`} />
              <Tooltip
                formatter={(v: any, name: any) => [
                  name === "revenue" ? formatCurrency(Number(v)) : v,
                  name === "revenue" ? "Doanh thu" : "Lượt"
                ]}
                contentStyle={{ borderRadius: 8, border: "1px solid var(--border)", fontSize: 12 }}
              />
              <Area type="monotone" dataKey="revenue" stroke="#17365f" strokeWidth={2} fill="url(#revenueGrad)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        {/* Pie chart */}
        <Card className="p-4 sm:p-5">
          <h3 className="mb-4 text-base font-semibold text-foreground">Tình trạng sửa chữa</h3>
          <div role="img" aria-label="Biểu đồ tỷ lệ trạng thái sửa chữa">
            <ResponsiveContainer width="100%" height={190}>
              <PieChart>
              <Pie data={pieData} dataKey="value" cx="50%" cy="50%" outerRadius={65} innerRadius={38} paddingAngle={3}>
                {pieData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
              </Pie>
              <Tooltip contentStyle={{ borderRadius: 8, border: "1px solid var(--border)", fontSize: 12 }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="mt-2 grid grid-cols-2 gap-x-4 gap-y-2 xl:grid-cols-1">
            {pieData.map(d => (
              <div key={d.name} className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-1.5">
                  <span className="w-2.5 h-2.5 rounded-full" style={{ background: d.color }} />
                  <span className="text-slate-600">{d.name}</span>
                </div>
                <span className="font-semibold text-slate-800">{d.value}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Bottom row */}
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        {/* Today's appointments */}
        <Card className="p-4 sm:p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-semibold text-foreground">Lịch hẹn hôm nay</h3>
            <span className="text-xs text-slate-400">{todayAppointments.length} lịch hẹn</span>
          </div>
          <div className="divide-y divide-border">
            {todayAppointments.length === 0 && <p className="text-sm text-slate-500">Chưa có lịch hẹn hôm nay.</p>}
            {todayAppointments.map(a => (
              <div key={a.id} className="flex items-start gap-3 py-3 first:pt-0 last:pb-0">
                <div className="w-10 text-center">
                  <span className="mono block rounded-md bg-primary-soft px-1.5 py-1 text-xs font-semibold text-primary">{a.time}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-800 truncate">{a.customerName}</p>
                  <p className="text-xs text-slate-500 truncate">{a.plate} · {a.serviceName ?? "Tư vấn tại gara"}</p>
                </div>
                <Badge variant={a.status === "DA_XAC_NHAN" ? "confirmed" : a.status === "DA_DEN" ? "arrived" : "pending"} label={appointmentLabels[a.status] ?? a.status} />
              </div>
            ))}
          </div>
        </Card>

        {/* Active repairs */}
        <Card className="p-4 sm:p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-semibold text-foreground">Xe đang sửa chữa</h3>
          </div>
          <div className="divide-y divide-border">
            {repairRows.filter(r => !["completed", "cancelled"].includes(r.status)).map(r => (
              <div key={r.id} className="flex items-center gap-3 py-3 first:pt-0 last:pb-0">
                <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg bg-primary-soft">
                  <span className="text-primary">{Icons.car}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-800">{r.vehicle}</p>
                  <p className="text-xs text-slate-500 truncate">{r.customer}</p>
                </div>
                <Badge variant={r.status as any} />
              </div>
            ))}
          </div>
        </Card>

        {/* Low stock */}
        <Card className="p-4 sm:p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-semibold text-foreground">Phụ tùng sắp hết / hết hàng</h3>
            <span className="text-xs text-warning font-medium">{lowStock.length} mặt hàng</span>
          </div>
          <div className="divide-y divide-border">
            {lowStock.map(item => (
              <div key={item.id} className="flex items-center justify-between gap-3 py-3 first:pt-0">
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-800 truncate">{item.name}</p>
                  <p className="text-xs text-slate-500">Tồn: {item.stock} / Tối thiểu: {item.minStock}</p>
                </div>
                <Badge variant={item.status as any} />
              </div>
            ))}
            {pendingQuotations.map(q => (
              <div key={q.id} className="flex items-center justify-between gap-3 py-3 last:pb-0">
                <div>
                  <p className="text-xs font-medium text-warning">Báo giá chờ xác nhận</p>
                  <p className="text-xs text-muted-foreground">{q.customerName} · {q.plate}</p>
                </div>
                <span className="whitespace-nowrap text-xs font-bold text-warning">{formatCurrency(q.total)}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Services chart */}
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
        <Card className="p-4 sm:p-5">
          <h3 className="mb-4 text-base font-semibold text-foreground">Dịch vụ sử dụng nhiều nhất · 7 tháng</h3>
          <div role="img" aria-label="Biểu đồ các dịch vụ được sử dụng nhiều nhất">
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={chartServices} layout="vertical" margin={{ left: 0, right: 30 }}>
              <XAxis type="number" tick={{ fontSize: 12, fill: "#526176" }} axisLine={false} tickLine={false} />
              <YAxis type="category" dataKey="name" tick={{ fontSize: 12, fill: "#475569" }} axisLine={false} tickLine={false} width={120} />
              <Tooltip contentStyle={{ borderRadius: 8, border: "1px solid var(--border)", fontSize: 12 }} formatter={(v) => [`${v} lượt`, "Số lần"]} />
              <Bar dataKey="value" radius={[0, 4, 4, 0]}>
                {chartServices.map((_, i) => <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          </div>
        </Card>

        <Card className="p-4 sm:p-5">
          <h3 className="mb-4 text-base font-semibold text-foreground">Thực thu theo tháng</h3>
          <div role="img" aria-label="Biểu đồ doanh thu theo tháng">
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={chartMonthly} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <XAxis dataKey="month" tick={{ fontSize: 12, fill: "#526176" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: "#526176" }} axisLine={false} tickLine={false}
                tickFormatter={(v) => `${(v / 1000000).toFixed(0)}M`} />
              <Tooltip contentStyle={{ borderRadius: 8, border: "1px solid var(--border)", fontSize: 12 }}
                formatter={(v: any) => [formatCurrency(Number(v)), "Doanh thu"]} />
              <Bar dataKey="revenue" fill="#17365f" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
          </div>
        </Card>
      </div>
    </div>
  );
}
