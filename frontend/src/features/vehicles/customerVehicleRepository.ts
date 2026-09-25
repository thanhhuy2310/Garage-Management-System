import { useCallback, useEffect, useState } from "react"
import { xe, type Xe } from "../../mock/data"

const STORAGE_KEY = "garage:customer-vehicles:v1"
const CHANGE_EVENT = "garage:customer-vehicles-changed"

export interface VehicleFormValue {
  plate: string
  brand: string
  model: string
  year: number | null
  mileage: number | null
}

export function toCustomerKey(customerId: number) {
  return `KH${String(customerId).padStart(3, "0")}`
}

function readStoredVehicles(): Xe[] {
  try {
    const value = window.localStorage.getItem(STORAGE_KEY)
    return value ? JSON.parse(value) as Xe[] : []
  } catch {
    return []
  }
}

function writeStoredVehicles(vehicles: Xe[]) {
  window.localStorage.setItem(STORAGE_KEY, JSON.stringify(vehicles))
  window.dispatchEvent(new Event(CHANGE_EVENT))
}

export function listCustomerVehicles(customerKey: string): Xe[] {
  return [...xe, ...readStoredVehicles()].filter(
    (vehicle) => vehicle.MaKhachHang === customerKey,
  )
}

function createVehicle(customerKey: string, value: VehicleFormValue): Xe {
  const plate = value.plate.trim().toUpperCase()
  const allVehicles = [...xe, ...readStoredVehicles()]
  if (allVehicles.some((vehicle) => vehicle.BienSo.toUpperCase() === plate)) {
    throw new Error("Biển số xe đã tồn tại.")
  }

  const vehicle: Xe = {
    MaXe: `XE-LOCAL-${Date.now()}`,
    MaKhachHang: customerKey,
    BienSo: plate,
    HangXe: value.brand.trim() || null,
    DongXe: value.model.trim() || null,
    NamSanXuat: value.year,
    SoKm: value.mileage,
  }

  // TODO: Replace this local persistence with the customer-scoped Vehicle API when it is available.
  writeStoredVehicles([...readStoredVehicles(), vehicle])
  return vehicle
}

export function useCustomerVehicles(customerKey: string) {
  const [vehicles, setVehicles] = useState<Xe[]>(() =>
    listCustomerVehicles(customerKey),
  )

  const refresh = useCallback(() => {
    setVehicles(listCustomerVehicles(customerKey))
  }, [customerKey])

  useEffect(() => {
    refresh()
    window.addEventListener(CHANGE_EVENT, refresh)
    window.addEventListener("storage", refresh)
    return () => {
      window.removeEventListener(CHANGE_EVENT, refresh)
      window.removeEventListener("storage", refresh)
    }
  }, [refresh])

  const addVehicle = useCallback(
    (value: VehicleFormValue) => {
      const vehicle = createVehicle(customerKey, value)
      setVehicles(listCustomerVehicles(customerKey))
      return vehicle
    },
    [customerKey],
  )

  return { vehicles, addVehicle }
}
