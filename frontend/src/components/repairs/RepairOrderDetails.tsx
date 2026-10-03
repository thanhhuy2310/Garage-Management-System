import { useCallback, useState } from "react"
import { garageApi } from "../../api/garage"
import { useGarageQuery } from "../../hooks/useGarageQuery"
import type { TechnicianAssignment } from "../../types/garage"
import { formatGarageDate, formatMoney } from "../../utils/garageFormat"
import { QueryState } from "../garage/QueryState"
import { Button, Card, Icons, Modal } from "../ui"
import AssignmentForm from "./AssignmentForm"
import RepairStatusBadge from "./RepairStatusBadge"

export default function RepairOrderDetails({
  orderId,
  canAssign,
  onBack,
}: {
  orderId: number
  canAssign: boolean
  onBack: () => void
}) {
  const loadDetail = useCallback(
    (signal: AbortSignal) => garageApi.repairOrder(orderId, signal),
    [orderId],
  )
  const query = useGarageQuery(loadDetail)
  const [assignmentOpen, setAssignmentOpen] = useState(false)
  const [saving, setSaving] = useState(false)
  const [success, setSuccess] = useState("")
  const detail = query.data

  function handleAssigned(assignment: TechnicianAssignment) {
    query.setData((current) =>
      current
        ? { ...current, assignments: [...current.assignments, assignment] }
        : current,
    )
    setAssignmentOpen(false)
    setSuccess(`Đã phân công ${assignment.technician.fullName}.`)
  }

  return (
    <div className="space-y-5">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <Button variant="outline" onClick={onBack}>
          Quay lại danh sách
        </Button>
        <Button variant="ghost" disabled={query.loading} onClick={query.reload}>
          Làm mới phiếu
        </Button>
      </div>
      <QueryState
        loading={query.loading}
        error={query.error}
        onRetry={query.reload}
      />
      {success && (
        <p
          role="status"
          className="rounded-lg bg-success-soft p-3 text-sm text-success"
        >
          {success}
        </p>
      )}
      {detail && !query.loading && !query.error && (
        <>
          <Card className="space-y-5 p-5 sm:p-6">
            <div className="flex flex-wrap items-start justify-between gap-4">
              <div>
                <p className="text-sm text-muted-foreground">
                  Phiếu sửa chữa #{detail.order.id} · Tiếp nhận #
                  {detail.order.receptionId}
                </p>
                <h2 className="mt-2 text-2xl font-bold text-foreground">
                  {detail.order.licensePlate}
                </h2>
                <p className="mt-1 text-sm text-muted-foreground">
                  {[detail.order.brand, detail.order.model]
                    .filter(Boolean)
                    .join(" ") || "Chưa có thông tin dòng xe"}
                </p>
              </div>
              <RepairStatusBadge status={detail.order.status} />
            </div>
            <dl className="grid gap-x-8 gap-y-5 border-t border-border pt-5 sm:grid-cols-2 2xl:grid-cols-4">
              {[
                ["Khách hàng", detail.order.customerName],
                ["Ngày lập phiếu", formatGarageDate(detail.order.createdAt)],
                ["Bắt đầu sửa chữa", formatGarageDate(detail.order.startedAt)],
                ["Hoàn tất", formatGarageDate(detail.order.completedAt)],
              ].map(([label, value]) => (
                <div key={label}>
                  <dt className="text-sm text-muted-foreground">{label}</dt>
                  <dd className="mt-1 break-words font-medium text-foreground">
                    {value}
                  </dd>
                </div>
              ))}
            </dl>
          </Card>
          <div className="grid items-start gap-5 lg:grid-cols-[minmax(0,1fr)_minmax(280px,0.65fr)]">
            <div className="order-2 min-w-0 space-y-5 lg:order-1">
              <Card className="space-y-4 p-5">
                <h3 className="font-semibold text-foreground">
                  Thông tin tiếp nhận
                </h3>
                <dl className="space-y-4 text-sm">
                  <div>
                    <dt className="text-muted-foreground">Yêu cầu của khách</dt>
                    <dd className="mt-1 whitespace-pre-wrap break-words leading-relaxed">
                      {detail.order.customerRequest || "Chưa ghi nhận yêu cầu."}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-muted-foreground">
                      Tình trạng ban đầu
                    </dt>
                    <dd className="mt-1 whitespace-pre-wrap break-words leading-relaxed">
                      {detail.order.initialCondition ||
                        "Chưa ghi nhận tình trạng."}
                    </dd>
                  </div>
                  {detail.order.result && (
                    <div>
                      <dt className="text-muted-foreground">
                        Kết quả sửa chữa
                      </dt>
                      <dd className="mt-1 whitespace-pre-wrap break-words leading-relaxed">
                        {detail.order.result}
                      </dd>
                    </div>
                  )}
                </dl>
              </Card>
              <Card className="p-5">
                <h3 className="mb-4 font-semibold text-foreground">
                  Dịch vụ trên phiếu ({detail.services.length})
                </h3>
                {detail.services.length ? (
                  <ul className="divide-y divide-border">
                    {detail.services.map((line) => (
                      <li key={line.id} className="space-y-3 py-4 first:pt-0">
                        <div className="flex flex-wrap justify-between gap-2">
                          <h4 className="break-words font-medium">
                            {line.name}
                          </h4>
                          <RepairStatusBadge status={line.status} />
                        </div>
                        <div className="flex flex-wrap justify-between gap-2 text-sm">
                          <span className="text-muted-foreground">
                            {line.quantity} × {formatMoney(line.unitPrice)}
                          </span>
                          <span className="font-semibold">
                            {formatMoney(line.quantity * line.unitPrice)}
                          </span>
                        </div>
                      </li>
                    ))}
                  </ul>
                ) : (
                  <p className="text-sm text-muted-foreground">
                    Chưa có dịch vụ trên phiếu.
                  </p>
                )}
              </Card>
            </div>
            <Card className="order-1 space-y-4 p-5 lg:order-2">
              <div>
                <h3 className="font-semibold text-foreground">
                  Kỹ thuật viên phụ trách
                </h3>
                <p className="mt-1 text-sm text-muted-foreground">
                  {detail.assignments.length} người được phân công
                </p>
              </div>
              {canAssign && (
                <Button
                  icon={Icons.userCheck}
                  className="w-full"
                  onClick={() => {
                    setSuccess("")
                    setAssignmentOpen(true)
                  }}
                >
                  Phân công KTV
                </Button>
              )}
              {detail.assignments.length ? (
                <ul className="space-y-3">
                  {detail.assignments.map((assignment) => (
                    <li
                      key={assignment.technician.id}
                      className="rounded-lg border border-border bg-surface-subtle p-4"
                    >
                      <p className="break-words font-semibold">
                        {assignment.technician.fullName}
                      </p>
                      <p className="mt-1 text-xs text-muted-foreground">
                        {formatGarageDate(assignment.assignedAt)}
                      </p>
                      {assignment.notes && (
                        <p className="mt-3 whitespace-pre-wrap break-words text-sm leading-relaxed">
                          {assignment.notes}
                        </p>
                      )}
                    </li>
                  ))}
                </ul>
              ) : (
                <p className="py-4 text-sm text-muted-foreground">
                  Chưa phân công kỹ thuật viên.
                </p>
              )}
            </Card>
          </div>
        </>
      )}
      <Modal
        open={assignmentOpen}
        onClose={() => {
          if (!saving) setAssignmentOpen(false)
        }}
        title={`Phân công KTV · Phiếu #${orderId}`}
      >
        {assignmentOpen && detail && (
          <AssignmentForm
            orderId={orderId}
            assignments={detail.assignments}
            onSaved={handleAssigned}
            onCancel={() => setAssignmentOpen(false)}
            onBusyChange={setSaving}
          />
        )}
      </Modal>
    </div>
  )
}
