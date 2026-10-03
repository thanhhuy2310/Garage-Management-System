import { useState } from "react"
import { garageApi } from "../../api/garage"
import { useGarageQuery } from "../../hooks/useGarageQuery"
import { formatGarageDate, repairStatusLabel } from "../../utils/garageFormat"
import { QueryState } from "../garage/QueryState"
import { Button, Card, SearchBox, Select } from "../ui"
import RepairOrderDetails from "./RepairOrderDetails"
import RepairStatusBadge from "./RepairStatusBadge"

export default function RepairOrderWorkspace({
  canAssign = false,
  technician = false,
}: {
  canAssign?: boolean
  technician?: boolean
}) {
  const query = useGarageQuery(garageApi.repairOrders)
  const [search, setSearch] = useState("")
  const [status, setStatus] = useState("")
  const [selectedId, setSelectedId] = useState<number | null>(null)
  const orders = query.data ?? []
  const statuses = [...new Set(orders.map((order) => order.status))]
  const keyword = search.trim().toLocaleLowerCase("vi")
  const filtered = orders.filter(
    (order) =>
      (!status || order.status === status) &&
      `${order.id} ${order.licensePlate} ${order.customerName}`
        .toLocaleLowerCase("vi")
        .includes(keyword),
  )

  if (selectedId !== null) {
    return (
      <div className="mx-auto max-w-6xl">
        <RepairOrderDetails
          key={selectedId}
          orderId={selectedId}
          canAssign={canAssign}
          onBack={() => {
            setSelectedId(null)
            query.reload()
          }}
        />
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-6xl space-y-5">
      <div>
        <h2 className="text-xl font-bold text-foreground">
          {technician ? "Công việc được phân công" : "Danh sách phiếu sửa chữa"}
        </h2>
        <p className="mt-1 text-sm text-muted-foreground">
          {technician
            ? "Xem xe, yêu cầu sửa chữa và nội dung phân công của bạn."
            : "Chọn phiếu để xem chi tiết xe, dịch vụ và kỹ thuật viên phụ trách."}
        </p>
      </div>
      <Card className="space-y-4 p-4 sm:p-5">
        <div className="grid gap-3 sm:grid-cols-[1fr_220px_auto] sm:items-end">
          <SearchBox
            value={search}
            onChange={setSearch}
            placeholder="Tìm mã phiếu, biển số, khách hàng..."
          />
          <Select
            label="Trạng thái"
            value={status}
            onChange={(event) => setStatus(event.target.value)}
            options={[
              { value: "", label: "Tất cả trạng thái" },
              ...statuses.map((value) => ({
                value,
                label: repairStatusLabel(value),
              })),
            ]}
          />
          <Button
            variant="outline"
            disabled={query.loading}
            onClick={query.reload}
          >
            Làm mới
          </Button>
        </div>
        {!query.loading && !query.error && (
          <p className="text-sm text-muted-foreground">
            {filtered.length} phiếu sửa chữa
          </p>
        )}
      </Card>
      <QueryState
        loading={query.loading}
        error={query.error}
        onRetry={query.reload}
      />
      {!query.loading &&
        !query.error &&
        (filtered.length ? (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {filtered.map((order) => (
              <Card key={order.id} className="flex flex-col p-5">
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <span className="text-xs text-muted-foreground">
                    Phiếu #{order.id}
                  </span>
                  <RepairStatusBadge status={order.status} />
                </div>
                <h3 className="mt-4 text-xl font-bold">{order.licensePlate}</h3>
                <p className="mt-1 text-sm text-muted-foreground">
                  {[order.brand, order.model].filter(Boolean).join(" ") ||
                    "Chưa có thông tin dòng xe"}
                </p>
                <p className="mt-4 break-words text-sm font-medium">
                  {order.customerName}
                </p>
                <p className="mt-1 mb-5 text-xs text-muted-foreground">
                  Ngày lập: {formatGarageDate(order.createdAt)}
                </p>
                <Button
                  variant="outline"
                  className="mt-auto w-full"
                  aria-label={`Xem phiếu #${order.id} · ${order.licensePlate}`}
                  onClick={() => setSelectedId(order.id)}
                >
                  {canAssign ? "Chi tiết & phân công" : "Xem chi tiết"}
                </Button>
              </Card>
            ))}
          </div>
        ) : (
          <Card className="p-10 text-center text-muted-foreground">
            {orders.length
              ? "Không tìm thấy phiếu phù hợp."
              : technician
                ? "Bạn chưa có công việc được phân công."
                : "Chưa có phiếu sửa chữa."}
          </Card>
        ))}
    </div>
  )
}
