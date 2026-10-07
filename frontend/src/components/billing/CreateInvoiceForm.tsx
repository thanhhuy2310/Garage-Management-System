import { useState } from "react"
import { billingApi } from "../../api/billing"
import { garageApi } from "../../api/garage"
import { errorMessage } from "../../api/client"
import { useGarageQuery } from "../../hooks/useGarageQuery"
import type { InvoiceDetail, InvoiceSummary } from "../../types/billing"
import { QueryState } from "../garage/QueryState"
import { Button, Select } from "../ui"

export default function CreateInvoiceForm({
  invoices,
  onSaved,
  onBusyChange,
}: {
  invoices: InvoiceSummary[]
  onSaved: (value: InvoiceDetail) => void
  onBusyChange: (busy: boolean) => void
}) {
  const query = useGarageQuery(garageApi.repairOrders)
  const [id, setId] = useState("")
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState("")
  const available = (query.data ?? []).filter(
    (o) =>
      o.status === "HOAN_TAT" &&
      !invoices.some((i) => i.repairOrderId === o.id),
  )
  async function submit(event: React.FormEvent) {
    event.preventDefault()
    if (busy) return
    setBusy(true)
    onBusyChange(true)
    setError("")
    try {
      onSaved(await billingApi.create(Number(id)))
    } catch (reason) {
      setError(errorMessage(reason))
    } finally {
      setBusy(false)
      onBusyChange(false)
    }
  }
  return (
    <form onSubmit={submit} className="space-y-5">
      <QueryState
        loading={query.loading}
        error={query.error}
        onRetry={query.reload}
      />
      <Select
        label="Phiếu sửa chữa đã hoàn tất"
        required
        value={id}
        disabled={busy}
        options={[
          { value: "", label: "Chọn phiếu sửa chữa" },
          ...available.map((o) => ({
            value: String(o.id),
            label: `#${o.id} · ${o.licensePlate} · ${o.customerName}`,
          })),
        ]}
        onChange={(e) => setId(e.target.value)}
      />
      {!query.loading && !query.error && !available.length && (
        <p className="text-sm text-muted-foreground">
          Không có phiếu hoàn tất chờ lập hóa đơn.
        </p>
      )}
      <p className="text-sm text-muted-foreground">
        Tổng tiền được tính theo dịch vụ và phụ tùng đã ghi trên phiếu sửa chữa.
      </p>
      {error && (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      )}
      <Button type="submit" disabled={busy || !id}>
        {busy ? "Đang lập..." : "Lập hóa đơn"}
      </Button>
    </form>
  )
}
