import { useState } from "react"
import axios from "axios"
import { billingApi } from "../../api/billing"
import { errorMessage } from "../../api/client"
import { useGarageQuery } from "../../hooks/useGarageQuery"
import type { InvoiceDetail, PaymentRequest } from "../../types/billing"
import { formatMoney } from "../../utils/garageFormat"
import { QueryState } from "../garage/QueryState"
import TransferQrPayment from "../TransferQrPayment"
import { Button, Input, Select } from "../ui"

function newRequestId() {
  // getRandomValues also works when testing mobile web over a local HTTP address.
  const bytes = crypto.getRandomValues(new Uint8Array(16))
  bytes[6] = (bytes[6] & 0x0f) | 0x40
  bytes[8] = (bytes[8] & 0x3f) | 0x80
  const hex = Array.from(bytes, value => value.toString(16).padStart(2, "0")).join("")
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`
}

export default function PaymentForm({
  detail,
  onSaved,
  onBusyChange,
}: {
  detail: InvoiceDetail
  onSaved: (value: InvoiceDetail) => void
  onBusyChange: (busy: boolean) => void
}) {
  const key = `garage_pending_payment_${detail.invoice.id}`
  const [pending, setPending] = useState<PaymentRequest | null>(() => {
    try {
      return JSON.parse(sessionStorage.getItem(key) ?? "null")
    } catch {
      return null
    }
  })
  const [amount, setAmount] = useState(
    String(pending?.amount ?? detail.invoice.remaining),
  )
  const [method, setMethod] = useState<PaymentRequest["method"]>(
    pending?.method ?? "TIEN_MAT",
  )
  const [bankId, setBankId] = useState(String(pending?.bankAccountId ?? ""))
  const [confirmed, setConfirmed] = useState(false)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState("")
  const banks = useGarageQuery(billingApi.banks)
  const bank = banks.data?.find((b) => b.active && b.id === Number(bankId))
  async function submit(event: React.FormEvent) {
    event.preventDefault()
    if (busy || !confirmed) return
    setBusy(true)
    onBusyChange(true)
    setError("")
    try {
      const request = pending ?? {
        amount: Number(amount),
        method,
        bankAccountId: method === "CHUYEN_KHOAN" && bank ? bank.id : null,
        requestId: newRequestId(),
      }
      // Keep the key across retries/reopening the dialog if the response was lost.
      sessionStorage.setItem(key, JSON.stringify(request))
      setPending(request)
      const saved = await billingApi.pay(detail.invoice.id, request)
      sessionStorage.removeItem(key)
      setPending(null)
      onSaved(saved)
    } catch (reason) {
      if (
        axios.isAxiosError(reason) &&
        reason.response &&
        reason.response.status >= 400 &&
        reason.response.status < 500 &&
        reason.response.status !== 408
      ) {
        sessionStorage.removeItem(key)
        setPending(null)
      }
      setError(errorMessage(reason))
    } finally {
      setBusy(false)
      onBusyChange(false)
    }
  }
  return (
    <form onSubmit={submit} className="space-y-5">
      <p className="text-sm">
        Hóa đơn #{detail.invoice.id} · Còn phải thu{" "}
        <strong>{formatMoney(detail.invoice.remaining)}</strong>
      </p>
      <Input
        label="Số tiền đã nhận (đ)"
        required
        type="number"
        min="0.01"
        step="0.01"
        max={pending ? undefined : detail.invoice.remaining}
        disabled={busy || !!pending}
        value={amount}
        onChange={(e) => {
          setAmount(e.target.value)
          setConfirmed(false)
        }}
      />
      <Select
        label="Phương thức"
        value={method}
        disabled={busy || !!pending}
        options={[
          { value: "TIEN_MAT", label: "Tiền mặt" },
          { value: "CHUYEN_KHOAN", label: "Chuyển khoản" },
        ]}
        onChange={(e) => {
          setMethod(e.target.value as PaymentRequest["method"])
          setConfirmed(false)
        }}
      />
      {method === "CHUYEN_KHOAN" && (
        <>
          <QueryState
            loading={banks.loading}
            error={banks.error}
            onRetry={banks.reload}
          />
          <Select
            label="Tài khoản nhận tiền"
            value={bankId}
            disabled={busy || !!pending}
            options={[
              { value: "", label: "Ghi nhận chuyển khoản không kèm QR" },
              ...(banks.data ?? [])
                .filter((b) => b.active)
                .map((b) => ({
                  value: String(b.id),
                  label: `${b.name} · ${b.account}`,
                })),
            ]}
            onChange={(e) => {
              setBankId(e.target.value)
              setConfirmed(false)
            }}
          />
          {bank &&
          Number.isSafeInteger(Number(amount)) &&
          Number(amount) > 0 &&
          Number(amount) <= detail.invoice.remaining ? (
            <TransferQrPayment
              key={`${bank.id}-${amount}`}
              bank={bank}
              amount={Number(amount)}
              amountLabel={formatMoney(Number(amount))}
              invoiceId={String(detail.invoice.id)}
            />
          ) : (
            <p className="text-sm text-muted-foreground">
              Chọn tài khoản nhận tiền và số tiền nguyên đồng để hiển thị QR.
              Bạn vẫn có thể ghi nhận giao dịch đã đối chiếu.
            </p>
          )}
        </>
      )}
      {pending && (
        <p role="status" className="text-sm text-warning">
          Yêu cầu trước chưa được xác nhận. Nhấn lại để kiểm tra và hoàn tất,
          không ghi nhận trùng.
        </p>
      )}
      <label className="flex min-h-11 items-start gap-3 text-sm leading-6">
        <input
          type="checkbox"
          className="mt-1.5"
          checked={confirmed}
          disabled={busy}
          onChange={(e) => setConfirmed(e.target.checked)}
        />
        Tôi đã nhận và đối chiếu đúng số tiền này.
      </label>
      {error && (
        <p role="alert" className="text-sm text-danger">
          {error}
        </p>
      )}
      <Button
        className="w-full justify-center"
        type="submit"
        disabled={busy || !confirmed || Number(amount) <= 0}
      >
        {busy ? "Đang ghi nhận..." : "Xác nhận đã nhận tiền"}
      </Button>
    </form>
  )
}
