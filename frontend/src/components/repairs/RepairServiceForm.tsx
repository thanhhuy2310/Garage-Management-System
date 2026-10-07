import { useState } from "react"
import { garageApi } from "../../api/garage"
import { errorMessage } from "../../api/client"
import { useGarageQuery } from "../../hooks/useGarageQuery"
import type { RepairOrderDetail } from "../../types/garage"
import { formatMoney } from "../../utils/garageFormat"
import { QueryState } from "../garage/QueryState"
import { Button, Input, Select } from "../ui"

export default function RepairServiceForm({
  detail,
  onSaved,
  onCancel,
  onBusyChange,
}: {
  detail?: RepairOrderDetail
  onSaved: (value: RepairOrderDetail) => void
  onCancel: () => void
  onBusyChange: (busy: boolean) => void
}) {
  const services = useGarageQuery(garageApi.services)
  const receptions = useGarageQuery(garageApi.receptions)
  const [serviceId, setServiceId] = useState("")
  const [receptionId, setReceptionId] = useState("")
  const [quantity, setQuantity] = useState("1")
  const [error, setError] = useState("")
  const [busy, setBusy] = useState(false)
  const options = (services.data ?? []).filter(
    (s) => !detail?.services.some((line) => line.id === s.id),
  )
  async function submit(event: React.FormEvent) {
    event.preventDefault()
    if (busy) return
    setBusy(true)
    onBusyChange(true)
    setError("")
    const line = { serviceId: Number(serviceId), quantity: Number(quantity) }
    try {
      onSaved(
        detail
          ? await garageApi.addRepairService(detail.order.id, line)
          : await garageApi.createRepair({
              receptionId: Number(receptionId),
              services: [line],
            }),
      )
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
        loading={services.loading}
        error={services.error}
        onRetry={services.reload}
      />
      {!detail && (
        <>
          <QueryState
            loading={receptions.loading}
            error={receptions.error}
            onRetry={receptions.reload}
          />
          <Select
            label="Phiếu tiếp nhận"
            required
            value={receptionId}
            disabled={busy}
            onChange={(e) => setReceptionId(e.target.value)}
            options={[
              { value: "", label: "Chọn xe đã tiếp nhận" },
              ...(receptions.data ?? []).map((r) => ({
                value: String(r.id),
                label: `#${r.id} · ${r.licensePlate} · ${r.customerName}`,
              })),
            ]}
          />
          {receptions.data?.length === 0 && (
            <p className="text-sm text-muted-foreground">
              Chưa có phiếu tiếp nhận chờ lập phiếu sửa chữa.
            </p>
          )}
        </>
      )}
      <Select
        label="Dịch vụ"
        required
        value={serviceId}
        disabled={busy}
        onChange={(e) => setServiceId(e.target.value)}
        options={[
          { value: "", label: "Chọn dịch vụ" },
          ...options.map((s) => ({
            value: String(s.id),
            label: `${s.name} · ${formatMoney(s.unitPrice)}`,
          })),
        ]}
      />
      <Input
        label="Số lượng"
        required
        min={1}
        max={1000}
        step={1}
        type="number"
        value={quantity}
        disabled={busy}
        onChange={(e) => setQuantity(e.target.value)}
      />
      {error && (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      )}
      <div className="flex justify-end gap-3">
        <Button
          variant="outline"
          type="button"
          disabled={busy}
          onClick={onCancel}
        >
          Hủy
        </Button>
        <Button
          type="submit"
          disabled={busy || !serviceId || (!detail && !receptionId)}
        >
          {busy ? "Đang lưu..." : detail ? "Thêm dịch vụ" : "Lập phiếu"}
        </Button>
      </div>
    </form>
  )
}
