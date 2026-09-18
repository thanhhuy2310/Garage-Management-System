import { useMemo } from "react";
import { Badge, Card, TimelineItem } from "../../components/ui";
import { phieuSuaChua, phieuTiepNhan, xe, type RepairStatus } from "../../mock/data";

const CUSTOMER_ID = "KH001";

const STATUS_VARIANT: Record<RepairStatus, "pending" | "in_progress" | "waiting_parts" | "completed" | "confirmed"> = {
  pending: "pending",
  inspecting: "confirmed",
  in_progress: "in_progress",
  waiting_parts: "waiting_parts",
  completed: "completed",
};

const STATUS_LABEL: Record<RepairStatus, string> = {
  pending: "Chờ xử lý",
  inspecting: "Đang kiểm tra",
  in_progress: "Đang sửa chữa",
  waiting_parts: "Chờ phụ tùng",
  completed: "Hoàn tất",
};

function repairVehicle(repairId: string) {
  const repair = phieuSuaChua.find((r) => r.MaPhieuSuaChua === repairId);
  const reception = phieuTiepNhan.find((t) => t.MaTiepNhan === repair?.MaTiepNhan);
  return { repair, reception, vehicle: xe.find((v) => v.MaXe === reception?.MaXe) };
}

export default function CustomerTracking() {
  const myRepairs = useMemo(() => {
    const mine = phieuSuaChua.filter((r) => {
      const reception = phieuTiepNhan.find((t) => t.MaTiepNhan === r.MaTiepNhan);
      return xe.find((v) => v.MaXe === reception?.MaXe)?.MaKhachHang === CUSTOMER_ID;
    });
    return mine.filter((r) => r.TrangThai !== "completed");
  }, []);

  return (
    <div className="space-y-4">
      <div>
        <h2 className="ui-section-title">Tiến độ sửa chữa</h2>
        <p className="ui-secondary-text text-sm">{myRepairs.length} xe đang trong xưởng</p>
      </div>

      {myRepairs.length === 0 ? (
        <Card className="p-10 text-center">
          <p className="ui-card-title">Không có xe nào đang sửa</p>
          <p className="ui-secondary-text mt-1 text-sm">Xe hoàn tất sẽ chuyển sang mục Lịch sử.</p>
        </Card>
      ) : (
        <ul className="grid gap-4 lg:grid-cols-2">
          {myRepairs.map((repair) => {
            const { reception, vehicle } = repairVehicle(repair.MaPhieuSuaChua);
            const steps = [
              { label: "Tiếp nhận xe", time: reception?.NgayTiepNhan.slice(0, 16).replace("T", " "), done: true },
              { label: "Kiểm tra & báo giá", done: true },
              {
                label: repair.TrangThai === "waiting_parts" ? "Chờ phụ tùng" : "Đang sửa chữa",
                time: repair.NgayBatDau?.slice(0, 16).replace("T", " ") ?? undefined,
                done: false,
                active: true,
              },
              { label: "Thanh toán & bàn giao", done: false },
            ];
            return (
              <li key={repair.MaPhieuSuaChua}>
                <Card className="h-full p-5">
                  <div className="flex items-start justify-between gap-2">
                    <div>
                      <p className="mono text-lg font-bold text-primary">{vehicle?.BienSo}</p>
                      <p className="text-xs text-muted-foreground">
                        {vehicle?.HangXe} {vehicle?.DongXe} · Phiếu {repair.MaPhieuSuaChua}
                      </p>
                    </div>
                    <Badge variant={STATUS_VARIANT[repair.TrangThai]} label={STATUS_LABEL[repair.TrangThai]} />
                  </div>
                  {reception?.YeuCauKhachHang && (
                    <p className="mt-2 rounded-lg bg-surface-subtle p-3 text-[13px] text-slate-600">
                      Yêu cầu: {reception.YeuCauKhachHang}
                    </p>
                  )}
                  <div className="mt-4">
                    {steps.map((step) => (
                      <TimelineItem key={step.label} label={step.label} time={step.time} done={step.done} active={step.active} />
                    ))}
                  </div>
                </Card>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
