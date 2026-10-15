import { useCallback, useEffect, useMemo, useState } from "react"
import {
  Area,
  AreaChart,
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts"
import { errorMessage } from "../api/client"
import { reportsApi } from "../api/reports"
import {
  Button,
  Card,
  EmptyState,
  Icons,
  StatCard,
  TableContainer,
} from "../components/ui"
import type { ReportOverview } from "../types/reports"
import { formatMoney } from "../utils/garageFormat"

const COLORS = ["#153A5B", "#E67817", "#047857", "#7C3AED", "#B45309", "#64748B"]
const STATUS_LABELS: Record<string, string> = {
  MOI_TAO: "Mới tạo",
  DANG_KIEM_TRA: "Đang kiểm tra",
  CHO_SUA: "Chờ sửa",
  DANG_SUA: "Đang sửa",
  CHO_PHU_TUNG: "Chờ phụ tùng",
  HOAN_TAT: "Hoàn tất",
  HUY: "Đã hủy",
  DA_HUY: "Đã hủy",
}

type Preset = "month" | "quarter" | "year"

function dateValue(date: Date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, "0")
  const day = String(date.getDate()).padStart(2, "0")
  return `${year}-${month}-${day}`
}

function presetRange(preset: Preset) {
  const now = new Date()
  const firstMonth = preset === "month"
    ? now.getMonth()
    : preset === "quarter"
      ? Math.floor(now.getMonth() / 3) * 3
      : 0
  return {
    from: dateValue(new Date(now.getFullYear(), firstMonth, 1)),
    to: dateValue(now),
  }
}

function number(value: number) {
  return new Intl.NumberFormat("vi-VN", { maximumFractionDigits: 2 }).format(value)
}

function monthLabel(value: string) {
  const [year, month] = value.split("-")
  return `T${Number(month)}/${year}`
}

