import { useCallback, useEffect, useState } from "react"
import {
  toVehiclePayload,
  vehicleErrorMessage,
  vehiclesApi,
  type Vehicle,
  type VehicleFormValue,
} from "../../api/vehicles"

export type { VehicleFormValue }

// Mã hiển thị kiểu KH001, vẫn được CustomerPortal dùng cho các màn hình còn dữ liệu mẫu.
export function toCustomerKey(customerId: number) {
  return `KH${String(customerId).padStart(3, "0")}`
}

/** Xe của khách hàng đang đăng nhập, lấy từ backend (bảng Xe trong SQL Server). */
export function useCustomerVehicles(customerId: number) {
  const [vehicles, setVehicles] = useState<Vehicle[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")

  const reload = useCallback(async () => {
    if (!customerId) {
      setVehicles([])
      setLoading(false)
      return
    }
    setLoading(true)
    setError("")
    try {
      setVehicles(await vehiclesApi.listByCustomer(customerId))
    } catch (loadError) {
      setError(vehicleErrorMessage(loadError, "Không thể tải danh sách xe."))
    } finally {
      setLoading(false)
    }
  }, [customerId])

  useEffect(() => {
    void reload()
  }, [reload])

  const addVehicle = useCallback(
    async (value: VehicleFormValue): Promise<Vehicle> => {
      if (!customerId) {
        throw new Error("Tài khoản chưa liên kết với khách hàng nên không thể thêm xe.")
      }
      try {
        const created = await vehiclesApi.create(toVehiclePayload(customerId, value))
        setVehicles((current) => [created, ...current])
        return created
      } catch (saveError) {
        throw new Error(vehicleErrorMessage(saveError, "Không thể thêm xe. Vui lòng thử lại."))
      }
    },
    [customerId],
  )

  return { vehicles, loading, error, reload, addVehicle }
}
