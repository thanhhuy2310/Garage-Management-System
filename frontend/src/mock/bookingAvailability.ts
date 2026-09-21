export const BOOKING_TODAY = "2026-09-21";
export const BOOKING_MAX_DATE = "2026-12-20";

export const MORNING_SLOTS = ["08:00", "08:30", "09:00", "09:30", "10:00", "10:30", "11:00"] as const;
export const AFTERNOON_SLOTS = ["13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30"] as const;
export const ALL_BOOKING_SLOTS = [...MORNING_SLOTS, ...AFTERNOON_SLOTS] as const;

const EXPLICIT_AVAILABILITY: Record<string, readonly string[]> = {
  "2026-09-21": ["08:00", "08:30", "09:30", "10:00", "10:30", "14:00", "15:00"],
  "2026-09-22": ["09:00", "10:00", "13:30", "16:00"],
  "2026-09-24": ["08:30", "09:00", "10:30", "14:30", "15:30", "16:30"],
  "2026-09-25": ["08:00", "09:30", "11:00", "13:30", "15:00", "16:00"],
};

export const FULLY_BOOKED_DATES = new Set([
  "2026-09-23",
  "2026-09-26",
  "2026-09-30",
  "2026-10-03",
  "2026-10-14",
  "2026-11-07",
]);

export const SIMULATED_CONFLICT = { date: "2026-09-21", time: "09:30" } as const;

export function parseBookingDate(dateKey: string) {
  const [year, month, day] = dateKey.split("-").map(Number);
  return new Date(year, month - 1, day);
}

export function toBookingDateKey(date: Date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`;
}

export function formatBookingDate(dateKey: string) {
  if (!dateKey) return "Chưa chọn ngày";
  const text = new Intl.DateTimeFormat("vi-VN", {
    weekday: "long",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  }).format(parseBookingDate(dateKey));
  return text.charAt(0).toUpperCase() + text.slice(1);
}

export function isClosedBookingDate(dateKey: string) {
  return parseBookingDate(dateKey).getDay() === 0;
}

export function getBookingAvailability(dateKey: string): readonly string[] {
  if (!dateKey || dateKey < BOOKING_TODAY || dateKey > BOOKING_MAX_DATE) return [];
  if (FULLY_BOOKED_DATES.has(dateKey) || isClosedBookingDate(dateKey)) return [];
  if (EXPLICIT_AVAILABILITY[dateKey]) return EXPLICIT_AVAILABILITY[dateKey];

  const day = parseBookingDate(dateKey).getDate();
  return ALL_BOOKING_SLOTS.filter((_, index) => (index + day) % 3 !== 0);
}

export function getSuggestedBookingSlots(dateKey: string, unavailable: ReadonlySet<string>) {
  return getBookingAvailability(dateKey)
    .filter((time) => !unavailable.has(`${dateKey}|${time}`))
    .slice(0, 3);
}
