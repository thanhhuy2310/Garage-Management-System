import { useMemo, useState } from "react";
import {
  BOOKING_MAX_DATE,
  BOOKING_TODAY,
  FULLY_BOOKED_DATES,
  getBookingAvailability,
  isClosedBookingDate,
  parseBookingDate,
  toBookingDateKey,
} from "../../mock/bookingAvailability";
import { Icons } from "../ui";

const WEEKDAYS = [
  { short: "T2", full: "Thứ 2" },
  { short: "T3", full: "Thứ 3" },
  { short: "T4", full: "Thứ 4" },
  { short: "T5", full: "Thứ 5" },
  { short: "T6", full: "Thứ 6" },
  { short: "T7", full: "Thứ 7" },
  { short: "CN", full: "CN" },
];

interface BookingCalendarProps {
  selectedDate: string;
  onSelectDate: (dateKey: string) => void;
}

function monthKey(date: Date) {
  return date.getFullYear() * 12 + date.getMonth();
}

export default function BookingCalendar({ selectedDate, onSelectDate }: BookingCalendarProps) {
  const initialDate = selectedDate ? parseBookingDate(selectedDate) : parseBookingDate(BOOKING_TODAY);
  const [visibleMonth, setVisibleMonth] = useState(() => new Date(initialDate.getFullYear(), initialDate.getMonth(), 1));

  const minMonth = monthKey(parseBookingDate(BOOKING_TODAY));
  const maxMonth = monthKey(parseBookingDate(BOOKING_MAX_DATE));
  const currentMonth = monthKey(visibleMonth);

  const days = useMemo(() => {
    const year = visibleMonth.getFullYear();
    const month = visibleMonth.getMonth();
    const firstDay = new Date(year, month, 1);
    const mondayOffset = (firstDay.getDay() + 6) % 7;
    const gridStart = new Date(year, month, 1 - mondayOffset);

    return Array.from({ length: 42 }, (_, index) => {
      const date = new Date(gridStart);
      date.setDate(gridStart.getDate() + index);
      return date;
    });
  }, [visibleMonth]);

  const moveMonth = (offset: number) => {
    setVisibleMonth((current) => new Date(current.getFullYear(), current.getMonth() + offset, 1));
  };

  const monthLabel = `Tháng ${String(visibleMonth.getMonth() + 1).padStart(2, "0")} / ${visibleMonth.getFullYear()}`;

  return (
    <section aria-labelledby="booking-calendar-title" className="rounded-lg border border-border bg-white p-2 sm:p-5">
      <div className="flex items-center justify-between gap-3 border-b border-border pb-4">
        <div>
          <p className="text-xs font-bold uppercase tracking-[0.12em] text-accent">Chọn ngày</p>
          <h3 id="booking-calendar-title" className="mt-1 text-lg font-bold text-foreground" aria-live="polite">{monthLabel}</h3>
        </div>
        <div className="flex items-center gap-2">
          <button
            type="button"
            onClick={() => moveMonth(-1)}
            disabled={currentMonth <= minMonth}
            aria-label="Xem tháng trước"
            className="motion-button flex h-11 w-11 items-center justify-center rounded-md border border-border text-primary hover:border-primary hover:bg-primary-soft disabled:cursor-not-allowed disabled:text-muted-foreground"
          >
            {Icons.chevronLeft}
          </button>
          <button
            type="button"
            onClick={() => moveMonth(1)}
            disabled={currentMonth >= maxMonth}
            aria-label="Xem tháng sau"
            className="motion-button flex h-11 w-11 items-center justify-center rounded-md border border-border text-primary hover:border-primary hover:bg-primary-soft disabled:cursor-not-allowed disabled:text-muted-foreground"
          >
            {Icons.chevronRight}
          </button>
        </div>
      </div>

      <div className="mt-4 grid grid-cols-7" role="row" aria-label="Các ngày trong tuần">
        {WEEKDAYS.map((weekday) => (
          <div key={weekday.short} role="columnheader" className="py-2 text-center text-[11px] font-bold uppercase tracking-wide text-muted-foreground sm:text-xs">
            <span className="sm:hidden">{weekday.short}</span>
            <span className="hidden sm:inline">{weekday.full}</span>
          </div>
        ))}
      </div>

      <div key={`${visibleMonth.getFullYear()}-${visibleMonth.getMonth()}`} className="booking-month-enter grid grid-cols-7 gap-0.5 sm:gap-1.5" role="grid" aria-label={monthLabel}>
        {days.map((date) => {
          const dateKey = toBookingDateKey(date);
          const inCurrentMonth = date.getMonth() === visibleMonth.getMonth();
          const isPast = dateKey < BOOKING_TODAY;
          const isBeyondRange = dateKey > BOOKING_MAX_DATE;
          const isToday = dateKey === BOOKING_TODAY;
          const isSelected = dateKey === selectedDate;
          const isFull = inCurrentMonth && FULLY_BOOKED_DATES.has(dateKey);
          const isClosed = inCurrentMonth && isClosedBookingDate(dateKey);
          const hasSlots = getBookingAvailability(dateKey).length > 0;
          const isDisabled = !inCurrentMonth || isPast || isBeyondRange || isFull || isClosed || !hasSlots;

          const stateLabel = isFull ? "đã hết chỗ" : isClosed ? "gara nghỉ" : isPast ? "đã qua" : isSelected ? "đã chọn" : isToday ? "hôm nay" : "còn lịch";
          const accessibleDate = new Intl.DateTimeFormat("vi-VN", { weekday: "long", day: "2-digit", month: "2-digit", year: "numeric" }).format(date);

          let stateClass = "border-transparent bg-white text-foreground hover:border-primary hover:bg-primary-soft";
          if (!inCurrentMonth) stateClass = "border-transparent bg-transparent text-slate-300";
          else if (isPast || isBeyondRange) stateClass = "border-transparent bg-surface-subtle text-slate-300";
          else if (isClosed) stateClass = "border-transparent bg-surface-subtle text-muted-foreground";
          else if (isFull) stateClass = "border-danger/25 bg-danger-soft text-danger";
          else if (isSelected) stateClass = "border-primary bg-primary text-primary-foreground shadow-sm";
          else if (isToday) stateClass = "border-primary/60 bg-white text-primary";

          return (
            <div key={dateKey} role="gridcell" className="min-w-0">
              <button
                type="button"
                disabled={isDisabled}
                aria-label={`${accessibleDate}, ${stateLabel}`}
                aria-pressed={isSelected}
                onClick={() => onSelectDate(dateKey)}
                className={`relative flex min-h-12 w-full flex-col items-center justify-center rounded-md border text-sm font-bold transition-colors duration-150 ${stateClass} disabled:cursor-not-allowed`}
              >
                <span>{date.getDate()}</span>
                {isFull && <span className="mt-0.5 text-[8px] font-bold uppercase leading-none sm:text-[9px]">Hết</span>}
                {isClosed && <span className="mt-0.5 text-[8px] font-medium uppercase leading-none sm:text-[9px]">Nghỉ</span>}
                {isToday && !isSelected && <span className="absolute bottom-1 h-1 w-1 rounded-full bg-accent" aria-hidden="true" />}
              </button>
            </div>
          );
        })}
      </div>

      <div className="mt-4 flex flex-wrap gap-x-4 gap-y-2 border-t border-border pt-4 text-xs text-muted-foreground" aria-label="Chú thích trạng thái ngày">
        <span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-sm bg-primary" aria-hidden="true" />Đã chọn</span>
        <span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-full border border-primary bg-white" aria-hidden="true" />Hôm nay</span>
        <span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-sm border border-danger/30 bg-danger-soft" aria-hidden="true" />Hết chỗ</span>
        <span className="inline-flex items-center gap-1.5"><span className="h-2.5 w-2.5 rounded-sm bg-surface-subtle" aria-hidden="true" />Không khả dụng</span>
      </div>
    </section>
  );
}
