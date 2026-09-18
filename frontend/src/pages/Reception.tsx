import React, { useState } from "react";
import { Card, Button, Input, Select, Badge, Icons, TimelineItem } from "../components/ui";
import { mockCustomers, mockVehicles, mockAppointments } from "../data";

const STEPS = ["Thông tin khách", "Thông tin xe", "Lịch hẹn", "Tình trạng xe", "Phiếu tiếp nhận"];

export default function Reception() {
  const [step, setStep] = useState(0);
  const [submitted, setSubmitted] = useState(false);

  if (submitted) {
    return (
      <div className="p-6 max-w-2xl mx-auto">
        <Card className="p-8 text-center">
          <div className="w-16 h-16 bg-emerald-100 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-emerald-600" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path d="m20 6-11 11-5-5"/>
            </svg>
          </div>
          <h2 className="text-xl font-bold text-slate-800 mb-2">Tiếp nhận xe thành công!</h2>
          <p className="text-slate-500 mb-1">Phiếu tiếp nhận: <strong className="text-[#1e3a6e] mono">PTN-2024-0017</strong></p>
          <p className="text-slate-500 mb-6">Xe <strong>51G-123.45</strong> của khách hàng <strong>Nguyễn Văn An</strong> đã được tiếp nhận.</p>
          <div className="flex gap-3 justify-center">
            <Button variant="outline" icon={Icons.printer}>In phiếu tiếp nhận</Button>
            <Button onClick={() => setSubmitted(false)}>Tiếp nhận xe khác</Button>
          </div>
        </Card>
      </div>
    );
  }

  return (
    <div className="p-6 max-w-5xl mx-auto">
      {/* Step indicator */}
      <div className="flex items-center gap-2 mb-8">
        {STEPS.map((s, i) => (
          <React.Fragment key={s}>
            <button onClick={() => setStep(i)} className="flex items-center gap-2">
              <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold border-2 transition-all ${
                i < step ? "bg-emerald-500 border-emerald-500 text-white" :
                i === step ? "bg-[#1e3a6e] border-[#1e3a6e] text-white" :
                "bg-white border-slate-300 text-slate-400"
              }`}>
                {i < step ? "✓" : i + 1}
              </div>
              <span className={`text-sm font-medium hidden sm:block ${i <= step ? "text-slate-800" : "text-slate-400"}`}>{s}</span>
            </button>
            {i < STEPS.length - 1 && <div className={`flex-1 h-0.5 ${i < step ? "bg-emerald-400" : "bg-slate-200"}`} />}
          </React.Fragment>
        ))}
      </div>

      <div className="grid grid-cols-3 gap-5">
        <div className="col-span-2 space-y-4">
          {step === 0 && (
            <Card className="p-6">
              <h3 className="font-semibold text-slate-800 mb-4">Thông tin khách hàng</h3>
              <div className="space-y-4">
                <Select label="Khách hàng *" options={[
                  { value: "", label: "-- Tìm hoặc chọn khách hàng --" },
                  ...mockCustomers.map(c => ({ value: c.id, label: `${c.name} – ${c.phone}` })),
                ]} />
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-xl">
                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-10 h-10 bg-blue-500 rounded-xl flex items-center justify-center text-white font-bold">N</div>
                    <div>
                      <p className="font-semibold text-slate-800">Nguyễn Văn An</p>
                      <p className="text-xs text-slate-500 mono">KH001 · 0901234567</p>
                    </div>
                    <span className="ml-auto text-xs text-blue-700 bg-blue-100 px-2 py-1 rounded-full font-medium">Khách quen</span>
                  </div>
                  <p className="text-xs text-slate-500">123 Lê Lợi, Q.1, TP.HCM · 2 xe đăng ký · Lần cuối: 15/08/2024</p>
                </div>
                <p className="text-xs text-slate-400">Chưa tìm thấy? <button className="text-blue-600 underline">Thêm khách hàng mới</button></p>
              </div>
            </Card>
          )}

          {step === 1 && (
            <Card className="p-6">
              <h3 className="font-semibold text-slate-800 mb-4">Thông tin xe</h3>
              <div className="space-y-4">
                <Select label="Chọn xe *" options={[
                  { value: "", label: "-- Chọn xe --" },
                  { value: "XE001", label: "51G-123.45 – Toyota Camry 2020" },
                  { value: "XE002", label: "51A-456.78 – Honda CR-V 2019" },
                ]} />
                <div className="p-4 bg-slate-50 rounded-xl border border-[#dde3ec]">
                  <div className="grid grid-cols-3 gap-3 text-sm">
                    <div><p className="text-xs text-slate-400 mb-1">Biển số</p><p className="font-mono font-bold text-[#1e3a6e]">51G-123.45</p></div>
                    <div><p className="text-xs text-slate-400 mb-1">Hãng xe</p><p className="font-medium">Toyota Camry</p></div>
                    <div><p className="text-xs text-slate-400 mb-1">Năm sản xuất</p><p className="font-medium">2020</p></div>
                    <div><p className="text-xs text-slate-400 mb-1">Màu sắc</p><p className="font-medium">Đen</p></div>
                    <div><p className="text-xs text-slate-400 mb-1">Bảo dưỡng cuối</p><p className="font-medium">15/08/2024</p></div>
                    <div><p className="text-xs text-slate-400 mb-1">Bảo dưỡng tiếp</p><p className="font-medium text-amber-600">15/11/2024</p></div>
                  </div>
                </div>
                <Input label="Số km hiện tại *" placeholder="45200" type="number" />
              </div>
            </Card>
          )}

          {step === 2 && (
            <Card className="p-6">
              <h3 className="font-semibold text-slate-800 mb-4">Lịch hẹn liên quan</h3>
              <div className="space-y-3">
                <div className="p-4 bg-blue-50 border border-blue-200 rounded-xl flex items-center justify-between">
                  <div>
                    <p className="font-semibold text-slate-800">LH001 – Bảo dưỡng định kỳ 45.000 km</p>
                    <p className="text-xs text-slate-500 mt-1">17/09/2024 lúc 08:00 · Trạng thái: Đã xác nhận</p>
                  </div>
                  <Badge variant="confirmed" />
                </div>
                <p className="text-xs text-slate-400">Không có lịch hẹn? <button className="text-blue-600 underline">Nhập yêu cầu trực tiếp</button></p>
                <div>
                  <label className="text-xs font-medium text-slate-600 block mb-1">Yêu cầu của khách hàng</label>
                  <textarea className="w-full border border-[#dde3ec] rounded-lg text-sm px-3 py-2 h-20 resize-none focus:border-[#3b6fd4] focus:outline-none" defaultValue="Bảo dưỡng định kỳ, thay dầu, kiểm tra tổng quát" />
                </div>
              </div>
            </Card>
          )}

          {step === 3 && (
            <Card className="p-6">
              <h3 className="font-semibold text-slate-800 mb-4">Tình trạng xe ban đầu</h3>
              <div className="space-y-3">
                {["Ngoại thất xe", "Nội thất xe", "Lốp xe", "Đèn xe", "Hệ thống điện", "Hệ thống phanh"].map(item => (
                  <div key={item} className="flex items-center justify-between p-3 bg-slate-50 rounded-lg">
                    <span className="text-sm font-medium text-slate-700">{item}</span>
                    <div className="flex gap-2">
                      {["Tốt", "Bình thường", "Cần chú ý"].map(opt => (
                        <label key={opt} className="flex items-center gap-1 text-xs cursor-pointer">
                          <input type="radio" name={item} className="accent-[#1e3a6e]" defaultChecked={opt === "Tốt"} />
                          <span className="text-slate-600">{opt}</span>
                        </label>
                      ))}
                    </div>
                  </div>
                ))}
                <div>
                  <label className="text-xs font-medium text-slate-600 block mb-1">Ghi chú tình trạng xe</label>
                  <textarea className="w-full border border-[#dde3ec] rounded-lg text-sm px-3 py-2 h-16 resize-none focus:border-[#3b6fd4] focus:outline-none" placeholder="Xước nhẹ cánh cửa bên phải, lốp trước trái hơi xì..." />
                </div>
              </div>
            </Card>
          )}

          {step === 4 && (
            <Card className="p-6">
              <h3 className="font-semibold text-slate-800 mb-4">Xác nhận phiếu tiếp nhận</h3>
              <div className="grid grid-cols-2 gap-4 text-sm mb-4">
                <div className="p-3 bg-slate-50 rounded-lg"><p className="text-xs text-slate-400 mb-1">Khách hàng</p><p className="font-semibold">Nguyễn Văn An</p></div>
                <div className="p-3 bg-slate-50 rounded-lg"><p className="text-xs text-slate-400 mb-1">Biển số xe</p><p className="font-mono font-bold text-[#1e3a6e]">51G-123.45</p></div>
                <div className="p-3 bg-slate-50 rounded-lg"><p className="text-xs text-slate-400 mb-1">Số km</p><p className="font-semibold">45,200 km</p></div>
                <div className="p-3 bg-slate-50 rounded-lg"><p className="text-xs text-slate-400 mb-1">Thời gian tiếp nhận</p><p className="font-semibold">08:05 – 17/09/2024</p></div>
              </div>
              <div className="p-3 bg-amber-50 border border-amber-200 rounded-lg mb-4">
                <p className="text-xs font-medium text-amber-800">Yêu cầu khách: Bảo dưỡng định kỳ, thay dầu, kiểm tra tổng quát</p>
              </div>
              <Select label="Phân công kỹ thuật viên kiểm tra" options={[
                { value: "NV002", label: "Trần Văn Khoa" },
                { value: "NV003", label: "Nguyễn Thành Long" },
                { value: "NV004", label: "Lê Quang Hưng" },
              ]} />
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
        <Card className="p-5 h-fit">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-4">Tóm tắt</p>
          <div className="space-y-3 text-sm">
            <div>
              <p className="text-xs text-slate-400">Khách hàng</p>
              <p className="font-semibold text-slate-800">{step >= 0 ? "Nguyễn Văn An" : "—"}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Xe</p>
              <p className="font-mono font-bold text-[#1e3a6e]">{step >= 1 ? "51G-123.45" : "—"}</p>
              <p className="text-xs text-slate-500">{step >= 1 ? "Toyota Camry 2020" : ""}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Lịch hẹn</p>
              <p className="font-semibold">{step >= 2 ? "LH001" : "—"}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Yêu cầu</p>
              <p className="text-slate-700 text-xs leading-relaxed">{step >= 2 ? "Bảo dưỡng định kỳ, thay dầu" : "—"}</p>
            </div>
            <div>
              <p className="text-xs text-slate-400">Số km</p>
              <p className="font-semibold">{step >= 1 ? "45,200 km" : "—"}</p>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}
