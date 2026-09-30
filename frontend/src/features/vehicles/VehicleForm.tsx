import { FormEvent, useState } from "react"
import { Button, Input, Select } from "../../components/ui"
import type { VehicleFormValue } from "../../api/vehicles"

export interface CustomerOption {
  value: number
  label: string
}

interface VehicleFormProps {
  onSubmit: (value: VehicleFormValue) => void | Promise<void>
  onCancel: () => void
  initialValue?: VehicleFormValue
  /** Khi có danh sách khách hàng, form hiển thị ô chọn chủ xe (dùng cho nhân viên). */
  customerOptions?: CustomerOption[]
  lockCustomer?: boolean
  submitLabel?: string
  savingLabel?: string
}

export default function VehicleForm({
  onSubmit,
  onCancel,
  initialValue,
  customerOptions,
  lockCustomer = false,
  submitLabel = "Thêm xe",
  savingLabel = "Đang lưu...",
}: VehicleFormProps) {
  const [customerId, setCustomerId] = useState(initialValue?.customerId?.toString() ?? "")
  const [plate, setPlate] = useState(initialValue?.plate ?? "")
  const [brand, setBrand] = useState(initialValue?.brand ?? "")
  const [model, setModel] = useState(initialValue?.model ?? "")
  const [year, setYear] = useState(initialValue?.year?.toString() ?? "")
  const [mileage, setMileage] = useState(initialValue?.mileage?.toString() ?? "")
  const [error, setError] = useState("")
  const [saving, setSaving] = useState(false)

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError("")
    const normalizedPlate = plate.trim()
    const parsedYear = year ? Number(year) : null
    const parsedMileage = mileage ? Number(mileage) : null
    const maxYear = new Date().getFullYear() + 1

    if (customerOptions && !customerId) {
      setError("Vui lòng chọn chủ xe.")
      return
    }
    if (!normalizedPlate) {
      setError("Vui lòng nhập biển số xe.")
      return
    }
    if (
      parsedYear !== null &&
      (!Number.isInteger(parsedYear) ||
        parsedYear < 1886 ||
        parsedYear > maxYear)
    ) {
      setError(`Năm sản xuất phải từ 1886 đến ${maxYear}.`)
      return
    }
    if (
      parsedMileage !== null &&
      (!Number.isInteger(parsedMileage) || parsedMileage < 0)
    ) {
      setError("Số km phải là số nguyên không âm.")
      return
    }

    setSaving(true)
    try {
      await onSubmit({
        customerId: customerId ? Number(customerId) : null,
        plate: normalizedPlate,
        brand,
        model,
        year: parsedYear,
        mileage: parsedMileage,
      })
    } catch (submitError) {
      setError(
        submitError instanceof Error
          ? submitError.message
          : "Không thể lưu xe. Vui lòng thử lại.",
      )
    } finally {
      setSaving(false)
    }
  }

  return (
    <form className="space-y-4" onSubmit={handleSubmit}>
      {customerOptions && (
        <Select
          label="Chủ xe *"
          value={customerId}
          onChange={(event) => setCustomerId(event.target.value)}
          disabled={lockCustomer}
          helperText={lockCustomer ? "Không thể đổi chủ xe vì xe có thể đã gắn với lịch hẹn và phiếu tiếp nhận." : undefined}
          options={[
            { value: "", label: "— Chọn khách hàng —" },
            ...customerOptions.map((option) => ({ value: String(option.value), label: option.label })),
          ]}
        />
      )}
      <Input
        label="Biển số xe *"
        value={plate}
        onChange={(event) => setPlate(event.target.value)}
        placeholder="51A-123.45"
        maxLength={20}
        autoFocus
        required
      />
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <Input
          label="Hãng xe"
          value={brand}
          onChange={(event) => setBrand(event.target.value)}
          placeholder="Toyota"
          maxLength={100}
        />
        <Input
          label="Dòng xe"
          value={model}
          onChange={(event) => setModel(event.target.value)}
          placeholder="Vios"
          maxLength={100}
        />
        <Input
          label="Năm sản xuất"
          type="number"
          inputMode="numeric"
          value={year}
          onChange={(event) => setYear(event.target.value)}
          min={1886}
          max={new Date().getFullYear() + 1}
        />
        <Input
          label="Số km"
          type="number"
          inputMode="numeric"
          value={mileage}
          onChange={(event) => setMileage(event.target.value)}
          min={0}
        />
      </div>
      <p className="text-xs leading-5 text-muted-foreground">
        Hãng xe, dòng xe, năm sản xuất và số km có thể cập nhật sau.
      </p>
      {error && (
        <p
          className="rounded-md bg-danger-soft px-3 py-2 text-sm text-danger"
          role="alert"
        >
          {error}
        </p>
      )}
      <div className="flex flex-col-reverse gap-2 pt-2 sm:flex-row sm:justify-end">
        <Button
          type="button"
          variant="outline"
          onClick={onCancel}
          disabled={saving}
        >
          Hủy
        </Button>
        <Button type="submit" disabled={saving}>
          {saving ? savingLabel : submitLabel}
        </Button>
      </div>
    </form>
  )
}
