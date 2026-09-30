import { useState } from "react"
import { Button, Card, Icons } from "../../components/ui"
import AddVehicleModal from "../../features/vehicles/AddVehicleModal"
import VehicleCard from "../../features/vehicles/VehicleCard"
import { useCustomerVehicles } from "../../features/vehicles/customerVehicleRepository"

export default function CustomerVehicles({
  customerId,
}: {
  customerId: number
}) {
  const { vehicles, loading, error, reload, addVehicle } =
    useCustomerVehicles(customerId)
  const [showAdd, setShowAdd] = useState(false)
  const [success, setSuccess] = useState("")

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <div>
          <h1 className="ui-section-title text-left">Xe của tôi</h1>
          <p className="ui-secondary-text mt-1 text-sm">
            Quản lý thông tin các xe của bạn.
          </p>
        </div>
        <Button icon={Icons.plus} onClick={() => setShowAdd(true)}>
          Thêm xe
        </Button>
      </div>

      {success && (
        <p
          className="rounded-md bg-success-soft px-4 py-3 text-sm text-success"
          role="status"
        >
          {success}
        </p>
      )}

      {error && (
        <div
          className="flex flex-col gap-3 rounded-md bg-danger-soft px-4 py-3 text-sm text-danger sm:flex-row sm:items-center sm:justify-between"
          role="alert"
        >
          <span>{error}</span>
          <Button size="sm" variant="outline" onClick={() => void reload()}>
            Thử lại
          </Button>
        </div>
      )}

      {loading ? (
        <Card className="p-6 text-center text-sm text-muted-foreground">
          Đang tải danh sách xe...
        </Card>
      ) : vehicles.length === 0 && !error ? (
        <Card className="flex min-h-72 items-center justify-center p-6 text-center">
          <div className="max-w-sm">
            <span
              className="mx-auto flex h-14 w-14 items-center justify-center rounded-full bg-primary-soft text-primary"
              aria-hidden="true"
            >
              {Icons.car}
            </span>
            <h2 className="mt-4 text-lg font-bold text-foreground">
              Bạn chưa có xe nào
            </h2>
            <p className="mt-2 text-sm leading-6 text-muted-foreground">
              Thêm thông tin xe để sử dụng khi đặt lịch sửa chữa hoặc bảo dưỡng.
            </p>
            <Button
              className="mt-5"
              icon={Icons.plus}
              onClick={() => setShowAdd(true)}
            >
              Thêm xe
            </Button>
          </div>
        </Card>
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
          {vehicles.map((vehicle) => (
            <VehicleCard key={vehicle.id} vehicle={vehicle} />
          ))}
        </div>
      )}

      <AddVehicleModal
        open={showAdd}
        onClose={() => setShowAdd(false)}
        onSubmit={addVehicle}
        onCreated={() => setSuccess("Đã thêm xe.")}
      />
    </div>
  )
}
