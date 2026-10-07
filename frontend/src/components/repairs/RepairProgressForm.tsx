import { useState } from "react"
import { garageApi } from "../../api/garage"
import { errorMessage } from "../../api/client"
import type { RepairOrderDetail } from "../../types/garage"
import { repairStatusLabel } from "../../utils/garageFormat"
import { Button, Select, Textarea } from "../ui"

export const nextRepairStates: Record<string, string[]> = {
  MOI_TAO: ["DANG_KIEM_TRA", "CHO_SUA", "DANG_SUA"],
  DANG_KIEM_TRA: ["CHO_SUA", "DANG_SUA"],
  CHO_SUA: ["DANG_SUA"],
  DANG_SUA: ["CHO_PHU_TUNG", "HOAN_TAT"],
  CHO_PHU_TUNG: ["DANG_SUA"],
}

export function nextServiceStates(status: string | null) {
  if ([null, "CHO_SUA", "MOI_TAO", "CHUA_THUC_HIEN"].includes(status))
    return ["DANG_SUA"]
  return status === "DANG_SUA" ? ["HOAN_TAT"] : []
}

export default function RepairProgressForm({
  detail,
  serviceId,
  onSaved,
  onCancel,
  onBusyChange,
}: {
  detail: RepairOrderDetail
  serviceId?: number
  onSaved: (value: RepairOrderDetail) => void
  onCancel: () => void
  onBusyChange: (busy: boolean) => void
}) {
  const service = detail.services.find((line) => line.id === serviceId)
  const current = serviceId
    ? (service?.status ?? "CHO_SUA")
    : detail.order.status
  const choices = serviceId
    ? nextServiceStates(current)
    : (nextRepairStates[current] ?? [])
  const [status, setStatus] = useState(choices[0] ?? "")
  const [notes, setNotes] = useState("")
  const [error, setError] = useState("")
  const [busy, setBusy] = useState(false)
  async function submit(event: React.FormEvent) {
    event.preventDefault()
    if (busy) return
    if (!notes.trim()) {
      setError("Vui lòng nhập nội dung cập nhật.")
      return
    }
    setBusy(true)
    onBusyChange(true)
    setError("")
    try {
      onSaved(
        await garageApi.updateProgress(
          detail.order.id,
          { status, expectedStatus: current, notes: notes.trim() },
          serviceId,
        ),
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
      <p className="text-sm text-muted-foreground">
        {service?.name ?? `Phiếu #${detail.order.id}`} · Hiện tại:{" "}
        {repairStatusLabel(current)}
      </p>
      <Select
        label="Chuyển trạng thái"
        value={status}
        disabled={busy}
        onChange={(e) => setStatus(e.target.value)}
        options={choices.map((value) => ({
          value,
          label: repairStatusLabel(value),
        }))}
      />
      <Textarea
        label={
          status === "HOAN_TAT" && !serviceId
            ? "Kết quả sửa chữa"
            : "Nội dung cập nhật"
        }
        required
        maxLength={1000}
        value={notes}
        disabled={busy}
        onChange={(e) => setNotes(e.target.value)}
        helperText="Nội dung này được lưu vào lịch sử tiến độ để khách hàng theo dõi."
      />
      {error && (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      )}
      <div className="flex flex-wrap justify-end gap-3">
        <Button
          variant="outline"
          type="button"
          disabled={busy}
          onClick={onCancel}
        >
          Hủy
        </Button>
        <Button type="submit" disabled={busy || !status}>
          {busy ? "Đang lưu..." : "Lưu tiến độ"}
        </Button>
      </div>
    </form>
  )
}
