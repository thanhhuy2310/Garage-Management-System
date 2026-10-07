import { useCallback, useState } from "react"
import { billingApi } from "../api/billing"
import { readSession } from "../api/session"
import BankAccounts from "../components/billing/BankAccounts"
import CreateInvoiceForm from "../components/billing/CreateInvoiceForm"
import PaymentForm from "../components/billing/PaymentForm"
import { QueryState } from "../components/garage/QueryState"
import { Badge, Button, Card, Input, Modal } from "../components/ui"
import { useGarageQuery } from "../hooks/useGarageQuery"
import type { InvoiceDetail } from "../types/billing"
import { formatGarageDate, formatMoney } from "../utils/garageFormat"

export default function Invoice() {
  const query = useGarageQuery(billingApi.invoices)
  const [selected, setSelected] = useState<number | null>(null)
  const [search, setSearch] = useState("")
  const [modal, setModal] = useState<"create" | "banks" | null>(null)
  const [busy, setBusy] = useState(false)
  const role = readSession()?.account.role
  const canManageBanks = role === "ADMIN" || role === "MANAGER"
  const invoices = query.data ?? []
  const visible = invoices.filter((i) =>
    `${i.id} ${i.licensePlate} ${i.customerName}`
      .toLowerCase()
      .includes(search.trim().toLowerCase()),
  )
  const id = selected ?? invoices[0]?.id
  return (
    <div className="space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h2 className="ui-section-title">Hóa đơn và thanh toán</h2>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={query.reload}>
            Làm mới
          </Button>
          {canManageBanks && (
            <Button variant="outline" onClick={() => setModal("banks")}>
              Tài khoản ngân hàng
            </Button>
          )}
          <Button
            onClick={() => setModal("create")}
            disabled={query.loading || !!query.error}
          >
            Lập hóa đơn
          </Button>
        </div>
      </div>
      <QueryState
        loading={query.loading}
        error={query.error}
        onRetry={query.reload}
      />
      {!query.loading && !query.error && (
        <div className="grid min-w-0 gap-6 xl:grid-cols-[minmax(260px,1fr)_minmax(0,2fr)]">
          <section className="min-w-0 space-y-3" aria-label="Danh sách hóa đơn">
            <Input
              label="Tìm hóa đơn"
              placeholder="Mã hóa đơn, biển số, khách hàng"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
            {!visible.length && (
              <Card className="p-5 text-sm text-muted-foreground">
                {invoices.length
                  ? "Không tìm thấy hóa đơn phù hợp."
                  : "Chưa có hóa đơn. Chọn Lập hóa đơn để thu tiền cho phiếu đã hoàn tất."}
              </Card>
            )}
            {visible.map((i) => (
              <button
                key={i.id}
                onClick={() => setSelected(i.id)}
                aria-pressed={id === i.id}
                className={`w-full rounded-xl border bg-surface p-4 text-left transition-colors ${
                  id === i.id
                    ? "border-primary ring-1 ring-primary"
                    : "border-border hover:bg-surface-subtle"
                }`}
              >
                <div className="flex flex-wrap items-center justify-between gap-2">
                  <strong>Hóa đơn #{i.id}</strong>
                  <Badge variant={i.remaining <= 0 ? "paid" : "unpaid"} />
                </div>
                <p className="mt-2 font-semibold">
                  {i.licensePlate} · {i.customerName}
                </p>
                <p className="mt-1 text-xs text-muted-foreground">
                  {formatGarageDate(i.createdAt)}
                </p>
                <p className="mt-3 text-sm">
                  Tổng <strong>{formatMoney(i.total)}</strong> · Còn{" "}
                  {formatMoney(i.remaining)}
                </p>
              </button>
            ))}
          </section>
          {id && <InvoiceContent key={id} id={id} onChanged={query.reload} />}
        </div>
      )}
      <Modal
        open={modal !== null}
        title={
          modal === "banks" ? "Tài khoản nhận chuyển khoản" : "Lập hóa đơn"
        }
        onClose={() => {
          if (!busy) setModal(null)
        }}
      >
        {modal === "create" && (
          <CreateInvoiceForm
            invoices={invoices}
            onBusyChange={setBusy}
            onSaved={(value) => {
              setSelected(value.invoice.id)
              setModal(null)
              query.reload()
            }}
          />
        )}
        {modal === "banks" && <BankAccounts onBusyChange={setBusy} />}
      </Modal>
    </div>
  )
}

