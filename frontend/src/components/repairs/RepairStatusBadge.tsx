import { repairStatusLabel } from "../../utils/garageFormat"
import { Badge } from "../ui"

export default function RepairStatusBadge({
  status,
}: {
  status: string | null
}) {
  const variant =
    status === "HOAN_TAT"
      ? "completed"
      : status === "DANG_SUA"
        ? "in_progress"
        : status === "CHO_PHU_TUNG"
          ? "waiting_parts"
          : status === "HUY" || status === "DA_HUY"
            ? "cancelled"
            : "gray"
  return <Badge variant={variant} label={repairStatusLabel(status)} />
}
