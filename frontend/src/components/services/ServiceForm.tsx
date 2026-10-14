import { useState, type FormEvent } from "react"
import { errorMessage } from "../../api/client"
import { garageApi } from "../../api/garage"
import type { GarageService } from "../../types/garage"
import { Button, Input, Textarea } from "../ui"

export default function ServiceForm({
  service,
  onSaved,
  onCancel,
  onBusyChange,
}: {
  service: GarageService | null
  onSaved: (service: GarageService) => void
  onCancel: () => void
  onBusyChange: (busy: boolean) => void
}) {
  const [name, setName] = useState(service?.name ?? "")
  const [type, setType] = useState(service?.type ?? "")
  const [price, setPrice] = useState(service?.unitPrice.toString() ?? "")
  const [description, setDescription] = useState(service?.description ?? "")
  const [error, setError] = useState("")
  const [saving, setSaving] = useState(false)

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    if (saving) return
    if (
      !name.trim() ||
      !price.trim() ||
      !Number.isFinite(Number(price)) ||
      Number(price) < 0
    ) {
      setError("Vui lòng nhập tên dịch vụ và đơn giá hợp lệ.")
      return
    }
    setSaving(true)
    onBusyChange(true)
    setError("")
    try {
      const request = {
        name: name.trim(),
        type: type.trim() || null,
        unitPrice: Number(price),
        description: description.trim() || null,
      }
      const saved = service
        ? await garageApi.updateService(service.id, request)
        : await garageApi.createService(request)
      onSaved(saved)
    } catch (reason) {
      setError(
        errorMessage(reason, "Không lưu được dịch vụ. Vui lòng thử lại."),
      )
    } finally {
      setSaving(false)
      onBusyChange(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5" aria-busy={saving}>
      <fieldset disabled={saving} className="space-y-4">
        <Input
          label="Tên dịch vụ"
          required
          maxLength={150}
          value={name}
          onChange={(event) => setName(event.target.value)}
          autoFocus
        />
        <Input
          label="Nhóm dịch vụ"
          maxLength={100}
          value={type}
          onChange={(event) => setType(event.target.value)}
          placeholder="Ví dụ: Bảo dưỡng"
        />
        <Input
          label="Đơn giá (VNĐ)"
          type="number"
          required
          min="0"
          max="9999999999999999.99"
          step="0.01"
          value={price}
          onChange={(event) => setPrice(event.target.value)}
        />
        <Textarea
          label="Mô tả"
          maxLength={500}
          value={description}
          onChange={(event) => setDescription(event.target.value)}
        />
      </fieldset>
      {error && (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      )}
      <div className="flex flex-wrap justify-end gap-3 border-t border-border pt-4">
        <Button
          type="button"
          variant="outline"
          disabled={saving}
          onClick={onCancel}
        >
          Hủy
        </Button>
        <Button type="submit" disabled={saving}>
          {saving ? "Đang lưu..." : "Lưu dịch vụ"}
        </Button>
      </div>
    </form>
  )
}