export default function Reports() {
  const initial = presetRange("year")
  const [preset, setPreset] = useState<Preset | null>("year")
  const [from, setFrom] = useState(initial.from)
  const [to, setTo] = useState(initial.to)
  const [data, setData] = useState<ReportOverview | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")

  const load = useCallback((signal?: AbortSignal) => {
    setLoading(true)
    setError("")
    reportsApi.overview(from, to, signal)
      .then((result) => {
        if (!signal?.aborted) setData(result)
      })
      .catch((reason) => {
        if (signal?.aborted || (reason instanceof DOMException && reason.name === "AbortError")) return
        setError(errorMessage(reason, "Không thể tải số liệu báo cáo."))
      })
      .finally(() => {
        if (!signal?.aborted) setLoading(false)
      })
  }, [from, to])

  useEffect(() => {
    const controller = new AbortController()
    load(controller.signal)
    return () => controller.abort()
  }, [load])

  const choosePreset = (next: Preset) => {
    const range = presetRange(next)
    setPreset(next)
    setFrom(range.from)
    setTo(range.to)
  }

  const statusData = useMemo(() => data?.vehicleStatuses.map((item) => ({
    ...item,
    name: STATUS_LABELS[item.status] ?? item.status,
  })) ?? [], [data])

  const exportCsv = () => {
    if (!data) return
    const rows: (string | number)[][] = [
      ["BÁO CÁO GARA", `${data.from} - ${data.to}`],
      ["Chỉ tiêu", "Giá trị"],
      ["Doanh thu đã thu", data.billing.collected],
      ["Giá trị hóa đơn", data.billing.invoiced],
      ["Công nợ đến cuối kỳ", data.billing.outstanding],
      ["Lượt sửa chữa tiếp nhận", data.repairs.opened],
      ["Lượt sửa chữa hoàn tất", data.repairs.completed],
      ["Thời gian xử lý trung bình (giờ)", data.repairs.averageHandlingHours],
      ["Phụ tùng nhập", data.inventory.imported],
      ["Phụ tùng xuất", data.inventory.exported],
      ["Tồn kho hiện tại", data.inventory.currentStock],
      [],
      ["Phụ tùng", "Nhập", "Xuất", "Tồn"],
      ...data.partMovements.map((item) => [
        item.partName,
        item.imported,
        item.exported,
        item.currentStock,
      ]),
    ]
    const csv = rows
      .map((row) => row.map((cell) => `"${String(cell ?? "").replaceAll('"', '""')}"`).join(","))
      .join("\r\n")
    const url = URL.createObjectURL(new Blob(["\uFEFF", csv], { type: "text/csv;charset=utf-8" }))
    const link = document.createElement("a")
    link.href = url
    link.download = `bao-cao-gara-${data.from}-${data.to}.csv`
    link.click()
    URL.revokeObjectURL(url)
  }

  return (
    <div className="space-y-6">
      <div className="page-toolbar gap-4">
        <div className="flex flex-wrap items-end gap-3">
          <div className="flex rounded-lg border border-border bg-surface p-1" aria-label="Khoảng báo cáo nhanh">
            {(["month", "quarter", "year"] as Preset[]).map((item) => (
              <button
                key={item}
                type="button"
                onClick={() => choosePreset(item)}
                aria-pressed={preset === item}
                className={`min-h-10 rounded-md px-3 text-sm font-semibold ${preset === item ? "bg-primary text-white" : "text-muted-foreground hover:bg-muted"}`}
              >
                {item === "month" ? "Tháng" : item === "quarter" ? "Quý" : "Năm"}
              </button>
            ))}
          </div>
          <label className="text-sm font-semibold text-slate-700">
            Từ ngày
            <input
              type="date"
              value={from}
              max={to}
              onChange={(event) => { setPreset(null); setFrom(event.target.value) }}
              className="mt-1 block min-h-11 rounded-md border border-border bg-white px-3 text-sm shadow-sm"
            />
          </label>
          <label className="text-sm font-semibold text-slate-700">
            Đến ngày
            <input
              type="date"
              value={to}
              min={from}
              onChange={(event) => { setPreset(null); setTo(event.target.value) }}
              className="mt-1 block min-h-11 rounded-md border border-border bg-white px-3 text-sm shadow-sm"
            />
          </label>
        </div>
        <Button variant="outline" icon={Icons.download} onClick={exportCsv} disabled={!data || loading}>
          Xuất CSV
        </Button>
      </div>

      {loading && (
        <Card className="p-8 text-center text-sm text-muted-foreground">
          Đang tổng hợp số liệu từ database…
        </Card>
      )}
      {error && (
        <Card className="border-danger/30 bg-danger-soft p-5 text-sm text-danger">
          <div className="flex flex-wrap items-center justify-between gap-3">
            <span>{error}</span>
            <Button variant="outline" onClick={() => load()}>Thử lại</Button>
          </div>
        </Card>
      )}

      {!loading && !error && data && (
        <>
          <p className="text-sm text-muted-foreground">
            Số liệu từ {data.from.split("-").reverse().join("/")} đến {data.to.split("-").reverse().join("/")}.
            Công nợ được tính đến cuối kỳ; tồn kho hiển thị số lượng hiện tại.
          </p>
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-4">
            <StatCard label="Doanh thu đã thu" value={formatMoney(data.billing.collected)} icon={Icons.creditCard} color="green" />
            <StatCard label="Lượt sửa chữa tiếp nhận" value={number(data.repairs.opened)} icon={Icons.wrench} color="blue" />
            <StatCard label="Lượt sửa chữa hoàn tất" value={number(data.repairs.completed)} icon={Icons.checkCircle} color="navy" />
            <StatCard label="Thời gian xử lý trung bình" value={`${number(data.repairs.averageHandlingHours)} giờ`} icon={Icons.history} color="amber" />
          </div>

          <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
            <Card className="p-4 sm:p-5 xl:col-span-2">
              <div className="mb-4 flex flex-wrap items-start justify-between gap-2">
                <div>
                  <h3 className="text-base font-semibold">Hóa đơn và doanh thu</h3>
                  <p className="text-xs text-muted-foreground">Doanh thu ghi nhận theo ngày thanh toán thực tế</p>
                </div>
                <div className="text-right text-xs text-muted-foreground">
                  Giá trị hóa đơn: <strong className="text-foreground">{formatMoney(data.billing.invoiced)}</strong><br />
                  Công nợ: <strong className="text-warning">{formatMoney(data.billing.outstanding)}</strong>
                </div>
              </div>
              <ResponsiveContainer width="100%" height={280}>
                <AreaChart data={data.trends} margin={{ left: 8, right: 8 }}>
                  <defs>
                    <linearGradient id="collected-gradient" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#047857" stopOpacity={0.28} />
                      <stop offset="95%" stopColor="#047857" stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                  <XAxis dataKey="period" tickFormatter={monthLabel} tick={{ fontSize: 12 }} />
                  <YAxis tickFormatter={(value) => `${Math.round(value / 1_000_000)}tr`} tick={{ fontSize: 11 }} width={48} />
                  <Tooltip
                    labelFormatter={monthLabel}
                    formatter={(value, name) => [formatMoney(Number(value)), name === "collected" ? "Đã thu" : "Hóa đơn"]}
                  />
                  <Legend formatter={(value) => value === "collected" ? "Đã thu" : "Hóa đơn"} />
                  <Area type="monotone" dataKey="invoiced" stroke="#153A5B" fill="transparent" strokeWidth={2} />
                  <Area type="monotone" dataKey="collected" stroke="#047857" fill="url(#collected-gradient)" strokeWidth={2.5} />
                </AreaChart>
              </ResponsiveContainer>
            </Card>

            <Card className="p-4 sm:p-5">
              <h3 className="text-base font-semibold">Tình trạng xe cuối kỳ</h3>
              <p className="mb-3 text-xs text-muted-foreground">Theo phiếu sửa gần nhất của từng xe đến ngày kết thúc</p>
              {statusData.length ? (
                <>
                  <ResponsiveContainer width="100%" height={190}>
                    <PieChart>
                      <Pie data={statusData} dataKey="count" nameKey="name" innerRadius={48} outerRadius={75} paddingAngle={2}>
                        {statusData.map((item, index) => <Cell key={item.status} fill={COLORS[index % COLORS.length]} />)}
                      </Pie>
                      <Tooltip formatter={(value) => [`${value} xe`, "Số lượng"]} />
                    </PieChart>
                  </ResponsiveContainer>
                  <div className="space-y-2">
                    {statusData.map((item, index) => (
                      <div key={item.status} className="flex items-center justify-between text-sm">
                        <span className="flex items-center gap-2">
                          <span className="h-2.5 w-2.5 rounded-full" style={{ background: COLORS[index % COLORS.length] }} />
                          {item.name}
                        </span>
                        <strong>{item.count}</strong>
                      </div>
                    ))}
                  </div>
                </>
              ) : <EmptyState message="Chưa có xe phát sinh sửa chữa." />}
            </Card>
          </div>

          <div className="grid grid-cols-1 gap-4 xl:grid-cols-3">
            <StatCard label="Phụ tùng nhập trong kỳ" value={number(data.inventory.imported)} icon={Icons.download} color="green" />
            <StatCard label="Phụ tùng xuất trong kỳ" value={number(data.inventory.exported)} icon={Icons.send} color="amber" />
            <StatCard
              label="Tồn kho hiện tại"
              value={number(data.inventory.currentStock)}
              icon={Icons.package}
              color={data.inventory.outOfStockParts ? "red" : "navy"}
              trend={`${data.inventory.lowStockParts} sắp hết · ${data.inventory.outOfStockParts} hết hàng`}
            />
          </div>

          <Card className="p-4 sm:p-5">
            <h3 className="text-base font-semibold">Nhập / xuất / tồn phụ tùng</h3>
            <p className="mb-4 text-xs text-muted-foreground">10 phụ tùng có biến động lớn nhất trong kỳ</p>
            {data.partMovements.length ? (
              <ResponsiveContainer width="100%" height={300}>
                <BarChart data={data.partMovements} margin={{ left: 0, right: 8 }}>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                  <XAxis dataKey="partName" tick={{ fontSize: 11 }} interval={0} angle={-18} textAnchor="end" height={72} />
                  <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="imported" name="Nhập" fill="#047857" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="exported" name="Xuất" fill="#E67817" radius={[4, 4, 0, 0]} />
                  <Bar dataKey="currentStock" name="Tồn" fill="#153A5B" radius={[4, 4, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            ) : <EmptyState message="Chưa có danh mục phụ tùng." />}
          </Card>

          <Card className="p-4 sm:p-5">
            <div className="mb-4 flex flex-wrap items-end justify-between gap-2">
              <div>
                <h3 className="text-base font-semibold">Hiệu suất xử lý của kỹ thuật viên</h3>
                <p className="text-xs text-muted-foreground">Theo các phân công phát sinh trong kỳ</p>
              </div>
              <span className="text-sm text-muted-foreground">
                Tỷ lệ hoàn tất chung: <strong className="text-foreground">{number(data.repairs.completionRate)}%</strong>
              </span>
            </div>
            {data.technicianPerformance.length ? (
              <TableContainer>
                <table className="w-full data-table">
                  <thead><tr><th>Kỹ thuật viên</th><th className="text-right">Được giao</th><th className="text-right">Hoàn tất</th><th className="text-right">Tỷ lệ</th><th className="text-right">Giờ xử lý TB</th></tr></thead>
                  <tbody>
                    {data.technicianPerformance.map((item) => (
                      <tr key={item.employeeId}>
                        <td className="font-medium">{item.employeeName}</td>
                        <td className="text-right">{number(item.assigned)}</td>
                        <td className="text-right font-semibold">{number(item.completed)}</td>
                        <td className="text-right">{number(item.completionRate)}%</td>
                        <td className="text-right">{number(item.averageHandlingHours)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </TableContainer>
            ) : <EmptyState message="Chưa có phân công kỹ thuật viên trong kỳ." />}
          </Card>
        </>
      )}
    </div>
  )
}
