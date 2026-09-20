import React, { useState } from "react";
import { Card, Button, Input, Select, Badge, Icons, Textarea } from "../components/ui";
import { dichVu, khachHang, lichHen, phieuTiepNhan, xe } from "../mock/data";

const STEPS = ["Thông tin khách", "Thông tin xe", "Lịch hẹn", "Tình trạng xe", "Phiếu tiếp nhận"];
const receptionRecord = phieuTiepNhan[0];
const selectedVehicle = xe.find((vehicle) => vehicle.MaXe === receptionRecord.MaXe)!;
const selectedCustomer = khachHang.find((customer) => customer.MaKhachHang === selectedVehicle.MaKhachHang)!;
const selectedAppointment = lichHen.find((appointment) => appointment.MaXe === selectedVehicle.MaXe)!;
const selectedService = dichVu.find((service) => service.MaDichVu === selectedAppointment.MaDichVu)!;

export default function Reception() {
  const [step, setStep] = useState(0);
  const [submitted, setSubmitted] = useState(false);

  if (submitted) {
    return (
      <div className="mx-auto max-w-2xl">
        <Card className="p-8 text-center">
          <div className="mx-auto mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-success-soft">
            <svg className="h-8 w-8 text-success" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path d="m20 6-11 11-5-5"/>
            </svg>
          </div>
          <h2 className="text-xl font-bold text-slate-800 mb-2">Tiếp nhận xe thành công!</h2>
          <p className="mb-1 text-slate-500">Phiếu tiếp nhận: <strong className="mono text-primary">{receptionRecord.MaTiepNhan}</strong></p>
          <p className="text-slate-500 mb-6">Xe <strong>{selectedVehicle.BienSo}</strong> của khách hàng <strong>{selectedCustomer.HoTen}</strong> đã được tiếp nhận.</p>
          <div className="flex gap-3 justify-center">
            <Button variant="outline" icon={Icons.printer}>In phiếu tiếp nhận</Button>
            <Button onClick={() => setSubmitted(false)}>Tiếp nhận xe khác</Button>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="mx-auto max-w-5xl">
      {/* Step indicator */}
      <div className="mb-6 flex items-center gap-2 overflow-x-auto pb-2">
        {STEPS.map((s, i) => (
          <React.Fragment key={s}>
            <button onClick={() => setStep(i)} className="flex min-h-11 flex-shrink-0 items-center gap-2 rounded-md px-1">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold border-2 transition-all ${
                i < step ? "border-success bg-success text-white" :
                i === step ? "bg-primary border-primary text-primary-foreground" :
                "bg-white border-slate-300 text-slate-400"
              }`}>
                {i < step ? "✓" : i + 1}
              </div>
              <span className={`text-sm font-medium hidden sm:block ${i <= step ? "text-slate-800" : "text-slate-400"}`}>{s}</span>
            </button>
            {i < STEPS.length - 1 && <div className={`h-0.5 flex-1 ${i < step ? "bg-success" : "bg-border"}`} />}
          </React.Fragment>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-6 xl:grid-cols-3">
        <div className="space-y-4 xl:col-span-2">
          {step === 0 && (
            <Card className="p-4 sm:p-5 lg:p-6">
              <h3 className="font-semibold text-slate-800 mb-4">Thông tin khách hàng</h3>
              <div className="space-y-4">
                <Select label="Khách hàng *" options={[
                  { value: "", label: "-- Tìm hoặc chọn khách hàng --" },
                  ...khachHang.map(customer => ({ value: customer.MaKhachHang, label: `${customer.HoTen} – ${customer.SoDienThoai}` })),
                ]} />
                <div className="rounded-lg border border-info/20 bg-info-soft p-4">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-info font-bold text-white">N</div>
                    <div>
                      <p className="font-semibold text-slate-800">{selectedCustomer.HoTen}</p>
                      <p className="text-xs text-slate-500 mono">{selectedCustomer.MaKhachHang} · {selectedCustomer.SoDienThoai}</p>
                    </div>
                  </div>
                  <p className="text-xs text-slate-500">{selectedCustomer.DiaChi} · {xe.filter(vehicle => vehicle.MaKhachHang === selectedCustomer.MaKhachHang).length} xe đăng ký</p>
                </div>
                <p className="text-xs text-muted-foreground">Chưa tìm thấy? <button type="button" className="font-medium text-primary underline">Thêm khách hàng mới</button></p>
              </div>
            </Card>
          )}

          {step === 1 && (
            <Card className="p-4 sm:p-5 lg:p-6">
              <h3 className="font-semibold text-slate-800 mb-4">Thông tin xe</h3>
              <div className="space-y-4">
                <Select label="Chọn xe *" options={[
                  { value: "", label: "-- Chọn xe --" },
                  ...xe.filter(vehicle => vehicle.MaKhachHang === selectedCustomer.MaKhachHang).map(vehicle => ({
                    value: vehicle.MaXe,
                    label: `${vehicle.BienSo} – ${vehicle.HangXe} ${vehicle.DongXe} ${vehicle.NamSanXuat}`,
                  })),
                ]} />
                <div className="rounded-lg border border-border bg-surface-subtle p-4">
                  <div className="grid grid-cols-1 gap-3 text-sm sm:grid-cols-2 lg:grid-cols-3">
                    <div><p className="mb-1 text-xs text-slate-400">Biển số</p><p className="mono font-bold text-primary">{selectedVehicle.BienSo}</p></div>
                    <div><p className="text-xs text-slate-400 mb-1">Hãng / dòng xe</p><p className="font-medium">{selectedVehicle.HangXe} {selectedVehicle.DongXe}</p></div>
                    <div><p className="text-xs text-slate-400 mb-1">Năm sản xuất</p><p className="font-medium">{selectedVehicle.NamSanXuat}</p></div>
                    <div><p className="text-xs text-slate-400 mb-1">Số km đã lưu</p><p className="font-medium">{selectedVehicle.SoKm?.toLocaleString("vi-VN")} km</p></div>
                    <div><p className="text-xs text-slate-400 mb-1">Mã xe</p><p className="font-medium mono">{selectedVehicle.MaXe}</p></div>
                    <div><p className="text-xs text-slate-400 mb-1">Mã khách hàng</p><p className="font-medium mono">{selectedVehicle.MaKhachHang}</p></div>
                  </div>
                </div>
                <Input label="Số km hiện tại *" placeholder="45200" type="number" />
              </div>
            </Card>
          )}

          {step === 2 && (
            <Card className="p-4 sm:p-5 lg:p-6">
              <h3 className="font-semibold text-slate-800 mb-4">Lịch hẹn liên quan</h3>
              <div className="space-y-3">
                <div className="flex flex-col gap-3 rounded-lg border border-info/20 bg-info-soft p-4 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <p className="font-semibold text-slate-800">{selectedAppointment.MaLichHen} – {selectedService.TenDichVu}</p>
                    <p className="text-xs text-slate-500 mt-1">{selectedAppointment.NgayHen.split("-").reverse().join("/")} lúc {selectedAppointment.GioHen} · Trạng thái: Đã xác nhận</p>
                  </div>
                  <Badge variant="confirmed" />
                </div>
                <p className="text-xs text-muted-foreground">Không có lịch hẹn? <button type="button" className="font-medium text-primary underline">Nhập yêu cầu trực tiếp</button></p>
                <Textarea label="Yêu cầu của khách hàng" defaultValue={receptionRecord.YeuCauKhachHang ?? ""} />
              </div>
            </Card>
          )}

          {step === 3 && (
            <Card className="p-4 sm:p-5 lg:p-6">
              <h3 className="font-semibold text-slate-800 mb-4">Tình trạng xe ban đầu</h3>
              <div className="space-y-3">
                {["Ngoại thất xe", "Nội thất xe", "Lốp xe", "Đèn xe", "Hệ thống điện", "Hệ thống phanh"].map(item => (
                  <div key={item} className="flex flex-col gap-3 rounded-lg bg-surface-subtle p-3 sm:flex-row sm:items-center sm:justify-between">
                    <span className="text-sm font-medium text-slate-700">{item}</span>
                    <div className="flex gap-2">
                      {["Tốt", "Bình thường", "Cần chú ý"].map(opt => (
                        <label key={opt} className="flex items-center gap-1 text-xs cursor-pointer">
                          <input type="radio" name={item} className="accent-primary" defaultChecked={opt === "Tốt"} />
                          <span className="text-slate-600">{opt}</span>
                        </label>
                      ))}
                    </div>
                  </div>
                ))}
                <Textarea label="Ghi chú tình trạng xe" placeholder="Xước nhẹ cánh cửa bên phải, lốp trước trái hơi xì..." />
              </div>
            </Card>
          )}

          {step === 4 && (
            <Card className="p-4 sm:p-5 lg:p-6">
              <h3 className="font-semibold text-slate-800 mb-4">Xác nhận phiếu tiếp nhận</h3>
              <div className="mb-4 grid grid-cols-1 gap-4 text-sm sm:grid-cols-2">
                <div className="rounded-lg bg-surface-subtle p-3"><p className="mb-1 text-xs text-muted-foreground">Khách hàng</p><p className="font-semibold">{selectedCustomer.HoTen}</p></div>
                <div className="rounded-lg bg-surface-subtle p-3"><p className="mb-1 text-xs text-slate-400">Biển số xe</p><p className="mono font-bold text-primary">{selectedVehicle.BienSo}</p></div>
                <div className="rounded-lg bg-surface-subtle p-3"><p className="mb-1 text-xs text-muted-foreground">Số km</p><p className="font-semibold">{selectedVehicle.SoKm?.toLocaleString("vi-VN")} km</p></div>
                <div className="rounded-lg bg-surface-subtle p-3"><p className="mb-1 text-xs text-muted-foreground">Thời gian tiếp nhận</p><p className="font-semibold">{new Date(receptionRecord.NgayTiepNhan).toLocaleString("vi-VN")}</p></div>
              </div>
              <div className="mb-4 rounded-lg border border-warning/25 bg-warning-soft p-3">
                <p className="text-xs font-medium text-warning">Yêu cầu khách: {receptionRecord.YeuCauKhachHang}</p>
              </div>
              <Input label="Ghi chú" defaultValue={receptionRecord.GhiChu ?? ""} placeholder="Ghi chú cho phiếu tiếp nhận" />
            </Card>
          )}

          {/* Navigation */}
          <div className="flex justify-between">
            <Button variant="outline" onClick={() => setStep(Math.max(0, step - 1))} disabled={step === 0}>← Quay lại</Button>
            {step < STEPS.length - 1
              ? <Button onClick={() => setStep(step + 1)}>Tiếp theo →</Button>
              : <Button icon={Icons.checkCircle} onClick={() => setSubmitted(true)}>Lập phiếu tiếp nhận</Button>
            }
          </div>
        </div>

        {/* Summary panel */}
        <Card className="detail-panel h-fit p-4 sm:p-5 lg:p-6">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-4">Tóm tắt</p>
          <div className="space-y-3 text-sm">
            <div>
              <p className="text-xs text-slate-400">Khách hàng</p>
              <p className="font-semibold text-slate-800">{step >= 0 ? selectedCustomer.HoTen : "—"}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Xe</p>
              <p className="mono font-bold text-primary">{step >= 1 ? selectedVehicle.BienSo : "—"}</p>
              <p className="text-xs text-slate-500">{step >= 1 ? `${selectedVehicle.HangXe} ${selectedVehicle.DongXe} ${selectedVehicle.NamSanXuat}` : ""}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Lịch hẹn</p>
              <p className="font-semibold">{step >= 2 ? selectedAppointment.MaLichHen : "—"}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Yêu cầu</p>
              <p className="text-slate-700 text-xs leading-relaxed">{step >= 2 ? receptionRecord.YeuCauKhachHang : "—"}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Số km</p>
              <p className="font-semibold">{step >= 1 ? `${selectedVehicle.SoKm?.toLocaleString("vi-VN")} km` : "—"}</p>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}
