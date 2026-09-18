import React, { useState } from "react";
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, Tooltip, ResponsiveContainer, Legend
} from "recharts";
import { Card, StatCard, Badge, Icons } from "../components/ui";
import {
  mockAppointments, mockRepairOrders, mockInventory,
  mockQuotations, chartRevenue, chartMonthly, chartServices,
  DEMO_TODAY, formatCurrency
} from "../mock/data";

const PIE_COLORS = ["#3b82f6", "#f59e0b", "#10b981", "#f97316", "#8b5cf6", "#64748b"];

const repairStatusCount = {
  pending: mockRepairOrders.filter(r => r.status === "pending").length,
  in_progress: mockRepairOrders.filter(r => r.status === "in_progress").length,
  waiting_parts: mockRepairOrders.filter(r => r.status === "waiting_parts").length,
  completed: mockRepairOrders.filter(r => r.status === "completed").length,
};

const pieData = [
  { name: "Đang sửa", value: repairStatusCount.in_progress, color: "#3b82f6" },
  { name: "Chờ phụ tùng", value: repairStatusCount.waiting_parts, color: "#f97316" },
  { name: "Chờ xử lý", value: repairStatusCount.pending, color: "#f59e0b" },
  { name: "Hoàn tất", value: repairStatusCount.completed, color: "#10b981" },
];

const lowStock = mockInventory.filter(i => i.status === "low" || i.status === "out");
const todayAppointments = mockAppointments.filter(a => a.date === DEMO_TODAY);
const pendingQuotations = mockQuotations
  .filter((quotation) => quotation.status === "pending")
  .map((quotation) => ({
    ...quotation,
    total: [...quotation.services, ...quotation.parts]
      .reduce((sum, item) => sum + item.qty * item.price, 0),
  }));

type ChartPeriod = "week" | "month";

