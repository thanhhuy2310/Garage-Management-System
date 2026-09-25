import { FormEvent, useState } from "react"
import { Button, Input } from "../../components/ui"
import type { VehicleFormValue } from "./customerVehicleRepository"

interface VehicleFormProps {
  onSubmit: (value: VehicleFormValue) => void | Promise<void>
  onCancel: () => void
}

export default function VehicleForm({ onSubmit, onCancel }: VehicleFormProps) {
  const [plate, setPlate] = useState("")
  const [brand, setBrand] = useState("")
  const [model, setModel] = useState("")
  const [year, setYear] = useState("")
  const [mileage, setMileage] = useState("")
  const [error, setError] = useState("")
  const [saving, setSaving] = useState(false)

  const handleSubmit = async (event: FormEvent) => {
    event.preventDefault()
    setError("")
    const normalizedPlate = plate.trim()
    const parsedYear = year ? Number(year) : null
    const parsedMileage = mileage ? Number(mileage) : null
    const maxYear = new Date().getFullYear() + 1

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
          : "Không thể thêm xe. Vui lòng thử lại.",
      )
    } finally {
      setSaving(false)
    }
  }

  return (
    <form className="space-y-4" onSubmit={handleSubmit}>
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
          {saving ? "Đang thêm..." : "Thêm xe"}
        </Button>
      </div>
    </form>
  )
}
