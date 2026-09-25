import { Icons } from "../../components/ui"
import type { Xe } from "../../mock/data"

export default function VehicleCard({ vehicle }: { vehicle: Xe }) {
  const description =
    [vehicle.HangXe, vehicle.DongXe].filter(Boolean).join(" ") ||
    "Chưa cập nhật hãng và dòng xe"

  return (
    <article className="rounded-lg border border-border bg-surface p-4 card-shadow sm:p-5">
      <div className="flex items-start gap-3">
        <span
          className="flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-md bg-primary-soft text-primary"
          aria-hidden="true"
        >
          {Icons.car}
        </span>
        <div className="min-w-0 flex-1">
          <p className="mono text-lg font-bold text-primary">
            {vehicle.BienSo}
          </p>
          <p className="mt-1 text-sm font-medium text-foreground">
            {description}
          </p>
        </div>
      </div>
      <dl className="mt-4 grid grid-cols-2 gap-3 border-t border-border pt-4 text-sm">
        <div>
          <dt className="text-xs text-muted-foreground">Năm sản xuất</dt>
          <dd className="mt-1 font-semibold text-foreground">
            {vehicle.NamSanXuat ?? "Chưa cập nhật"}
          </dd>
        </div>
        <div>
          <dt className="text-xs text-muted-foreground">Số km</dt>
          <dd className="mono mt-1 font-semibold text-foreground">
            {vehicle.SoKm === null
              ? "Chưa cập nhật"
              : `${vehicle.SoKm.toLocaleString("vi-VN")} km`}
          </dd>
        </div>
      </dl>
    </article>
  )
}
