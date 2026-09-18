import { useMemo, useState } from "react";
import { Badge, Button, Card, Icons, Input, Modal, Select } from "../../components/ui";
import { dichVu, lichHen, xe, type AppointmentStatus } from "../../mock/data";

const CUSTOMER_ID = "KH001";

const STATUS_VARIANT: Record<AppointmentStatus, "pending" | "confirmed" | "arrived" | "cancelled" | "completed"> = {
  pending: "pending",
  confirmed: "confirmed",
  arrived: "arrived",
  cancelled: "cancelled",
  completed: "completed",
};

const STATUS_LABEL: Record<AppointmentStatus, string> = {
  pending: "Chờ xác nhận",
  confirmed: "Đã xác nhận",
  arrived: "Đã đến",
  cancelled: "Đã hủy",
  completed: "Hoàn tất",
};

export default function CustomerAppointments({ onBooked }: { onBooked?: () => void }) {
  const [showBook, setShowBook] = useState(false);
  const [done, setDone] = useState(false);

  const myVehicles = useMemo(() => xe.filter((v) => v.MaKhachHang === CUSTOMER_ID), []);
  const myAppointments = useMemo(
    () => lichHen.filter((a) => a.MaKhachHang === CUSTOMER_ID),
    [],
  );

  const vehiclePlate = (id: string) => xe.find((v) => v.MaXe === id)?.BienSo ?? id;
  const serviceName = (id: string | null) => dichVu.find((s) => s.MaDichVu === id)?.TenDichVu ?? "Tư vấn chung";

  return (
    <div className="space-y-4">
      <div className="page-toolbar">
        <div>
          <h2 className="ui-section-title">Lịch hẹn của tôi</h2>
          <p className="ui-secondary-text text-sm">{myAppointments.length} lịch hẹn · {myVehicles.length} xe</p>
        </div>
        <Button icon={Icons.plus} onClick={() => { setShowBook(true); setDone(false); }}>Đặt lịch mới</Button>
      </div>

      {myAppointments.length === 0 ? (
        <Card className="p-10 text-center">
          <p className="ui-card-title">Chưa có lịch hẹn</p>
          <p className="ui-secondary-text mt-1 text-sm">Đặt lịch bảo dưỡng hoặc sửa chữa đầu tiên cho xe của bạn.</p>
        </Card>
      ) : (
        <ul className="grid gap-4 md:grid-cols-2">
          {myAppointments.map((appointment) => (
            <li key={appointment.MaLichHen}>
              <Card className="h-full p-5">
                <div className="flex items-start justify-between gap-2">
                  <div>
                    <p className="mono text-lg font-bold text-primary">{vehiclePlate(appointment.MaXe)}</p>
                    <p className="text-sm text-slate-600">{serviceName(appointment.MaDichVu)}</p>
                  </div>
                  <Badge variant={STATUS_VARIANT[appointment.TrangThai]} label={STATUS_LABEL[appointment.TrangThai]} />
                </div>
                {appointment.NoiDung && <p className="mt-2 text-[13px] text-slate-500">{appointment.NoiDung}</p>}
                <div className="mt-3 flex items-center justify-between rounded-lg bg-surface-subtle px-3 py-2.5">
                  <span className="text-xs text-muted-foreground">Ngày {appointment.NgayHen}</span>
                  <span className="text-sm font-bold text-primary">{appointment.GioHen}</span>
                </div>
                <p className="mono mt-2 text-xs text-slate-400">{appointment.MaLichHen}</p>
              </Card>
            </li>
          ))}
        </ul>
      )}

      <Modal open={showBook} onClose={() => setShowBook(false)} title="Đặt lịch sửa chữa / bảo dưỡng">
        {done ? (
          <div className="py-6 text-center">
            <span className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-success-soft text-success" aria-hidden="true">
              {Icons.checkCircle}
            </span>
            <p className="ui-card-title mt-3">Đặt lịch thành công!</p>
            <p className="ui-secondary-text mt-1 text-sm">Gara sẽ xác nhận giờ hẹn trong giờ làm việc.</p>
            <div className="mt-4 flex justify-center">
              <Button variant="outline" onClick={() => { setShowBook(false); onBooked?.(); }}>Đóng</Button>
            </div>
          </div>
        ) : (
          <form className="space-y-4" onSubmit={(e) => { e.preventDefault(); setDone(true); }}>
            <Select
              label="Xe *"
              options={myVehicles.map((v) => ({ value: v.MaXe, label: `${v.BienSo} · ${v.HangXe} ${v.DongXe}` }))}
            />
            <Select
              label="Dịch vụ *"
              options={[{ value: "", label: "Tư vấn chung" }, ...dichVu.map((s) => ({ value: s.MaDichVu, label: s.TenDichVu }))]}
            />
            <div className="grid grid-cols-2 gap-4">
              <Input label="Ngày hẹn *" type="date" required />
              <Input label="Giờ hẹn *" type="time" required />
            </div>
            <Input label="Nội dung / triệu chứng" placeholder="Xe kêu lạ khi đạp phanh..." />
            <div className="flex justify-end gap-2">
              <Button type="button" variant="outline" onClick={() => setShowBook(false)}>Hủy</Button>
              <Button type="submit">Xác nhận đặt lịch</Button>
            </div>
          </form>
        )}
      </Modal>
    </div>
  );
}
