import { readSession } from "../api/session"
import RepairOrderWorkspace from "../components/repairs/RepairOrderWorkspace"

export default function RepairOrders() {
  const role = readSession()?.account.role
  return (
    <RepairOrderWorkspace canAssign={role === "MANAGER" || role === "ADMIN"} />
  )
}
