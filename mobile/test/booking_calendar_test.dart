import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/screens/booking/booking_calendar.dart';

void main() {
  testWidgets('calendar shows month grid and disables fully booked date', (
    tester,
  ) async {
    final now = DateTime.now();
    final visible = DateTime(now.year, now.month + 1);
    final fullyBooked = DateTime(visible.year, visible.month, 11);
    DateTime? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BookingCalendar(
            visibleMonth: visible,
            maxDate: visible.add(const Duration(days: 60)),
            selectedDate: null,
            fullyBookedDates: {fullyBooked},
            onMonthChanged: (_) {},
            onDateSelected: (date) => selected = date,
          ),
        ),
      ),
    );

    expect(find.text('T2'), findsOneWidget);
    expect(find.text('CN'), findsOneWidget);
    expect(find.text('11'), findsOneWidget);

    await tester.tap(find.text('11'));
    expect(selected, isNull);
  });
}