export default function Dashboard() {
  const [chartPeriod, setChartPeriod] = useState<ChartPeriod>("week");
  const data = (chartPeriod === "week" ? chartRevenue : chartMonthly) as any[];
  const xKey = chartPeriod === "week" ? "date" : "month";

  return (
    <div className="p-6 space-y-6">
      {/* Stat cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4 2xl:grid-cols-7">
        <StatCard label="Tiếp nhận hôm nay" value="4" icon={Icons.truck} color="navy" trend="+1 so với hôm qua" trendUp />
        <StatCard label="Đang sửa chữa" value={repairStatusCount.in_progress + repairStatusCount.waiting_parts} icon={Icons.wrench} color="blue" />
        <StatCard label="Đã hoàn tất" value={repairStatusCount.completed} icon={Icons.checkCircle} color="green" />
        <StatCard label="Lịch hẹn hôm nay" value={todayAppointments.length} icon={Icons.calendar} color="navy" />
        <StatCard label="Báo giá chờ xác nhận" value={pendingQuotations.length} icon={Icons.fileText} color="amber" />
        <StatCard label="Doanh thu hôm nay" value={formatCurrency(chartRevenue.at(-1)?.revenue ?? 0)} icon={Icons.creditCard} color="green" trend="+12% so hôm qua" trendUp />
        <StatCard label="Phụ tùng sắp hết" value={lowStock.length} icon={Icons.alertTriangle} color="red" />
      </div>

      {/* Charts row */}
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        {/* Revenue chart */}
        <Card className="p-5 xl:col-span-2">
          <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <h3 className="text-base font-semibold text-slate-900">Doanh thu & Lượt sửa chữa</h3>
            <div className="flex gap-1 bg-slate-100 p-0.5 rounded-lg">
              {(["week", "month"] as ChartPeriod[]).map(p => (
                <button key={p} onClick={() => setChartPeriod(p)} aria-pressed={chartPeriod === p}
                  className={`min-h-9 rounded-md px-3 py-1 text-sm font-medium transition-all ${chartPeriod === p ? "bg-white shadow-sm text-primary" : "text-slate-600 hover:text-slate-900"}`}>
                  {p === "week" ? "7 ngày" : "7 tháng"}
                </button>
              ))}
            </div>
          </div>
          <div role="img" aria-label={`Biểu đồ doanh thu trong ${chartPeriod === "week" ? "7 ngày" : "7 tháng"} gần nhất`}>
            <ResponsiveContainer width="100%" height={220}>
              <AreaChart data={data} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <defs>
                <linearGradient id="revenueGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#1e3a6e" stopOpacity={0.15} />
                  <stop offset="95%" stopColor="#1e3a6e" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey={xKey} tick={{ fontSize: 12, fill: "#64748b" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: "#64748b" }} axisLine={false} tickLine={false}
                tickFormatter={(v) => v >= 1000000 ? `${(v / 1000000).toFixed(0)}M` : `${(v / 1000).toFixed(0)}k`} />
              <Tooltip
                formatter={(v: any, name: any) => [
                  name === "revenue" ? formatCurrency(Number(v)) : v,
                  name === "revenue" ? "Doanh thu" : "Lượt"
                ]}
                contentStyle={{ borderRadius: 8, border: "1px solid #dde3ec", fontSize: 12 }}
              />
              <Area type="monotone" dataKey="revenue" stroke="#1e3a6e" strokeWidth={2} fill="url(#revenueGrad)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        {/* Pie chart */}
        <Card className="p-5">
          <h3 className="mb-4 text-base font-semibold text-slate-900">Tình trạng sửa chữa</h3>
          <div role="img" aria-label="Biểu đồ tỷ lệ trạng thái sửa chữa">
            <ResponsiveContainer width="100%" height={160}>
              <PieChart>
              <Pie data={pieData} dataKey="value" cx="50%" cy="50%" outerRadius={65} innerRadius={38} paddingAngle={3}>
                {pieData.map((entry, i) => <Cell key={i} fill={entry.color} />)}
              </Pie>
              <Tooltip contentStyle={{ borderRadius: 8, border: "1px solid #dde3ec", fontSize: 12 }} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="space-y-1.5 mt-2">
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
        <Card className="p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-semibold text-slate-900">Lịch hẹn hôm nay</h3>
            <span className="text-xs text-slate-400">{todayAppointments.length} lịch hẹn</span>
          </div>
          <div className="space-y-3">
            {todayAppointments.map(a => (
              <div key={a.id} className="flex items-start gap-3 rounded-lg bg-slate-50 p-3 transition-colors hover:bg-slate-100">
                <div className="w-10 text-center">
                  <span className="text-xs font-mono font-semibold text-[#1e3a6e] bg-[#e8eef7] px-1.5 py-1 rounded block">{a.time}</span>
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-800 truncate">{a.customer}</p>
                  <p className="text-xs text-slate-500 truncate">{a.vehicle} · {a.service}</p>
                </div>
                <Badge variant={a.status as any} />
              </div>
            ))}
          </div>
        </Card>

        {/* Active repairs */}
        <Card className="p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-semibold text-slate-900">Xe đang sửa chữa</h3>
          </div>
          <div className="space-y-3">
            {mockRepairOrders.filter(r => r.status !== "completed").map(r => (
              <div key={r.id} className="flex items-center gap-3 rounded-lg bg-slate-50 p-3 transition-colors hover:bg-slate-100">
                <div className="w-8 h-8 bg-[#e8eef7] rounded-lg flex items-center justify-center flex-shrink-0">
                  <span className="text-[#1e3a6e]">{Icons.car}</span>
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
        <Card className="p-5">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-base font-semibold text-slate-900">Phụ tùng sắp hết / hết hàng</h3>
            <span className="text-xs text-amber-600 font-medium">{lowStock.length} mặt hàng</span>
          </div>
          <div className="space-y-2">
            {lowStock.map(item => (
              <div key={item.id} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-medium text-slate-800 truncate">{item.name}</p>
                  <p className="text-xs text-slate-500">Tồn: {item.stock} / Tối thiểu: {item.minStock}</p>
                </div>
                <Badge variant={item.status as any} />
              </div>
            ))}
            {pendingQuotations.map(q => (
              <div key={q.id} className="flex items-center justify-between p-3 bg-amber-50 rounded-lg border border-amber-100">
                <div>
                  <p className="text-xs font-medium text-amber-800">Báo giá chờ xác nhận</p>
                  <p className="text-xs text-amber-700">{q.customer} · {q.vehicle}</p>
                </div>
                <span className="text-xs font-bold text-amber-800">{formatCurrency(q.total)}</span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Services chart */}
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
        <Card className="p-5">
          <h3 className="mb-4 text-base font-semibold text-slate-900">Dịch vụ sử dụng nhiều nhất</h3>
          <div role="img" aria-label="Biểu đồ các dịch vụ được sử dụng nhiều nhất">
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={chartServices} layout="vertical" margin={{ left: 0, right: 30 }}>
              <XAxis type="number" tick={{ fontSize: 12, fill: "#64748b" }} axisLine={false} tickLine={false} />
              <YAxis type="category" dataKey="name" tick={{ fontSize: 12, fill: "#475569" }} axisLine={false} tickLine={false} width={120} />
              <Tooltip contentStyle={{ borderRadius: 8, border: "1px solid #dde3ec", fontSize: 12 }} formatter={(v) => [`${v} lượt`, "Số lần"]} />
              <Bar dataKey="value" radius={[0, 4, 4, 0]}>
                {chartServices.map((_, i) => <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />)}
              </Bar>
            </BarChart>
          </ResponsiveContainer>
          </div>
        </Card>

        <Card className="p-5">
          <h3 className="mb-4 text-base font-semibold text-slate-900">Doanh thu theo tháng</h3>
          <div role="img" aria-label="Biểu đồ doanh thu theo tháng">
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={chartMonthly} margin={{ top: 0, right: 0, left: -20, bottom: 0 }}>
              <XAxis dataKey="month" tick={{ fontSize: 12, fill: "#64748b" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: "#64748b" }} axisLine={false} tickLine={false}
                tickFormatter={(v) => `${(v / 1000000).toFixed(0)}M`} />
              <Tooltip contentStyle={{ borderRadius: 8, border: "1px solid #dde3ec", fontSize: 12 }}
                formatter={(v: any) => [formatCurrency(Number(v)), "Doanh thu"]} />
              <Bar dataKey="revenue" fill="#1e3a6e" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
          </div>
        </Card>
      </div>
    </div>
  );
}
