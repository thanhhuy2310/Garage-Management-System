import React, { useState } from "react";
import {
  AreaChart, Area, BarChart, Bar, PieChart, Pie, Cell,
  XAxis, YAxis, Tooltip, ResponsiveContainer, Legend
} from "recharts";
import { Card, StatCard, Button, Tabs, Icons } from "../components/ui";
import { chartMonthly, chartServices, formatCurrency } from "../data";

const PIE_COLORS = ["#1e3a6e", "#3b82f6", "#f59e0b", "#10b981", "#f97316", "#8b5cf6"];

const techStats = [
  { name: "Trần Văn Khoa", completed: 42, hours: 168, revenue: 28500000, rating: 4.8 },
  { name: "Nguyễn Thành Long", completed: 38, hours: 152, revenue: 24200000, rating: 4.7 },
  { name: "Lê Quang Hưng", completed: 35, hours: 145, revenue: 22100000, rating: 4.6 },
];

const inventoryChart = [
  { name: "T7", nhap: 45, xuat: 38, ton: 340 },
  { name: "T8", nhap: 62, xuat: 55, ton: 347 },
  { name: "T9", nhap: 28, xuat: 22, ton: 353 },
];

export default function Reports() {
  const [period, setPeriod] = useState("month");

  return (
    <div className="p-6 space-y-6">
      {/* Toolbar */}
      <div className="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          <Tabs tabs={[{ key: "week", label: "Tuần" }, { key: "month", label: "Tháng" }, { key: "quarter", label: "Quý" }, { key: "year", label: "Năm" }]}
            active={period} onChange={setPeriod} />
          <input type="month" aria-label="Chọn tháng báo cáo" defaultValue="2026-09" className="h-10 rounded-md border border-border bg-white px-3 text-sm shadow-sm" />
        </div>
        <Button variant="outline" icon={Icons.download}>Xuất báo cáo</Button>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Tổng doanh thu tháng 9" value="48.2M" icon={Icons.creditCard} color="green" trend="+15% so T8" trendUp />
        <StatCard label="Lượt sửa chữa" value="55" icon={Icons.wrench} color="blue" trend="+8% so T8" trendUp />
        <StatCard label="Xe đã hoàn tất" value="51" icon={Icons.checkCircle} color="navy" />
        <StatCard label="Khách hàng mới" value="12" icon={Icons.users} color="amber" trend="+3 so T8" trendUp />
      </div>

      {/* Revenue chart */}
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
        <Card className="p-5 xl:col-span-2">
          <h3 className="mb-4 text-base font-semibold text-slate-900">Doanh thu theo tháng</h3>
          <div role="img" aria-label="Biểu đồ doanh thu theo tháng">
            <ResponsiveContainer width="100%" height={220}>
              <AreaChart data={chartMonthly} margin={{ left: -20 }}>
              <defs>
                <linearGradient id="grad1" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#1e3a6e" stopOpacity={0.2} />
                  <stop offset="95%" stopColor="#1e3a6e" stopOpacity={0} />
                </linearGradient>
              </defs>
              <XAxis dataKey="month" tick={{ fontSize: 12, fill: "#64748b" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: "#64748b" }} axisLine={false} tickLine={false}
                tickFormatter={v => `${(v / 1000000).toFixed(0)}M`} />
              <Tooltip formatter={(v: any) => [formatCurrency(Number(v)), "Doanh thu"]}
                contentStyle={{ borderRadius: 8, border: "1px solid #dde3ec", fontSize: 12 }} />
              <Area type="monotone" dataKey="revenue" stroke="#1e3a6e" strokeWidth={2.5} fill="url(#grad1)" />
              </AreaChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card className="p-5">
          <h3 className="mb-4 text-base font-semibold text-slate-900">Tỷ lệ dịch vụ</h3>
          <div role="img" aria-label="Biểu đồ tỷ lệ dịch vụ">
            <ResponsiveContainer width="100%" height={180}>
              <PieChart>
              <Pie data={chartServices} dataKey="value" cx="50%" cy="50%" outerRadius={70} innerRadius={40} paddingAngle={3}>
                {chartServices.map((_, i) => <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />)}
              </Pie>
              <Tooltip contentStyle={{ borderRadius: 8, border: "1px solid #dde3ec", fontSize: 12 }} formatter={(v, n) => [`${v}%`, n]} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="space-y-1.5 mt-1">
            {chartServices.map((s, i) => (
              <div key={s.name} className="flex items-center justify-between text-sm">
                <div className="flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full" style={{ background: PIE_COLORS[i] }} />
                  <span className="text-slate-600">{s.name}</span>
                </div>
                <span className="font-semibold">{s.value}%</span>
              </div>
            ))}
          </div>
        </Card>
      </div>

      {/* Inventory & Technicians */}
      <div className="grid grid-cols-1 gap-4 xl:grid-cols-2">
        <Card className="p-5">
          <h3 className="mb-4 text-base font-semibold text-slate-900">Nhập / Xuất / Tồn phụ tùng</h3>
          <div role="img" aria-label="Biểu đồ nhập và xuất phụ tùng theo tháng">
            <ResponsiveContainer width="100%" height={200}>
              <BarChart data={inventoryChart} margin={{ left: -20 }}>
              <XAxis dataKey="name" tick={{ fontSize: 12, fill: "#64748b" }} axisLine={false} tickLine={false} />
              <YAxis tick={{ fontSize: 11, fill: "#64748b" }} axisLine={false} tickLine={false} />
              <Tooltip contentStyle={{ borderRadius: 8, border: "1px solid #dde3ec", fontSize: 12 }} />
              <Legend wrapperStyle={{ fontSize: 11 }} />
              <Bar dataKey="nhap" name="Nhập" fill="#10b981" radius={[4, 4, 0, 0]} />
              <Bar dataKey="xuat" name="Xuất" fill="#f59e0b" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>

        <Card className="p-5">
          <h3 className="mb-4 text-base font-semibold text-slate-900">Hiệu suất kỹ thuật viên</h3>
          <div className="overflow-x-auto">
            <table className="w-full data-table">
            <thead>
              <tr>
                <th>Kỹ thuật viên</th>
                <th className="text-right">Hoàn tất</th>
                <th className="text-right">Giờ làm</th>
                <th className="text-right">Doanh thu</th>
                <th className="text-center">Đánh giá</th>
              </tr>
            </thead>
            <tbody>
              {techStats.map((t, i) => (
                <tr key={i}>
                  <td>
                    <div className="flex items-center gap-2">
                      <div className="w-7 h-7 rounded-full bg-[#e8eef7] flex items-center justify-center text-[#1e3a6e] text-xs font-bold">
                        {t.name.charAt(0)}
                      </div>
                      <span className="font-medium text-slate-700 text-sm">{t.name}</span>
                    </div>
                  </td>
                  <td className="text-right font-semibold">{t.completed}</td>
                  <td className="text-right text-slate-600">{t.hours}h</td>
                  <td className="text-right font-mono text-sm">{(t.revenue / 1000000).toFixed(1)}M</td>
                  <td className="text-center">
                    <span className="text-amber-500 font-bold text-sm">★ {t.rating}</span>
                  </td>
                </tr>
              ))}
            </tbody>
            </table>
          </div>
        </Card>
      </div>
    </div>
  );
}
