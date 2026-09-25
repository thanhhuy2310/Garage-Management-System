import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class BookingCalendar extends StatelessWidget {
  const BookingCalendar({
    super.key,
    required this.visibleMonth,
    required this.maxDate,
    required this.selectedDate,
    required this.fullyBookedDates,
    required this.onMonthChanged,
    required this.onDateSelected,
  });

  final DateTime visibleMonth;
  final DateTime maxDate;
  final DateTime? selectedDate;
  final Set<DateTime> fullyBookedDates;
  final ValueChanged<DateTime> onMonthChanged;
  final ValueChanged<DateTime> onDateSelected;

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _sameDay(DateTime? a, DateTime b) =>
      a != null && a.year == b.year && a.month == b.month && a.day == b.day;

  bool _containsDay(Set<DateTime> values, DateTime date) =>
      values.any((item) => _sameDay(item, date));

  @override
  Widget build(BuildContext context) {
    final days = DateUtils.getDaysInMonth(
      visibleMonth.year,
      visibleMonth.month,
    );
    final first = DateTime(visibleMonth.year, visibleMonth.month);
    final leading = (first.weekday - DateTime.monday) % 7;
    final canGoBack = DateTime(
      visibleMonth.year,
      visibleMonth.month,
    ).isAfter(DateTime(_today.year, _today.month));
    final canGoForward = DateTime(
      visibleMonth.year,
      visibleMonth.month,
    ).isBefore(DateTime(maxDate.year, maxDate.month));
    const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

    return Align(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Tháng trước',
                      onPressed: canGoBack
                          ? () => onMonthChanged(
                              DateTime(
                                visibleMonth.year,
                                visibleMonth.month - 1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Text(
                        'Tháng ${visibleMonth.month.toString().padLeft(2, '0')} / ${visibleMonth.year}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tháng sau',
                      onPressed: canGoForward
                          ? () => onMonthChanged(
                              DateTime(
                                visibleMonth.year,
                                visibleMonth.month + 1,
                              ),
                            )
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 7,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: weekdays
                      .map(
                        (day) => Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                GridView.builder(
                  key: ValueKey('${visibleMonth.year}-${visibleMonth.month}'),
                  itemCount: leading + days,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                  ),
                  itemBuilder: (context, index) {
                    if (index < leading) return const SizedBox.shrink();
                    final date = DateTime(
                      visibleMonth.year,
                      visibleMonth.month,
                      index - leading + 1,
                    );
                    final past = date.isBefore(_today);
                    final beyondLimit = date.isAfter(maxDate);
                    final closed = date.weekday == DateTime.sunday;
                    final fullyBooked =
                        _containsDay(fullyBookedDates, date) || closed;
                    final disabled = past || fullyBooked || beyondLimit;
                    final selected = _sameDay(selectedDate, date);
                    final today = _sameDay(_today, date);
                    final background = selected
                        ? AppColors.primary
                        : fullyBooked && !past
                        ? AppColors.dangerSoft
                        : Colors.transparent;
                    final foreground = selected
                        ? Colors.white
                        : disabled
                        ? fullyBooked && !past
                              ? AppColors.danger
                              : const Color(0xFF9AA5B1)
                        : AppColors.foreground;
                    return Semantics(
                      button: true,
                      enabled: !disabled,
                      selected: selected,
                      label:
                          '${date.day}/${date.month}/${date.year}${fullyBooked ? ', đã kín lịch' : ''}',
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: InkWell(
                          onTap: disabled ? null : () => onDateSelected(date),
                          borderRadius: BorderRadius.circular(9),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            decoration: BoxDecoration(
                              color: background,
                              borderRadius: BorderRadius.circular(9),
                              border: today && !selected
                                  ? Border.all(color: AppColors.accent)
                                  : null,
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Text(
                                  '${date.day}',
                                  style: TextStyle(
                                    color: foreground,
                                    fontWeight: selected || today
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                                if (today && !selected)
                                  const Positioned(
                                    bottom: 5,
                                    child: SizedBox(
                                      width: 4,
                                      height: 4,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.square_rounded,
                      size: 12,
                      color: AppColors.dangerSoft,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Đỏ: đã kín lịch hoặc ngày nghỉ',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
