import { useMemo, useState } from "react";
import BookingCalendar from "../../components/booking/BookingCalendar";
import TimeSlotPicker from "../../components/booking/TimeSlotPicker";
import { Badge, Button, Card, Icons, Modal } from "../../components/ui";
import AddVehicleModal from "../../features/vehicles/AddVehicleModal";
import { useCustomerVehicles } from "../../features/vehicles/customerVehicleRepository";
import {
  SIMULATED_CONFLICT,
  formatBookingDate,
  getSuggestedBookingSlots,
} from "../../mock/bookingAvailability";
import { dichVu, formatCurrency, lichHen, type AppointmentStatus } from "../../mock/data";

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

export default function CustomerAppointments({ customerKey, onBooked }: { customerKey: string; onBooked?: () => void }) {
  const { vehicles: myVehicles, addVehicle } = useCustomerVehicles(customerKey);
  const [showBook, setShowBook] = useState(false);
  const [showAddVehicle, setShowAddVehicle] = useState(false);
  const [vehicleSuccess, setVehicleSuccess] = useState("");
  const [done, setDone] = useState(false);
  const [bookingStep, setBookingStep] = useState(1);
  const [selectedVehicle, setSelectedVehicle] = useState("");
  const [selectedService, setSelectedService] = useState("");
  const [selectedDate, setSelectedDate] = useState("");
  const [selectedTime, setSelectedTime] = useState("");
  const [unavailableSlots, setUnavailableSlots] = useState<Set<string>>(() => new Set());
  const [conflict, setConflict] = useState<{ date: string; time: string } | null>(null);

  const myAppointments = useMemo(
    () => lichHen.filter((a) => a.MaKhachHang === customerKey),
    [customerKey],
  );

  const vehiclePlate = (id: string) => myVehicles.find((vehicle) => vehicle.MaXe === id)?.BienSo ?? id;
  const serviceName = (id: string | null) => dichVu.find((s) => s.MaDichVu === id)?.TenDichVu ?? "Tư vấn chung";

  const openBooking = () => {
    setBookingStep(1);
    setSelectedVehicle("");
    setSelectedService("");
    setSelectedDate("");
    setSelectedTime("");
    setUnavailableSlots(new Set());
    setConflict(null);
    setVehicleSuccess("");
    setDone(false);
    setShowBook(true);
  };

  const closeBooking = () => {
    setConflict(null);
    setShowBook(false);
  };

  const chooseDate = (dateKey: string) => {
    setSelectedDate(dateKey);
    setSelectedTime("");
  };

  const chooseTime = (time: string) => {
    const slotKey = `${selectedDate}|${time}`;
    const shouldSimulateConflict = selectedDate === SIMULATED_CONFLICT.date
      && time === SIMULATED_CONFLICT.time
      && !unavailableSlots.has(slotKey);

    if (shouldSimulateConflict) {
      setUnavailableSlots((current) => new Set(current).add(slotKey));
      setSelectedTime("");
      setConflict({ date: selectedDate, time });
      return;
    }

    setSelectedTime(time);
  };

  const canContinue = bookingStep === 1
    ? Boolean(selectedVehicle)
    : bookingStep === 2
      ? Boolean(selectedService)
      : Boolean(selectedDate && selectedTime);

  const conflictSuggestions = conflict
    ? getSuggestedBookingSlots(conflict.date, unavailableSlots)
    : [];

  return (
    <div className="space-y-6">
      <div className="page-toolbar">
        <div>
          <h2 className="ui-section-title">Lịch hẹn của tôi</h2>
          <p className="ui-secondary-text text-sm">{myAppointments.length} lịch hẹn · {myVehicles.length} xe</p>
        </div>
        <Button icon={Icons.plus} onClick={openBooking}>Đặt lịch mới</Button>
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
              <Card className="h-full p-4 sm:p-5">
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

      <Modal open={showBook} onClose={closeBooking} title="Đặt lịch sửa chữa / bảo dưỡng" width="max-w-5xl">
        {done ? (
          <div className="py-6 text-center">
            <span className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-success-soft text-success" aria-hidden="true">
              {Icons.checkCircle}
            </span>
            <p className="ui-card-title mt-3">Đã đặt lịch</p>
            <p className="ui-secondary-text mt-1 text-sm">Gara sẽ kiểm tra và xác nhận giờ hẹn trong giờ làm việc.</p>
            <dl className="mx-auto mt-5 grid max-w-lg gap-3 rounded-lg border border-border bg-surface-subtle p-4 text-left text-sm sm:grid-cols-2">
              <div><dt className="text-xs text-muted-foreground">Xe</dt><dd className="mt-1 font-bold text-foreground">{vehiclePlate(selectedVehicle)}</dd></div>
              <div><dt className="text-xs text-muted-foreground">Dịch vụ</dt><dd className="mt-1 font-bold text-foreground">{serviceName(selectedService)}</dd></div>
              <div><dt className="text-xs text-muted-foreground">Ngày hẹn</dt><dd className="mt-1 font-bold text-foreground">{formatBookingDate(selectedDate)}</dd></div>
              <div><dt className="text-xs text-muted-foreground">Giờ hẹn</dt><dd className="mono mt-1 font-bold text-primary">{selectedTime}</dd></div>
            </dl>
            <div className="mt-4 flex justify-center">
              <Button variant="outline" onClick={() => { closeBooking(); onBooked?.(); }}>Đóng</Button>
            </div>
          </div>
        ) : (
          <div className="space-y-5">
            <ol className="grid grid-cols-3 gap-2" aria-label={`Bước ${bookingStep} trên 3`}>
              {["Chọn xe", "Dịch vụ", "Ngày & giờ"].map((label, index) => {
                const stepNumber = index + 1;
                const active = bookingStep === stepNumber;
                const completed = bookingStep > stepNumber;
                return (
                  <li key={label} aria-current={active ? "step" : undefined} className={`flex min-w-0 items-center gap-1 rounded-md border px-1.5 py-2.5 sm:gap-2 sm:px-3 ${active ? "border-primary bg-primary-soft" : completed ? "border-success/25 bg-success-soft" : "border-border bg-surface-subtle"}`}>
                    <span className={`flex h-7 w-7 flex-shrink-0 items-center justify-center rounded-full text-xs font-bold ${active ? "bg-primary text-white" : completed ? "bg-success text-white" : "bg-muted text-muted-foreground"}`} aria-hidden="true">
                      {completed ? Icons.check : stepNumber}
                    </span>
                    <span className={`text-[11px] font-semibold leading-tight sm:text-sm ${active ? "text-primary" : completed ? "text-success" : "text-muted-foreground"}`}>{label}</span>
                  </li>
                );
              })}
            </ol>

            <div key={bookingStep} className="booking-step-enter">
              {bookingStep === 1 && (
                <section aria-labelledby="booking-vehicle-title" className="mx-auto max-w-3xl">
                  <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
                    <div>
                      <p className="text-xs font-bold uppercase tracking-[0.12em] text-accent">Bước 1</p>
                      <h3 id="booking-vehicle-title" className="mt-1 text-lg font-bold text-foreground">Chọn xe</h3>
                      <p className="mt-1 text-sm text-muted-foreground">Chọn xe bạn muốn đặt lịch.</p>
                    </div>
                    <Button type="button" size="sm" variant="outline" icon={Icons.plus} onClick={() => setShowAddVehicle(true)}>Thêm xe mới</Button>
                  </div>
                  {vehicleSuccess && <p className="mb-4 rounded-md bg-success-soft px-4 py-3 text-sm text-success" role="status">{vehicleSuccess}</p>}
                  {myVehicles.length === 0 ? (
                    <div className="rounded-lg border border-dashed border-border bg-surface-subtle p-6 text-center">
                      <span className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-primary-soft text-primary" aria-hidden="true">{Icons.car}</span>
                      <p className="mt-3 font-bold text-foreground">Bạn chưa có xe nào</p>
                      <p className="mt-1 text-sm text-muted-foreground">Thêm xe để tiếp tục đặt lịch.</p>
                      <Button className="mt-4" type="button" icon={Icons.plus} onClick={() => setShowAddVehicle(true)}>Thêm xe mới</Button>
                    </div>
                  ) : <div className="grid gap-3 sm:grid-cols-2">
                    {myVehicles.map((vehicle) => {
                      const selected = selectedVehicle === vehicle.MaXe;
                      const vehicleDetails = [vehicle.HangXe, vehicle.DongXe, vehicle.NamSanXuat].filter(Boolean).join(" · ") || "Chưa cập nhật thông tin xe";
                      return (
                        <button
                          key={vehicle.MaXe}
                          type="button"
                          aria-pressed={selected}
                          onClick={() => setSelectedVehicle(vehicle.MaXe)}
                          className={`motion-button flex min-h-20 items-center gap-3 rounded-lg border p-4 text-left ${selected ? "border-primary bg-primary-soft ring-1 ring-primary" : "border-border bg-white hover:border-primary"}`}
                        >
                          <span className={`flex h-11 w-11 flex-shrink-0 items-center justify-center rounded-md ${selected ? "bg-primary text-white" : "bg-surface-subtle text-primary"}`} aria-hidden="true">{Icons.car}</span>
                          <span className="min-w-0 flex-1"><span className="mono block font-bold text-primary">{vehicle.BienSo}</span><span className="mt-1 block text-xs text-muted-foreground">{vehicleDetails}</span></span>
                          {selected && <span className="text-primary" aria-hidden="true">{Icons.checkCircle}</span>}
                        </button>
                      );
                    })}
                  </div>}
                </section>
              )}

              {bookingStep === 2 && (
                <section aria-labelledby="booking-service-title" className="mx-auto max-w-3xl">
                  <div className="mb-4">
                    <p className="text-xs font-bold uppercase tracking-[0.12em] text-accent">Bước 2</p>
                    <h3 id="booking-service-title" className="mt-1 text-lg font-bold text-foreground">Chọn dịch vụ cần thực hiện</h3>
                  </div>
                  <div className="grid max-h-[50vh] gap-2 overflow-y-auto pr-1 sm:grid-cols-2">
                    {dichVu.map((service) => {
                      const selected = selectedService === service.MaDichVu;
                      return (
                        <button
                          key={service.MaDichVu}
                          type="button"
                          aria-pressed={selected}
                          onClick={() => setSelectedService(service.MaDichVu)}
                          className={`motion-button flex min-h-16 items-center justify-between gap-3 rounded-lg border p-3 text-left ${selected ? "border-primary bg-primary-soft ring-1 ring-primary" : "border-border bg-white hover:border-primary"}`}
                        >
                          <span className="min-w-0"><span className="block text-sm font-semibold text-foreground">{service.TenDichVu}</span><span className="mt-1 block text-xs text-muted-foreground">{service.LoaiDichVu} · Từ {formatCurrency(service.DonGia)}</span></span>
                          {selected && <span className="flex-shrink-0 text-primary" aria-hidden="true">{Icons.checkCircle}</span>}
                        </button>
                      );
                    })}
                  </div>
                </section>
              )}

              {bookingStep === 3 && (
                <section aria-labelledby="booking-datetime-title" className="mx-auto w-full max-w-5xl text-left">
                  <div className="mb-5 text-left">
                    <p className="text-xs font-bold uppercase tracking-[0.12em] text-accent">Bước 3</p>
                    <h3 id="booking-datetime-title" className="mt-1 text-xl font-bold text-foreground">Chọn ngày đặt lịch</h3>
                    <p className="mt-1 text-sm text-muted-foreground">Chọn ngày và khung giờ phù hợp để mang xe đến gara.</p>
                  </div>
                  <div className="grid overflow-hidden rounded-lg border border-border bg-white lg:grid-cols-[minmax(0,1.08fr)_minmax(320px,0.92fr)]">
                    <BookingCalendar selectedDate={selectedDate} onSelectDate={chooseDate} />
                    <TimeSlotPicker selectedDate={selectedDate} selectedTime={selectedTime} unavailableSlots={unavailableSlots} onSelectTime={chooseTime} />
                  </div>
                </section>
              )}
            </div>

            <div className="flex flex-col-reverse gap-2 border-t border-border pt-4 sm:flex-row sm:items-center sm:justify-between">
              <Button type="button" variant="outline" icon={bookingStep > 1 ? Icons.arrowLeft : undefined} onClick={() => bookingStep > 1 ? setBookingStep((current) => current - 1) : closeBooking()}>
                {bookingStep > 1 ? "Quay lại" : "Hủy"}
              </Button>
              <Button
                type="button"
                disabled={!canContinue}
                icon={bookingStep === 3 ? Icons.check : Icons.arrowRight}
                onClick={() => bookingStep < 3 ? setBookingStep((current) => current + 1) : setDone(true)}
              >
                {bookingStep === 3 ? "Xác nhận đặt lịch" : "Tiếp tục"}
              </Button>
            </div>
          </div>
        )}
      </Modal>

      <Modal open={Boolean(conflict)} onClose={() => setConflict(null)} title="Khung giờ không còn trống" width="max-w-md">
        {conflict && (
          <div>
            <div className="flex gap-3 rounded-lg border border-danger/20 bg-danger-soft p-4">
              <span className="mt-0.5 flex-shrink-0 text-danger" aria-hidden="true">{Icons.alertCircle}</span>
              <div>
                <p className="font-semibold text-danger">Khung giờ {conflict.time} hiện không còn trống.</p>
                <p className="mt-1 text-sm leading-6 text-slate-700">{formatBookingDate(conflict.date)} vừa có lịch hẹn khác được ghi nhận. Vui lòng chọn một giờ thay thế.</p>
              </div>
            </div>

            <p className="mt-5 text-sm font-semibold text-foreground">Bạn có thể chọn:</p>
            <div className="mt-3 grid grid-cols-3 gap-2">
              {conflictSuggestions.map((time) => (
                <button
                  key={time}
                  type="button"
                  onClick={() => { setSelectedTime(time); setConflict(null); }}
                  className="motion-button min-h-12 rounded-md border border-border bg-white font-mono text-sm font-bold text-primary hover:border-primary hover:bg-primary-soft"
                >
                  {time}
                </button>
              ))}
            </div>
            <div className="mt-5 flex justify-end">
              <Button type="button" variant="outline" onClick={() => setConflict(null)}>Chọn giờ khác</Button>
            </div>
          </div>
        )}
      </Modal>

      <AddVehicleModal
        open={showAddVehicle}
        onClose={() => setShowAddVehicle(false)}
        onSubmit={addVehicle}
        onCreated={(vehicle) => {
          setSelectedVehicle(vehicle.MaXe);
          setVehicleSuccess("Đã thêm xe.");
        }}
      />
    </div>
  );
}
