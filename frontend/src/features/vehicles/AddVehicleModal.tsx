import { Modal } from "../../components/ui"
import type { Vehicle, VehicleFormValue } from "../../api/vehicles"
import VehicleForm from "./VehicleForm"

interface AddVehicleModalProps {
  open: boolean
  onClose: () => void
  onSubmit: (value: VehicleFormValue) => Promise<Vehicle>
  onCreated: (vehicle: Vehicle) => void
}

export default function AddVehicleModal({
  open,
  onClose,
  onSubmit,
  onCreated,
}: AddVehicleModalProps) {
  const handleSubmit = async (value: VehicleFormValue) => {
    // Nếu API lỗi, onSubmit ném Error và VehicleForm hiển thị message; modal vẫn mở.
    const vehicle = await onSubmit(value)
    onCreated(vehicle)
    onClose()
  }

  return (
    <Modal open={open} onClose={onClose} title="Thêm xe mới" width="max-w-xl">
      {open && (
        <VehicleForm
          onSubmit={handleSubmit}
          onCancel={onClose}
          submitLabel="Thêm xe"
          savingLabel="Đang thêm..."
        />
      )}
    </Modal>
  )
}
