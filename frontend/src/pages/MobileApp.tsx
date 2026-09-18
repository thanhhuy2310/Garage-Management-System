import React, { useState } from "react";
import { Badge, TimelineItem } from "../components/ui";
import { formatCurrency } from "../data";
import { mockQuotations, calcTotal } from "../data";

type MobileScreen = "home" | "book" | "track" | "quote" | "history" | "account";
type BookStep = 0 | 1 | 2 | 3 | 4;

const NAV = [
  { key: "home", icon: "🏠", label: "Trang chủ" },
  { key: "book", icon: "📅", label: "Lịch hẹn" },
  { key: "track", icon: "🔧", label: "Xe của tôi" },
  { key: "history", icon: "📋", label: "Lịch sử" },
  { key: "account", icon: "👤", label: "Tài khoản" },
];

function MobileHome({ onNavigate }: { onNavigate: (s: MobileScreen) => void }) {
  return (
    <div className="flex-1 overflow-y-auto">
      {/* Header */}
      <div className="bg-[#1e3a6e] px-4 pt-10 pb-8">
        <div className="flex items-center justify-between mb-1">
          <div>
            <p className="text-white/70 text-sm">Xin chào 👋</p>
            <p className="text-white font-bold text-lg">Nguyễn Văn An</p>
          </div>
          <div className="relative">
            <div className="w-10 h-10 bg-white/20 rounded-full flex items-center justify-center text-white">🔔</div>
            <span className="absolute -top-1 -right-1 w-4 h-4 bg-red-500 text-white text-[9px] rounded-full flex items-center justify-center font-bold">2</span>
          </div>
        </div>
      </div>

      {/* Car in repair card */}
      <div className="px-4 -mt-4">
        <div className="bg-white rounded-2xl p-4 shadow-lg border border-[#dde3ec]">
          <div className="flex items-center justify-between mb-3">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Xe đang sửa chữa</p>
            <button onClick={() => onNavigate("track")} className="text-xs text-blue-600 font-medium">Xem chi tiết →</button>
          </div>
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-[#e8eef7] rounded-xl flex items-center justify-center text-2xl">🚗</div>
            <div>
              <p className="font-mono font-bold text-[#1e3a6e]">51G-123.45</p>
              <p className="text-xs text-slate-500">Toyota Camry 2020</p>
            </div>
          </div>
          {/* Progress bar */}
          <div className="mt-3">
            <div className="flex items-center justify-between mb-1">
              <span className="text-xs text-slate-600 font-medium">Đang sửa chữa</span>
              <span className="text-xs text-blue-600 font-semibold">65%</span>
            </div>
            <div className="h-2 bg-slate-100 rounded-full overflow-hidden">
              <div className="h-full bg-gradient-to-r from-blue-500 to-[#1e3a6e] rounded-full" style={{ width: "65%" }} />
            </div>
          </div>
        </div>
      </div>

      <div className="px-4 mt-4 space-y-3">
        {/* Quick actions */}
        <div className="grid grid-cols-2 gap-3">
          <button onClick={() => onNavigate("book")}
            className="bg-[#1e3a6e] text-white rounded-2xl p-4 text-left hover:bg-[#162d56] transition-all">
            <div className="text-2xl mb-2">📅</div>
            <p className="font-semibold text-sm">Đặt lịch hẹn</p>
            <p className="text-white/60 text-xs mt-0.5">Chọn ngày & dịch vụ</p>
          </button>
          <button onClick={() => onNavigate("quote")}
            className="bg-amber-500 text-white rounded-2xl p-4 text-left hover:bg-amber-600 transition-all relative">
            <span className="absolute -top-1 -right-1 bg-red-500 text-white text-[9px] rounded-full px-1.5 py-0.5 font-bold">1 mới</span>
            <div className="text-2xl mb-2">💰</div>
            <p className="font-semibold text-sm">Báo giá</p>
            <p className="text-white/80 text-xs mt-0.5">Chờ xác nhận</p>
          </button>
        </div>

        {/* Next appointment */}
        <div className="bg-white rounded-2xl p-4 border border-[#dde3ec]">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Lịch hẹn sắp tới</p>
          <div className="flex items-center gap-3">
            <div className="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center flex-shrink-0">
              <div className="text-center">
                <p className="text-xs font-bold text-blue-600">T3</p>
                <p className="text-xl font-black text-[#1e3a6e] leading-none">17</p>
              </div>
            </div>
            <div>
              <p className="font-semibold text-slate-800 text-sm">Bảo dưỡng định kỳ</p>
              <p className="text-xs text-slate-500 mt-0.5">08:00 · Gara Ô Tô Thành Công</p>
            </div>
            <span className="ml-auto"><Badge variant="confirmed" /></span>
          </div>
        </div>

        {/* Recent notifications */}
        <div className="bg-white rounded-2xl p-4 border border-[#dde3ec]">
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3">Thông báo gần đây</p>
          <div className="space-y-3">
            {[
              { icon: "🔧", text: "Xe đang được sửa chữa – Bảo dưỡng động cơ đã hoàn tất", time: "10:30", unread: true },
              { icon: "💰", text: "Báo giá BG002 đang chờ xác nhận từ bạn", time: "09:15", unread: true },
            ].map((n, i) => (
              <div key={i} className={`flex items-start gap-3 p-3 rounded-xl ${n.unread ? "bg-blue-50" : "bg-slate-50"}`}>
                <span className="text-lg">{n.icon}</span>
                <div className="flex-1">
                  <p className="text-xs text-slate-700 leading-relaxed">{n.text}</p>
                  <p className="text-[10px] text-slate-400 mt-1">{n.time}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

function MobileBook({ onNavigate }: { onNavigate: (s: MobileScreen) => void }) {
  const [step, setStep] = useState<BookStep>(0);
  const [selectedVehicle, setSelectedVehicle] = useState("");
  const [selectedService, setSelectedService] = useState("");
  const [selectedDate, setSelectedDate] = useState("");
  const [selectedTime, setSelectedTime] = useState("");
  const [showConflict, setShowConflict] = useState(false);
  const [confirmed, setConfirmed] = useState(false);

  const STEP_LABELS = ["Chọn xe", "Dịch vụ", "Ngày", "Giờ", "Xác nhận"];

  if (confirmed) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center px-6 text-center">
        <div className="w-20 h-20 bg-emerald-100 rounded-full flex items-center justify-center text-4xl mb-4">✅</div>
        <h2 className="text-xl font-bold text-slate-800 mb-2">Đặt lịch thành công!</h2>
        <p className="text-slate-500 text-sm mb-6">Lịch hẹn của bạn đã được gara xác nhận.<br />Vui lòng đến đúng giờ.</p>
        <div className="bg-white rounded-2xl p-4 w-full border border-[#dde3ec] mb-6">
          <div className="space-y-2 text-sm">
            <div className="flex justify-between"><span className="text-slate-500">Xe:</span><span className="font-semibold">51G-123.45</span></div>
            <div className="flex justify-between"><span className="text-slate-500">Dịch vụ:</span><span className="font-semibold">Bảo dưỡng định kỳ</span></div>
            <div className="flex justify-between"><span className="text-slate-500">Ngày:</span><span className="font-semibold">18/09/2024</span></div>
            <div className="flex justify-between"><span className="text-slate-500">Giờ:</span><span className="font-bold text-[#1e3a6e]">10:30</span></div>
          </div>
        </div>
        <button onClick={() => { setConfirmed(false); setStep(0); onNavigate("home"); }}
          className="w-full h-12 bg-[#1e3a6e] text-white rounded-2xl font-semibold text-sm">
          Về trang chủ
        </button>
      </div>
    );
  }

  if (showConflict) {
    return (
      <div className="flex-1 flex flex-col px-4 pt-6">
        <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4 mb-4">
          <div className="flex items-center gap-2 mb-2">
            <span className="text-amber-500">⚠️</span>
            <p className="font-semibold text-amber-800 text-sm">Giờ đã chọn không còn trống</p>
          </div>
          <p className="text-xs text-amber-700">18/09/2024 lúc 08:00 đã được đặt. Gara đề xuất các giờ khác:</p>
        </div>
        <p className="font-semibold text-slate-800 mb-3 text-sm">Chọn thời gian thay thế:</p>
        <div className="space-y-3 flex-1">
          {["09:30", "10:30", "14:00", "15:30"].map(t => (
            <button key={t} onClick={() => { setSelectedTime(t); setShowConflict(false); setStep(4); }}
              className="w-full flex items-center justify-between bg-white border border-[#dde3ec] rounded-2xl p-4 hover:border-[#1e3a6e] transition-all">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-[#e8eef7] rounded-xl flex items-center justify-center font-mono font-bold text-[#1e3a6e] text-sm">{t}</div>
                <div className="text-left">
                  <p className="font-semibold text-slate-800 text-sm">18/09/2024 lúc {t}</p>
                  <p className="text-xs text-emerald-600">Còn trống</p>
                </div>
              </div>
              <span className="text-slate-400">›</span>
            </button>
          ))}
        </div>
        <button onClick={() => setShowConflict(false)} className="h-12 w-full border border-[#dde3ec] rounded-2xl text-slate-600 font-medium mt-4 text-sm">Chọn ngày khác</button>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col">
      {/* Step indicator */}
      <div className="px-4 pt-4 pb-3">
        <div className="flex items-center gap-1">
          {STEP_LABELS.map((_, i) => (
            <div key={i} className={`flex-1 h-1 rounded-full transition-all ${i <= step ? "bg-[#1e3a6e]" : "bg-slate-200"}`} />
          ))}
        </div>
        <p className="text-xs text-slate-500 mt-2">{STEP_LABELS[step]} ({step + 1}/{STEP_LABELS.length})</p>
      </div>

      <div className="flex-1 px-4 overflow-y-auto">
        {step === 0 && (
          <div>
            <h2 className="font-bold text-slate-800 mb-4">Chọn xe của bạn</h2>
            <div className="space-y-3">
              {[{ id: "XE001", plate: "51G-123.45", name: "Toyota Camry 2020" }, { id: "XE002", plate: "51A-456.78", name: "Honda CR-V 2019" }].map(v => (
                <button key={v.id} onClick={() => setSelectedVehicle(v.id)}
                  className={`w-full flex items-center gap-3 p-4 rounded-2xl border-2 transition-all ${selectedVehicle === v.id ? "border-[#1e3a6e] bg-[#e8eef7]" : "border-[#dde3ec] bg-white"}`}>
                  <div className="w-12 h-12 bg-[#e8eef7] rounded-xl flex items-center justify-center text-2xl">🚗</div>
                  <div className="text-left">
                    <p className="font-mono font-bold text-[#1e3a6e]">{v.plate}</p>
                    <p className="text-xs text-slate-500">{v.name}</p>
                  </div>
                  {selectedVehicle === v.id && <span className="ml-auto text-[#1e3a6e] text-xl">✓</span>}
                </button>
              ))}
            </div>
          </div>
        )}
        {step === 1 && (
          <div>
            <h2 className="font-bold text-slate-800 mb-4">Chọn dịch vụ</h2>
            <div className="space-y-3">
              {["Bảo dưỡng định kỳ", "Sửa chữa phanh", "Điều hòa không mát", "Thay lốp xe", "Kiểm tra động cơ", "Sửa chữa khác"].map(s => (
                <button key={s} onClick={() => setSelectedService(s)}
                  className={`w-full flex items-center justify-between p-4 rounded-2xl border-2 transition-all text-sm font-medium ${selectedService === s ? "border-[#1e3a6e] bg-[#e8eef7] text-[#1e3a6e]" : "border-[#dde3ec] bg-white text-slate-700"}`}>
                  {s}
                  {selectedService === s && <span>✓</span>}
                </button>
              ))}
            </div>
          </div>
        )}
        {step === 2 && (
          <div>
            <h2 className="font-bold text-slate-800 mb-4">Chọn ngày</h2>
            <div className="grid grid-cols-3 gap-2">
              {Array.from({ length: 14 }, (_, i) => {
                const d = new Date("2024-09-18");
                d.setDate(d.getDate() + i);
                const label = d.toLocaleDateString("vi-VN", { day: "2-digit", month: "2-digit" });
                const weekday = d.toLocaleDateString("vi-VN", { weekday: "short" });
                const isSelected = selectedDate === label;
                return (
                  <button key={i} onClick={() => setSelectedDate(label)}
                    className={`py-3 rounded-2xl text-center transition-all ${isSelected ? "bg-[#1e3a6e] text-white" : "bg-white border border-[#dde3ec] text-slate-700"}`}>
                    <p className={`text-xs ${isSelected ? "text-white/70" : "text-slate-400"}`}>{weekday}</p>
                    <p className={`font-bold text-sm`}>{label}</p>
                  </button>
                );
              })}
            </div>
          </div>
        )}
        {step === 3 && (
          <div>
            <h2 className="font-bold text-slate-800 mb-4">Chọn giờ</h2>
            <div className="grid grid-cols-3 gap-2">
              {["08:00", "09:00", "10:00", "11:00", "13:00", "14:00", "15:00", "16:00"].map(t => (
                <button key={t} onClick={() => { setSelectedTime(t); if (t === "08:00") setShowConflict(true); }}
                  className={`py-3 rounded-2xl text-sm font-bold transition-all ${selectedTime === t ? "bg-[#1e3a6e] text-white" : t === "08:00" ? "bg-slate-100 text-slate-400 line-through cursor-not-allowed" : "bg-white border border-[#dde3ec] text-slate-700"}`}
                  disabled={t === "08:00" && false}>
                  {t}
                  {t === "08:00" && <span className="block text-[9px] font-normal mt-0.5">Đã đặt</span>}
                </button>
              ))}
            </div>
          </div>
        )}
        {step === 4 && (
          <div>
            <h2 className="font-bold text-slate-800 mb-4">Xác nhận thông tin</h2>
            <div className="bg-white rounded-2xl border border-[#dde3ec] overflow-hidden mb-4">
              <div className="bg-[#1e3a6e] px-4 py-3">
                <p className="text-white/70 text-xs">Xác nhận lịch hẹn</p>
              </div>
              <div className="p-4 space-y-3 text-sm">
                <div className="flex justify-between"><span className="text-slate-500">Xe:</span><span className="font-mono font-bold text-[#1e3a6e]">51G-123.45</span></div>
                <div className="flex justify-between"><span className="text-slate-500">Dịch vụ:</span><span className="font-semibold">{selectedService || "Bảo dưỡng định kỳ"}</span></div>
                <div className="flex justify-between"><span className="text-slate-500">Ngày:</span><span className="font-semibold">{selectedDate || "18/09/2024"}</span></div>
                <div className="flex justify-between"><span className="text-slate-500">Giờ:</span><span className="font-bold text-[#1e3a6e]">{selectedTime || "10:30"}</span></div>
                <div className="flex justify-between"><span className="text-slate-500">Gara:</span><span className="font-semibold">Gara Ô Tô Thành Công</span></div>
              </div>
            </div>
            <div className="mb-3">
              <p className="text-xs font-medium text-slate-600 mb-1">Ghi chú (tùy chọn)</p>
              <textarea className="w-full border border-[#dde3ec] rounded-xl text-sm px-3 py-2 h-16 resize-none" placeholder="Ghi chú thêm..." />
            </div>
          </div>
        )}
      </div>

      {/* Bottom nav */}
      <div className="px-4 pb-4 pt-2 flex gap-3">
        {step > 0 && <button onClick={() => setStep((step - 1) as BookStep)} className="h-12 flex-1 border border-[#dde3ec] rounded-2xl text-slate-600 font-medium text-sm">← Quay lại</button>}
        <button
          onClick={() => step < 4 ? setStep((step + 1) as BookStep) : setConfirmed(true)}
          className="h-12 flex-1 bg-[#1e3a6e] text-white rounded-2xl font-semibold text-sm hover:bg-[#162d56] transition-all">
          {step < 4 ? "Tiếp theo →" : "Xác nhận đặt lịch ✓"}
        </button>
      </div>
    </div>
  );
}

function MobileTrack() {
  return (
    <div className="flex-1 overflow-y-auto px-4 pt-4 space-y-4">
      <div className="bg-white rounded-2xl border border-[#dde3ec] p-4">
        <div className="flex items-center gap-3 mb-3">
          <div className="w-12 h-12 bg-[#e8eef7] rounded-xl flex items-center justify-center text-2xl">🚗</div>
          <div>
            <p className="font-mono font-bold text-[#1e3a6e]">51G-123.45</p>
            <p className="text-xs text-slate-500">Toyota Camry 2020</p>
          </div>
          <span className="ml-auto"><Badge variant="in_progress" /></span>
        </div>
        <div className="space-y-1 text-xs text-slate-500">
          <p>Kỹ thuật viên: <strong>Trần Văn Khoa</strong></p>
          <p>Bắt đầu: <strong>15/09/2024 lúc 14:00</strong></p>
        </div>
      </div>

      <div>
        <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-3 px-1">Tiến độ xử lý</p>
        <div className="bg-white rounded-2xl border border-[#dde3ec] p-4">
          <div className="space-y-0 relative">
            <div className="absolute left-[17px] top-9 bottom-0 w-0.5 bg-slate-200 z-0" />
            <TimelineItem label="Đã tiếp nhận xe" time="15/09 08:05" note="Nhân viên: Phạm Minh Tuấn" done active={false} />
            <TimelineItem label="Đã kiểm tra xe" time="15/09 10:00" note="KTV: Trần Văn Khoa kiểm tra" done active={false} />
            <TimelineItem label="Báo giá đã xác nhận" time="15/09 11:30" note="Tổng: 645.000 VNĐ" done active={false} />
            <TimelineItem label="Đang sửa chữa" time="15/09 14:00" done={false} active note="Đang thay dầu và kiểm tra phanh" />
            <TimelineItem label="Hoàn tất sửa chữa" done={false} />
            <TimelineItem label="Chờ thanh toán" done={false} />
            <TimelineItem label="Đã bàn giao xe" done={false} />
          </div>
        </div>
      </div>

      <div className="bg-amber-50 border border-amber-200 rounded-2xl p-4">
        <p className="font-semibold text-amber-800 text-sm mb-1">📞 Cần hỗ trợ?</p>
        <p className="text-xs text-amber-700">Liên hệ gara: <strong>028 3456 7890</strong></p>
      </div>
    </div>
  );
}

function MobileQuote({ onNavigate }: { onNavigate: (s: MobileScreen) => void }) {
  const [confirmed, setConfirmed] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const q = mockQuotations[1];
  const total = calcTotal(q.services, q.parts);

  if (confirmed) {
    return (
      <div className="flex-1 flex flex-col items-center justify-center px-6 text-center">
        <div className="text-5xl mb-4">✅</div>
        <h2 className="text-xl font-bold text-slate-800 mb-2">Đã xác nhận!</h2>
        <p className="text-slate-500 text-sm mb-4">Gara sẽ bắt đầu sửa chữa ngay sau khi nhận được xác nhận của bạn.</p>
        <button onClick={() => { setConfirmed(false); onNavigate("home"); }}
          className="w-full h-12 bg-[#1e3a6e] text-white rounded-2xl font-semibold text-sm">
          Về trang chủ
        </button>
      </div>
    );
  }

  return (
    <div className="flex-1 overflow-y-auto">
      <div className="px-4 pt-4 space-y-4">
        <div>
          <div className="flex items-center justify-between mb-1">
            <h2 className="font-bold text-slate-800">Báo giá {q.id}</h2>
            <Badge variant="pending" />
          </div>
          <p className="text-xs text-slate-500">{q.vehicle} · {q.created.split("-").reverse().join("/")}</p>
        </div>

        <div className="bg-white rounded-2xl border border-[#dde3ec] overflow-hidden">
          <div className="bg-slate-50 px-4 py-2 border-b border-[#dde3ec]">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Dịch vụ</p>
          </div>
          {q.services.map((s, i) => (
            <div key={i} className="flex items-center justify-between px-4 py-3 border-b border-[#dde3ec] last:border-0">
              <div>
                <p className="text-sm font-medium text-slate-800">{s.name}</p>
                <p className="text-xs text-slate-400">SL: {s.qty}</p>
              </div>
              <span className="font-semibold text-sm">{formatCurrency(s.price)}</span>
            </div>
          ))}
        </div>

        <div className="bg-white rounded-2xl border border-[#dde3ec] overflow-hidden">
          <div className="bg-slate-50 px-4 py-2 border-b border-[#dde3ec]">
            <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Phụ tùng</p>
          </div>
          {q.parts.map((p, i) => (
            <div key={i} className="flex items-center justify-between px-4 py-3 border-b border-[#dde3ec] last:border-0">
              <div>
                <p className="text-sm font-medium text-slate-800">{p.name}</p>
                <p className="text-xs text-slate-400">SL: {p.qty}</p>
              </div>
              <span className="font-semibold text-sm">{formatCurrency(p.qty * p.price)}</span>
            </div>
          ))}
        </div>

        <div className="bg-[#1e3a6e] text-white rounded-2xl p-4 flex justify-between items-center">
          <span className="font-medium">Tổng cộng</span>
          <span className="text-xl font-bold">{formatCurrency(total)}</span>
        </div>

        <div className="grid grid-cols-2 gap-3 pb-4">
          <button className="h-12 bg-red-50 text-red-600 font-semibold rounded-2xl text-sm border border-red-200 hover:bg-red-100 transition-all">
            Không đồng ý
          </button>
          <button onClick={() => setShowModal(true)}
            className="h-12 bg-[#1e3a6e] text-white font-semibold rounded-2xl text-sm hover:bg-[#162d56] transition-all">
            Xác nhận
          </button>
        </div>
      </div>

      {/* Confirm modal */}
      {showModal && (
        <div className="fixed inset-0 z-50 flex items-end">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowModal(false)} />
          <div className="relative bg-white rounded-t-3xl w-full p-6">
            <div className="w-10 h-1 bg-slate-300 rounded-full mx-auto mb-4" />
            <h3 className="font-bold text-slate-800 text-lg mb-2 text-center">Xác nhận sửa chữa</h3>
            <p className="text-sm text-slate-500 text-center mb-4">Bạn đồng ý với báo giá <strong>{formatCurrency(total)}</strong> và cho phép gara tiến hành sửa chữa?</p>
            <div className="grid grid-cols-2 gap-3">
              <button onClick={() => setShowModal(false)} className="h-12 border border-[#dde3ec] rounded-2xl text-slate-600 font-medium text-sm">Hủy</button>
              <button onClick={() => { setShowModal(false); setConfirmed(true); }} className="h-12 bg-[#1e3a6e] text-white rounded-2xl font-semibold text-sm">Xác nhận ✓</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function MobileHistory() {
  const [detail, setDetail] = useState(false);
  return (
    <div className="flex-1 overflow-y-auto px-4 pt-4 space-y-3">
      {detail ? (
        <>
          <button onClick={() => setDetail(false)} className="flex items-center gap-2 text-[#1e3a6e] font-medium text-sm mb-2">← Quay lại</button>
          <div className="bg-white rounded-2xl border border-[#dde3ec] p-4 space-y-3">
            <div className="flex justify-between items-start">
              <div><p className="font-mono font-bold text-[#1e3a6e]">51D-567.89</p><p className="text-xs text-slate-500">Ford EcoSport 2018</p></div>
              <Badge variant="completed" />
            </div>
            <div className="grid grid-cols-2 gap-3 text-sm">
              <div><p className="text-xs text-slate-400">Ngày sửa</p><p className="font-semibold">14/09/2024</p></div>
              <div><p className="text-xs text-slate-400">Kỹ thuật viên</p><p className="font-semibold">Lê Quang Hưng</p></div>
            </div>
            <div>
              <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide mb-2">Dịch vụ đã làm</p>
              {["Kiểm tra và vệ sinh bugi", "Điều chỉnh bướm ga"].map(s => (
                <div key={s} className="flex items-center gap-2 py-2 border-b border-[#dde3ec] last:border-0">
                  <span className="text-emerald-500 text-xs">✓</span>
                  <span className="text-sm text-slate-700">{s}</span>
                </div>
              ))}
            </div>
            <div className="flex justify-between pt-2">
              <span className="font-semibold text-slate-700">Tổng chi phí</span>
              <span className="font-bold text-[#1e3a6e]">{formatCurrency(550000)}</span>
            </div>
          </div>
        </>
      ) : (
        <>
          <p className="text-xs font-semibold text-slate-500 uppercase tracking-wide">Xe: 51G-123.45 · Toyota Camry</p>
          {[
            { date: "15/09/2024", service: "Đang sửa chữa", status: "in_progress", cost: 645000 },
            { date: "15/08/2024", service: "Bảo dưỡng 40.000 km", status: "completed", cost: 420000 },
            { date: "12/05/2024", service: "Thay lốp xe (2 lốp trước)", status: "completed", cost: 1800000 },
          ].map((h, i) => (
            <button key={i} onClick={() => setDetail(true)}
              className="w-full bg-white rounded-2xl border border-[#dde3ec] p-4 text-left hover:border-[#1e3a6e] transition-all">
              <div className="flex items-start justify-between mb-2">
                <p className="font-semibold text-slate-800 text-sm">{h.service}</p>
                <Badge variant={h.status as any} />
              </div>
              <div className="flex items-center justify-between text-xs text-slate-500">
                <span>{h.date}</span>
                <span className="font-bold text-[#1e3a6e]">{formatCurrency(h.cost)}</span>
              </div>
            </button>
          ))}
        </>
      )}
    </div>
  );
}

export default function MobileApp() {
  const [screen, setScreen] = useState<MobileScreen>("home");

  const PAGE_TITLE: Record<MobileScreen, string> = {
    home: "Trang chủ",
    book: "Đặt lịch hẹn",
    track: "Theo dõi tiến độ",
    quote: "Xác nhận báo giá",
    history: "Lịch sử sửa chữa",
    account: "Tài khoản",
  };

  return (
    <div className="flex items-center justify-center min-h-full py-8 bg-[#f0f4f8]">
      <div className="mobile-device shadow-2xl">
        {/* Status bar */}
        <div className="flex items-center justify-between px-5 pt-3 pb-1 bg-[#1e3a6e] text-white/80 text-[10px]">
          <span className="font-semibold">9:41</span>
          <span className="font-bold">{GARAGE_NAME_SHORT}</span>
          <span>●●● 5G</span>
        </div>

        {/* Page title (except home) */}
        {screen !== "home" && (
          <div className={`flex items-center gap-3 px-4 py-3 ${screen === "book" || screen === "track" || screen === "quote" ? "bg-[#1e3a6e] text-white" : "bg-white border-b border-[#dde3ec]"}`}>
            <button onClick={() => setScreen("home")} className={`p-1.5 rounded-lg ${screen === "book" || screen === "track" || screen === "quote" ? "text-white/70 hover:text-white hover:bg-white/10" : "text-slate-500 hover:bg-slate-100"}`}>←</button>
            <h2 className={`font-bold text-sm ${screen === "book" || screen === "track" || screen === "quote" ? "text-white" : "text-slate-800"}`}>{PAGE_TITLE[screen]}</h2>
          </div>
        )}

        {/* Content — flex-1 fills whatever remains between status+title and bottom nav */}
        <div className="flex-1 overflow-hidden flex flex-col min-h-0">
          {screen === "home" && <MobileHome onNavigate={setScreen} />}
          {screen === "book" && <MobileBook onNavigate={setScreen} />}
          {screen === "track" && <MobileTrack />}
          {screen === "quote" && <MobileQuote onNavigate={setScreen} />}
          {screen === "history" && <MobileHistory />}
          {screen === "account" && (
            <div className="flex-1 overflow-y-auto flex flex-col items-center pt-8 px-4 pb-4">
              <div className="w-20 h-20 bg-gradient-to-br from-blue-400 to-indigo-600 rounded-full flex items-center justify-center text-white text-2xl font-bold mb-3">A</div>
              <p className="font-bold text-slate-800 text-lg">Nguyễn Văn An</p>
              <p className="text-slate-500 text-sm mono">0901234567</p>
              <div className="w-full mt-6 space-y-2">
                {["Thông tin cá nhân", "Xe của tôi", "Đổi mật khẩu", "Liên hệ hỗ trợ", "Đăng xuất"].map(item => (
                  <button key={item} className={`w-full flex items-center justify-between p-4 bg-white rounded-2xl border border-[#dde3ec] text-sm font-medium ${item === "Đăng xuất" ? "text-red-500" : "text-slate-700"}`}>
                    {item} <span>›</span>
                  </button>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Bottom navigation */}
        <div className="flex items-center bg-white border-t border-[#dde3ec] flex-shrink-0 h-[70px]">
          {NAV.map(n => (
            <button key={n.key} onClick={() => setScreen(n.key as MobileScreen)}
              className={`flex-1 flex flex-col items-center justify-center gap-0.5 py-2 transition-all ${screen === n.key || (screen === "track" && n.key === "track") || (screen === "quote" && n.key === "home") ? "text-[#1e3a6e]" : "text-slate-400"}`}>
              <span className="text-lg">{n.icon}</span>
              <span className="text-[9px] font-medium">{n.label}</span>
              {n.key === "home" && screen === "home" && <span className="w-1 h-1 bg-[#1e3a6e] rounded-full" />}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}

const GARAGE_NAME_SHORT = "Gara Thành Công";
