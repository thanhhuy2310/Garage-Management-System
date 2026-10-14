import { useState } from "react"
import { garageApi } from "../api/garage"
import { QueryState } from "../components/garage/QueryState"
import ServiceForm from "../components/services/ServiceForm"
import { Button, Card, Icons, Modal, SearchBox, Select } from "../components/ui"
import { useGarageQuery } from "../hooks/useGarageQuery"
import type { GarageService } from "../types/garage"
import { formatMoney } from "../utils/garageFormat"

export default function Services() {
  const query = useGarageQuery(garageApi.services)
  const [search, setSearch] = useState("")
  const [category, setCategory] = useState("")
  const [editing, setEditing] = useState<GarageService | null>(null)
  const [formOpen, setFormOpen] = useState(false)
  const [saving, setSaving] = useState(false)
  const [success, setSuccess] = useState("")

  const services = query.data ?? []
  const categories = [
    ...new Set(
      services
        .map((service) => service.type)
        .filter((type): type is string => Boolean(type)),
    ),
  ]
  const keyword = search.trim().toLocaleLowerCase("vi")
  const filtered = services.filter(
    (service) =>
      (!category || service.type === category) &&
      `${service.name} ${service.type ?? ""}`
        .toLocaleLowerCase("vi")
        .includes(keyword),
  )

  function openForm(service: GarageService | null) {
    setEditing(service)
    setSuccess("")
    setFormOpen(true)
  }

  function handleSaved(service: GarageService) {
    query.setData((current) =>
      editing
        ? (current ?? []).map((item) =>
            item.id === service.id ? service : item,
          )
        : [...(current ?? []), service],
    )
    setFormOpen(false)
    setSuccess(editing ? "Đã cập nhật dịch vụ." : "Đã thêm dịch vụ.")
  }

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold text-foreground">
            Danh mục dịch vụ
          </h2>
          <p className="mt-1 text-sm text-muted-foreground">
            Quản lý tên dịch vụ, nhóm và đơn giá tại gara.
          </p>
        </div>
        <Button icon={Icons.plus} onClick={() => openForm(null)}>
          Thêm dịch vụ
        </Button>
      </div>
      {success && (
        <p
          role="status"
          className="rounded-lg bg-success-soft p-3 text-sm text-success"
        >
          {success}
        </p>
      )}
      <Card className="space-y-4 p-4 sm:p-5">
        <div className="grid gap-3 sm:grid-cols-[1fr_240px_auto] sm:items-end">
          <SearchBox
            value={search}
            onChange={setSearch}
            placeholder="Tìm tên hoặc nhóm dịch vụ..."
          />
          <Select
            label="Nhóm dịch vụ"
            value={category}
            onChange={(event) => setCategory(event.target.value)}
            options={[
              { value: "", label: "Tất cả nhóm" },
              ...categories.map((item) => ({ value: item, label: item })),
            ]}
          />
          <Button
            variant="outline"
            disabled={query.loading}
            onClick={query.reload}
          >
            Làm mới
          </Button>
        </div>
        {!query.loading && !query.error && (
          <p className="text-sm text-muted-foreground">
            {filtered.length} dịch vụ
          </p>
        )}
      </Card>
      <QueryState
        loading={query.loading}
        error={query.error}
        onRetry={query.reload}
      />
      {!query.loading &&
        !query.error &&
        (filtered.length ? (
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {filtered.map((service) => (
              <Card key={service.id} className="flex flex-col p-5">
                <div className="flex items-start justify-between gap-3">
                  <span
                    className="rounded-md bg-primary-soft p-2 text-primary"
                    aria-hidden="true"
                  >
                    {Icons.wrench}
                  </span>
                  <span className="text-xs text-muted-foreground">
                    DV #{service.id}
                  </span>
                </div>
                <h3 className="mt-4 break-words text-base font-semibold text-foreground">
                  {service.name}
                </h3>
                <p className="mt-1 text-sm text-muted-foreground">
                  {service.type || "Chưa phân nhóm"}
                </p>
                <p className="mt-3 mb-5 whitespace-pre-wrap break-words text-sm leading-relaxed text-muted-foreground">
                  {service.description || "Chưa có mô tả."}
                </p>
                <div className="mt-auto flex flex-wrap items-center justify-between gap-3 border-t border-border pt-4">
                  <span className="font-semibold text-primary">
                    {formatMoney(service.unitPrice)}
                  </span>
                  <Button
                    variant="outline"
                    icon={Icons.edit}
                    aria-label={`Sửa ${service.name}`}
                    onClick={() => openForm(service)}
                  >
                    Chỉnh sửa
                  </Button>
                </div>
              </Card>
            ))}
          </div>
        ) : (
          <Card className="p-10 text-center text-muted-foreground">
            {services.length
              ? "Không tìm thấy dịch vụ phù hợp."
              : "Chưa có dịch vụ. Thêm dịch vụ đầu tiên để bắt đầu."}
          </Card>
        ))}
      <Modal
        open={formOpen}
        onClose={() => {
          if (!saving) setFormOpen(false)
        }}
        title={editing ? "Chỉnh sửa dịch vụ" : "Thêm dịch vụ"}
      >
        {formOpen && (
          <ServiceForm
            key={editing?.id ?? "new"}
            service={editing}
            onSaved={handleSaved}
            onCancel={() => setFormOpen(false)}
            onBusyChange={setSaving}
          />
        )}
      </Modal>
    </div>
  )
}
