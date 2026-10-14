import { useState } from "react"
import { billingApi } from "../../api/billing"
import { errorMessage } from "../../api/client"
import { useGarageQuery } from "../../hooks/useGarageQuery"
import type { BankAccount } from "../../types/billing"
import { QueryState } from "../garage/QueryState"
import { Button, Input, Select } from "../ui"

// BINs from the VietQR bank directory; account numbers are entered by the garage.
const banks = [
  ["970436", "Vietcombank"],
  ["970418", "BIDV"],
  ["970407", "Techcombank"],
  ["970422", "MB Bank"],
  ["970416", "ACB"],
  ["970415", "VietinBank"],
  ["970405", "Agribank"],
  ["970432", "VPBank"],
  ["970423", "TPBank"],
]
const emptyAccount = (): Omit<BankAccount, "id"> => ({
  name: "",
  bin: "",
  account: "",
  accountName: "GARA O TO THANH CONG",
  active: true,
})

export default function BankAccounts({
  onBusyChange,
}: {
  onBusyChange: (busy: boolean) => void
}) {
  const query = useGarageQuery(billingApi.banks)
  const [editing, setEditing] = useState<number>()
  const [form, setForm] = useState(emptyAccount)
  const [busy, setBusy] = useState(false)
  const [error, setError] = useState("")
  const [saved, setSaved] = useState(false)
  async function submit(event: React.FormEvent) {
    event.preventDefault()
    if (busy) return
    setBusy(true)
    onBusyChange(true)
    setError("")
    setSaved(false)
    try {
      await billingApi.saveBank(form, editing)
      setForm(emptyAccount())
      setEditing(undefined)
      setSaved(true)
      query.reload()
    } catch (reason) {
      setError(errorMessage(reason))
    } finally {
      setBusy(false)
      onBusyChange(false)
    }
  }
  return (
    <div className="space-y-6">
      <QueryState
        loading={query.loading}
        error={query.error}
        onRetry={query.reload}
      />
      {query.data?.length === 0 && (
        <p className="text-sm text-muted-foreground">
          Chưa có tài khoản nhận chuyển khoản. Thêm tài khoản của gara bên dưới.
        </p>
      )}
      <div className="space-y-2">
        {query.data?.map((bank) => (
          <button
            type="button"
            key={bank.id}
            disabled={busy}
            className="w-full rounded-lg border border-border p-3 text-left hover:bg-surface-subtle"
            onClick={() => {
              setForm(bank)
              setEditing(bank.id)
              setSaved(false)
              setError("")
            }}
          >
            <span className="block font-semibold">
              {bank.name} · {bank.active ? "Đang sử dụng" : "Ngừng sử dụng"}
            </span>
            <span className="block break-all text-sm text-muted-foreground">
              {bank.account} · {bank.accountName}
            </span>
            <span className="text-xs text-primary">Chỉnh sửa</span>
          </button>
        ))}
      </div>
      <form onSubmit={submit} className="space-y-4 border-t border-border pt-5">
        <h3 className="font-semibold">
          {editing ? "Chỉnh sửa tài khoản" : "Thêm tài khoản ngân hàng"}
        </h3>
        <Select
          label="Ngân hàng"
          required
          disabled={busy}
          value={form.bin}
          options={[
            { value: "", label: "Chọn ngân hàng" },
            ...banks.map(([value, label]) => ({ value, label })),
          ]}
          onChange={(e) =>
            setForm({
              ...form,
              bin: e.target.value,
              name: banks.find((b) => b[0] === e.target.value)?.[1] ?? "",
            })
          }
        />
        <Input
          label="Số tài khoản"
          required
          inputMode="numeric"
          pattern="[0-9]{6,25}"
          maxLength={25}
          disabled={busy}
          value={form.account}
          onChange={(e) =>
            setForm({ ...form, account: e.target.value.replace(/\s/g, "") })
          }
        />
        <Input
          label="Tên chủ tài khoản"
          required
          maxLength={100}
          disabled={busy}
          value={form.accountName}
          onChange={(e) => setForm({ ...form, accountName: e.target.value })}
        />
        <p className="text-xs text-muted-foreground">
          Kiểm tra và nhập đúng tên chủ tài khoản đã đăng ký tại ngân hàng.
        </p>
        <label className="flex min-h-11 items-center gap-3 text-sm">
          <input
            type="checkbox"
            checked={form.active}
            disabled={busy}
            onChange={(e) => setForm({ ...form, active: e.target.checked })}
          />
          Đang sử dụng
        </label>
        {error && (
          <p role="alert" className="text-sm text-danger">
            {error}
          </p>
        )}
        {saved && (
          <p role="status" className="text-sm text-success">
            Đã lưu tài khoản ngân hàng.
          </p>
        )}
        <div className="flex flex-wrap justify-end gap-3">
          {editing && (
            <Button
              variant="outline"
              type="button"
              disabled={busy}
              onClick={() => {
                setEditing(undefined)
                setForm(emptyAccount())
              }}
            >
              Thêm tài khoản khác
            </Button>
          )}
          <Button type="submit" disabled={busy}>
            {busy ? "Đang lưu..." : "Lưu tài khoản"}
          </Button>
        </div>
      </form>
    </div>
  )
}
