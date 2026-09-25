import {
  AFTERNOON_SLOTS,
  MORNING_SLOTS,
  formatBookingDate,
  getBookingAvailability,
} from "../../mock/bookingAvailability";
import { Icons } from "../ui";

interface TimeSlotPickerProps {
  selectedDate: string;
  selectedTime: string;
  unavailableSlots: ReadonlySet<string>;
  onSelectTime: (time: string) => void;
}

interface SlotGroupProps {
  label: string;
  slots: readonly string[];
  available: ReadonlySet<string>;
  selectedDate: string;
  selectedTime: string;
  unavailableSlots: ReadonlySet<string>;
  onSelectTime: (time: string) => void;
}

function SlotGroup({ label, slots, available, selectedDate, selectedTime, unavailableSlots, onSelectTime }: SlotGroupProps) {
  return (
    <fieldset>
      <legend className="text-xs font-bold uppercase tracking-[0.12em] text-muted-foreground">{label}</legend>
      <div className="mt-3 grid grid-cols-2 gap-2 sm:grid-cols-3 xl:grid-cols-4">
        {slots.map((time) => {
          const isSelected = selectedTime === time;
          const isUnavailable = !available.has(time) || unavailableSlots.has(`${selectedDate}|${time}`);

          return (
            <button
              key={time}
              type="button"
              disabled={isUnavailable}
              aria-pressed={isSelected}
              aria-label={`${time}, ${isUnavailable ? "đã được đặt" : isSelected ? "đã chọn" : "còn trống"}`}
              onClick={() => onSelectTime(time)}
              className={`motion-button flex min-h-12 flex-col items-center justify-center rounded-md border px-2 py-2 font-mono text-sm font-bold ${
                isSelected
                  ? "border-primary bg-primary text-primary-foreground shadow-sm"
                  : isUnavailable
                    ? "cursor-not-allowed border-danger/20 bg-danger-soft text-danger opacity-75"
                    : "border-border bg-white text-foreground hover:border-primary hover:bg-primary-soft hover:text-primary"
              }`}
            >
              <span>{time}</span>
              <span className={`mt-0.5 font-sans text-[9px] font-semibold uppercase tracking-wide ${isSelected ? "text-white/75" : isUnavailable ? "text-danger" : "text-success"}`}>
                {isUnavailable ? "Đã đặt" : isSelected ? "Đã chọn" : "Còn trống"}
              </span>
            </button>
          );
        })}
      </div>
    </fieldset>
  );
}

export default function TimeSlotPicker({ selectedDate, selectedTime, unavailableSlots, onSelectTime }: TimeSlotPickerProps) {
  if (!selectedDate) {
    return (
      <section aria-labelledby="booking-slots-title" className="flex min-h-[320px] items-center justify-center border-t border-border bg-surface-subtle p-6 text-center lg:min-h-[360px] lg:border-t-0">
        <div className="max-w-xs">
          <span className="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-primary-soft text-primary" aria-hidden="true">{Icons.calendar}</span>
          <h3 id="booking-slots-title" className="mt-4 font-bold text-foreground">Chọn ngày trên lịch</h3>
          <p className="mt-2 text-sm leading-6 text-muted-foreground">Các khung giờ còn trống sẽ hiển thị tại đây.</p>
        </div>
      </section>
    );
  }

  const available = new Set(getBookingAvailability(selectedDate));

  return (
    <section key={selectedDate} aria-labelledby="booking-slots-title" className="booking-slots-enter border-t border-border bg-surface-subtle p-4 sm:p-5 lg:border-t-0">
      <div className="border-b border-border pb-4">
        <h3 id="booking-slots-title" className="text-base font-bold text-foreground">{formatBookingDate(selectedDate)}</h3>
        <p className="mt-1 text-xs font-bold uppercase tracking-[0.12em] text-accent">Khung giờ còn trống</p>
        <p className="mt-1 text-xs leading-5 text-muted-foreground">Khung giờ màu đỏ đã có lịch hẹn và không thể chọn.</p>
      </div>

      <div className="mt-5 space-y-6" aria-live="polite">
        <SlotGroup
          label="Buổi sáng"
          slots={MORNING_SLOTS}
          available={available}
          selectedDate={selectedDate}
          selectedTime={selectedTime}
          unavailableSlots={unavailableSlots}
          onSelectTime={onSelectTime}
        />
        <SlotGroup
          label="Buổi chiều"
          slots={AFTERNOON_SLOTS}
          available={available}
          selectedDate={selectedDate}
          selectedTime={selectedTime}
          unavailableSlots={unavailableSlots}
          onSelectTime={onSelectTime}
        />
      </div>
    </section>
  );
}
