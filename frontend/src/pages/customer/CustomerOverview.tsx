import { Badge, Button, Card, Icons } from "../../components/ui";
import type { CustomerPage } from "../../router";
import { baoGia, lichHen, phieuSuaChua, phieuTiepNhan, xe } from "../../mock/data";
import { thongBao } from "../../mock/schemaData";

const CUSTOMER_ID = "KH001";

interface CustomerOverviewProps {
  onNavigate: (page: CustomerPage) => void;
}

export default function CustomerOverview({ onNavigate }: CustomerOverviewProps) {
  const myVehicles = xe.filter((vehicle) => vehicle.MaKhachHang === CUSTOMER_ID);
  const vehicleIds = new Set(myVehicles.map((vehicle) => vehicle.MaXe));
  const myReceptions = phieuTiepNhan.filter((reception) => vehicleIds.has(reception.MaXe));
  const receptionIds = new Set(myReceptions.map((reception) => reception.MaTiepNhan));
  const myRepairs = phieuSuaChua.filter((repair) => receptionIds.has(repair.MaTiepNhan));
  const repairIds = new Set(myRepairs.map((repair) => repair.MaPhieuSuaChua));
  const activeRepairs = myRepairs.filter((repair) => repair.TrangThai !== "completed");
  const myAppointments = lichHen.filter((appointment) => appointment.MaKhachHang === CUSTOMER_ID);
  const upcomingAppointments = myAppointments.filter((appointment) => ["pending", "confirmed"].includes(appointment.TrangThai));
  const pendingQuotations = baoGia.filter((quotation) => repairIds.has(quotation.MaPhieuSuaChua) && quotation.TrangThai === "pending");
  const unreadNotices = thongBao.filter((notice) => notice.MaKhachHang === CUSTOMER_ID && !notice.DaDoc);
  const nextAppointment = upcomingAppointments[0];
  const activeRepair = activeRepairs[0];
  const activeReception = myReceptions.find((reception) => reception.MaTiepNhan === activeRepair?.MaTiepNhan);
  const activeVehicle = myVehicles.find((vehicle) => vehicle.MaXe === activeReception?.MaXe);

  const summaries = [
    { label: "Xe của tôi", value: myVehicles.length, icon: Icons.car, tint: "bg-primary-soft text-primary" },
    { label: "Lịch hẹn sắp tới", value: upcomingAppointments.length, icon: Icons.calendar, tint: "bg-info-soft text-info" },
    { label: "Xe đang trong xưởng", value: activeRepairs.length, icon: Icons.wrench, tint: "bg-warning-soft text-warning" },
    { label: "Thông báo chưa đọc", value: unreadNotices.length, icon: Icons.bell, tint: "bg-danger-soft text-danger" },
  ];

  return (
    <div className="space-y-6">
      <div>
        <p className="text-xs font-bold uppercase tracking-widest text-accent">Khu vực khách hàng</p>
        <h1 className="ui-page-title mt-1 text-brand-dark">Tổng quan xe &amp; dịch vụ</h1>
        <p className="ui-secondary-text mt-1 text-sm">Theo dõi lịch hẹn, báo giá và tiến độ sửa chữa trong một nơi.</p>
      </div>

      <section aria-label="Chỉ số tổng quan" className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {summaries.map((item) => (
          <Card key={item.label} className="flex min-h-28 items-center gap-4 p-4">
            <span className={`flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-lg ${item.tint}`} aria-hidden="true">{item.icon}</span>
            <div><p className="text-2xl font-extrabold text-foreground">{item.value}</p><p className="text-xs text-muted-foreground">{item.label}</p></div>
          </Card>
        ))}
      </section>

      <div className="grid gap-4 lg:grid-cols-2">
        <Card className="p-4 sm:p-5">
          <div className="flex items-center justify-between gap-3">
            <h2 className="ui-card-title">Lịch hẹn gần nhất</h2>
            <Button size="sm" variant="ghost" onClick={() => onNavigate("appointments")}>Xem lịch hẹn</Button>
          </div>
          {nextAppointment ? (
            <div className="mt-4 rounded-lg bg-surface-subtle p-4">
              <div className="flex items-start justify-between gap-3">
                <div><p className="mono font-bold text-primary">{myVehicles.find((vehicle) => vehicle.MaXe === nextAppointment.MaXe)?.BienSo}</p><p className="mt-1 text-sm text-muted-foreground">{nextAppointment.NoiDung || "Kiểm tra và tư vấn tại gara"}</p></div>
                <Badge variant={nextAppointment.TrangThai === "confirmed" ? "confirmed" : "pending"} label={nextAppointment.TrangThai === "confirmed" ? "Đã xác nhận" : "Chờ xác nhận"} />
              </div>
              <p className="mt-3 text-sm font-semibold text-foreground">{nextAppointment.NgayHen} · {nextAppointment.GioHen}</p>
            </div>
          ) : <p className="mt-4 text-sm text-muted-foreground">Chưa có lịch hẹn sắp tới.</p>}
        </Card>

        <Card className="p-4 sm:p-5">
          <div className="flex items-center justify-between gap-3">
            <h2 className="ui-card-title">Tiến độ hiện tại</h2>
            <Button size="sm" variant="ghost" onClick={() => onNavigate("tracking")}>Theo dõi chi tiết</Button>
          </div>
          {activeRepair ? (
            <div className="mt-4 rounded-lg bg-surface-subtle p-4">
              <div className="flex items-start justify-between gap-3">
                <div><p className="mono font-bold text-primary">{activeVehicle?.BienSo}</p><p className="mt-1 text-xs text-muted-foreground">Phiếu {activeRepair.MaPhieuSuaChua}</p></div>
                <Badge variant={activeRepair.TrangThai === "waiting_parts" ? "waiting_parts" : "in_progress"} />
              </div>
              <div className="mt-4 h-2 overflow-hidden rounded-full bg-border"><div className="h-full w-2/3 rounded-full bg-primary" /></div>
              <p className="mt-2 text-xs text-muted-foreground">Gara đang cập nhật tiến độ theo từng bước thực hiện.</p>
            </div>
          ) : <p className="mt-4 text-sm text-muted-foreground">Không có xe nào đang sửa chữa.</p>}
        </Card>
      </div>

      {pendingQuotations.length > 0 && (
        <Card className="flex flex-col gap-4 border-warning/30 bg-warning-soft p-4 sm:flex-row sm:items-center sm:justify-between sm:p-5">
          <div><p className="font-semibold text-foreground">Bạn có {pendingQuotations.length} báo giá đang chờ xác nhận</p><p className="mt-1 text-sm text-muted-foreground">Xem đầy đủ hạng mục và chi phí trước khi gara thực hiện.</p></div>
          <Button onClick={() => onNavigate("quotations")}>Xem báo giá</Button>
        </Card>
      )}

      <section aria-label="Thao tác nhanh" className="grid gap-3 sm:flex sm:flex-wrap">
        <Button icon={Icons.plus} onClick={() => onNavigate("appointments")}>Đặt lịch mới</Button>
        <Button variant="outline" icon={Icons.history} onClick={() => onNavigate("history")}>Xem lịch sử</Button>
        <Button variant="outline" icon={Icons.userCheck} onClick={() => onNavigate("profile")}>Hồ sơ cá nhân</Button>
      </section>
    </div>
  );
}
