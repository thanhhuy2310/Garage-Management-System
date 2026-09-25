import type { Xe } from "../../mock/data"
import { Modal } from "../../components/ui"
import type { VehicleFormValue } from "./customerVehicleRepository"
import VehicleForm from "./VehicleForm"

interface AddVehicleModalProps {
  open: boolean
  onClose: () => void
  onSubmit: (value: VehicleFormValue) => Xe
  onCreated: (vehicle: Xe) => void
}

export default function AddVehicleModal({
  open,
  onClose,
  onSubmit,
  onCreated,
}: AddVehicleModalProps) {
  const handleSubmit = (value: VehicleFormValue) => {
    const vehicle = onSubmit(value)
    onCreated(vehicle)
    onClose()
  }

  return (
    <Modal open={open} onClose={onClose} title="Thêm xe mới" width="max-w-xl">
      {open && <VehicleForm onSubmit={handleSubmit} onCancel={onClose} />}
    </Modal>
  )
}