function InvoiceContent({
  id,
  onChanged,
}: {
  id: number
  onChanged: () => void
}) {
  const load = useCallback(
    (signal: AbortSignal) => billingApi.invoice(id, signal),
    [id],
  )
  const query = useGarageQuery(load)
  const [pay, setPay] = useState(false)
  const [busy, setBusy] = useState(false)
  const detail = query.data
  function saved(value: InvoiceDetail) {
    query.setData(value)
    setPay(false)
    onChanged()
  }
  return (
    <Card className="min-w-0 self-start p-4 sm:p-6">
      <QueryState
        loading={query.loading}
        error={query.error}
        onRetry={query.reload}
      />
      {detail && (
        <>
          <div className="flex flex-wrap items-center justify-between gap-3">
            <h3 className="text-xl font-bold">Hóa đơn #{id}</h3>
            <Badge
              variant={detail.invoice.remaining <= 0 ? "paid" : "unpaid"}
            />
          </div>
          <p className="mt-2 text-sm text-muted-foreground">
            {formatGarageDate(detail.invoice.createdAt)} · Phiếu sửa chữa #
            {detail.invoice.repairOrderId}
          </p>
          <div className="my-5 grid gap-3 sm:grid-cols-2">
            <div className="rounded-lg bg-surface-subtle p-3">
              <p className="text-xs text-muted-foreground">Khách hàng</p>
              <p className="mt-1 font-semibold">
                {detail.invoice.customerName}
              </p>
            </div>
            <div className="rounded-lg bg-surface-subtle p-3">
              <p className="text-xs text-muted-foreground">Biển số</p>
              <p className="mt-1 font-semibold">
                {detail.invoice.licensePlate}
              </p>
            </div>
          </div>
          <div className="overflow-x-auto">
            <table className="data-table w-full min-w-[520px]">
              <thead>
                <tr>
                  <th>Nội dung</th>
                  <th>Số lượng</th>
                  <th>Đơn giá</th>
                  <th>Thành tiền</th>
                </tr>
              </thead>
              <tbody>
                {detail.lines.map((line) => (
                  <tr key={`${line.type}-${line.id}`}>
                    <td>
                      <span className="block font-medium">{line.name}</span>
                      <span className="text-xs text-muted-foreground">
                        {line.type === "DICH_VU" ? "Dịch vụ" : "Phụ tùng"}
                      </span>
                    </td>
                    <td>{line.quantity}</td>
                    <td>{formatMoney(line.unitPrice)}</td>
                    <td>{formatMoney(line.quantity * line.unitPrice)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <dl className="ml-auto mt-5 max-w-sm space-y-3 text-sm">
            <div className="flex justify-between gap-3">
              <dt>Tổng tiền</dt>
              <dd className="font-bold">{formatMoney(detail.invoice.total)}</dd>
            </div>
            <div className="flex justify-between gap-3">
              <dt>Đã thanh toán</dt>
              <dd>{formatMoney(detail.invoice.paid)}</dd>
            </div>
            <div className="flex justify-between gap-3 border-t border-border pt-3 text-base font-bold">
              <dt>Còn phải thu</dt>
              <dd className="text-primary">
                {formatMoney(detail.invoice.remaining)}
              </dd>
            </div>
          </dl>
          <h4 className="mb-3 mt-7 font-semibold">Lịch sử thanh toán</h4>
          {!detail.payments.length && (
            <p className="text-sm text-muted-foreground">
              Chưa ghi nhận thanh toán.
            </p>
          )}
          <div className="space-y-2">
            {detail.payments.map((p) => (
              <div
                key={p.id}
                className="flex flex-wrap justify-between gap-2 rounded-lg border border-border p-3 text-sm"
              >
                <span>
                  #{p.id} · {formatGarageDate(p.paidAt)}
                  <span className="block text-muted-foreground">
                    {p.method === "CHUYEN_KHOAN"
                      ? "Chuyển khoản"
                      : p.method === "TIEN_MAT"
                        ? "Tiền mặt"
                        : p.method}
                  </span>
                </span>
                <strong>{formatMoney(p.amount)}</strong>
              </div>
            ))}
          </div>
          {detail.invoice.remaining > 0 && (
            <Button
              className="mt-6 w-full justify-center"
              onClick={() => setPay(true)}
            >
              Ghi nhận thanh toán
            </Button>
          )}
          <Modal
            open={pay}
            title="Ghi nhận thanh toán"
            width="max-w-3xl"
            onClose={() => {
              if (!busy) setPay(false)
            }}
          >
            {pay && (
              <PaymentForm
                detail={detail}
                onSaved={saved}
                onBusyChange={setBusy}
              />
            )}
          </Modal>
        </>
      )}
    </Card>
  )
}
