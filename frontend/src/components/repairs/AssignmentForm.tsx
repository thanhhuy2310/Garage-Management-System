import { useState, type FormEvent } from "react"
import { errorMessage } from "../../api/client"
import { garageApi } from "../../api/garage"
import { useGarageQuery } from "../../hooks/useGarageQuery"
import type { TechnicianAssignment } from "../../types/garage"
import { QueryState } from "../garage/QueryState"
import { Button, Select, Textarea } from "../ui"
import TechnicianSchedule from './TechnicianSchedule'

export default function AssignmentForm({
  orderId,
  assignments,
  onSaved,
  onCancel,
  onBusyChange,
}: {
  orderId: number
  assignments: TechnicianAssignment[]
  onSaved: (assignment: TechnicianAssignment) => void
  onCancel: () => void
  onBusyChange: (busy: boolean) => void
}) {
  const query = useGarageQuery(garageApi.technicianWorkload)
  const [technicianId, setTechnicianId] = useState("")
  const [previousTechnician, setPreviousTechnician] = useState("")
  const [notes, setNotes] = useState("")
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState("")
  const available = (query.data ?? []).filter(
    (technician) =>
      technician.assignable &&
      !assignments.some((item) => item.technician.id === technician.id),
  )

  async function handleSubmit(event: FormEvent) {
    event.preventDefault()
    if (
      saving ||
      !available.some((technician) => technician.id === Number(technicianId))
    )
      return
    setSaving(true)
    onBusyChange(true)
    setError("")
    try {
      const assignment = await garageApi.assignTechnician(orderId, {
        technicianId: Number(technicianId),
        notes: notes.trim() || null,
      }, previousTechnician ? Number(previousTechnician) : undefined)
      onSaved(assignment)
    } catch (reason) {
      setError(
        errorMessage(
          reason,
          "Không phân công được kỹ thuật viên. Vui lòng thử lại.",
        ),
      )
    } finally {
      setSaving(false)
      onBusyChange(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5" aria-busy={saving}>
      <QueryState
        loading={query.loading}
        error={query.error}
        onRetry={query.reload}
      />
      {query.data && <>
        <div className="overflow-x-auto"><table className="w-full text-sm">
          <thead><tr><th className="text-left">Kỹ thuật viên</th><th>Trạng thái</th><th>Ca làm</th><th>Xe / giới hạn</th><th>Việc còn lại</th><th>Xong hôm nay</th></tr></thead>
          <tbody>{query.data.map(t=><tr key={t.id} className="border-t border-border">
            <td className="py-2">{t.fullName}</td><td>{t.status}</td>
            <td>{t.shiftStatus}<br/>{t.shifts.map(s=>`${s.name} ${s.start.slice(0,5)}–${s.end.slice(0,5)}`).join(', ')}</td>
            <td>{t.activeVehicles} / {t.vehicleLimit}</td><td>{t.pendingTasks}</td><td>{t.completedToday}</td>
          </tr>)}</tbody></table></div>
        <TechnicianSchedule technicians={query.data} onSaved={query.reload} onBusyChange={onBusyChange}/>
      </>}
      {!query.loading &&
        !query.error &&
        (available.length ? (
          <fieldset disabled={saving} className="space-y-4">
            {assignments.length > 0 && <Select label="Hình thức phân công" value={previousTechnician}
              onChange={event => setPreviousTechnician(event.target.value)}
              options={[{value:"", label:"Phân công thêm"}, ...assignments.map(a => ({
                value:String(a.technician.id), label:`Bàn giao từ ${a.technician.fullName}`,
              }))]}/>}
            <Select
              label="Kỹ thuật viên"
              required
              value={technicianId}
              onChange={(event) => setTechnicianId(event.target.value)}
              options={[
                { value: "", label: "Chọn kỹ thuật viên" },
                ...available.map((technician) => ({
                  value: String(technician.id),
                  label: `${technician.fullName} · ${technician.status} · ${technician.activeVehicles}/${technician.vehicleLimit} xe`,
                })),
              ]}
            />
            <Textarea
              label="Nội dung phân công"
              maxLength={500}
              value={notes}
              onChange={(event) => setNotes(event.target.value)}
              placeholder="Hạng mục cần kiểm tra và lưu ý khi sửa chữa"
            />
          </fieldset>
        ) : (
          <p className="text-sm text-muted-foreground">
            Không còn kỹ thuật viên nào để thêm vào phiếu này.
          </p>
        ))}
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
        <Button
          type="submit"
          disabled={
            saving ||
            query.loading ||
            Boolean(query.error) ||
            !available.some(
              (technician) => technician.id === Number(technicianId),
            )
          }
        >
          {saving ? "Đang lưu..." : "Xác nhận phân công"}
        </Button>
      </div>
    </form>
  )
}
