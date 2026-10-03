import { useState, type FormEvent } from "react"
import { errorMessage } from "../../api/client"
import { garageApi } from "../../api/garage"
import { useGarageQuery } from "../../hooks/useGarageQuery"
import type { TechnicianAssignment } from "../../types/garage"
import { QueryState } from "../garage/QueryState"
import { Button, Select, Textarea } from "../ui"

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
  const query = useGarageQuery(garageApi.technicians)
  const [technicianId, setTechnicianId] = useState("")
  const [notes, setNotes] = useState("")
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState("")
  const available = (query.data ?? []).filter(
    (technician) =>
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
      })
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
      {!query.loading &&
        !query.error &&
        (available.length ? (
          <fieldset disabled={saving} className="space-y-4">
            <Select
              label="Kỹ thuật viên"
              required
              value={technicianId}
              onChange={(event) => setTechnicianId(event.target.value)}
              options={[
                { value: "", label: "Chọn kỹ thuật viên" },
                ...available.map((technician) => ({
                  value: String(technician.id),
                  label: `${technician.fullName} · NV #${technician.id}`,
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
