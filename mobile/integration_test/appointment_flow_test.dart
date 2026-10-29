import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:garage_customer_mobile/app/app.dart';
import 'package:garage_customer_mobile/core/widgets/primary_button.dart';
import 'package:garage_customer_mobile/services/auth_service.dart';
import 'package:garage_customer_mobile/services/api_appointment_service.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';
import 'package:garage_customer_mobile/models/appointment.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const username = String.fromEnvironment('VERIFY_USERNAME');
  const password = String.fromEnvironment('VERIFY_PASSWORD');
  const bookingId = String.fromEnvironment('VERIFY_BOOKING_ID');
  const newTime = String.fromEnvironment('VERIFY_NEW_TIME');
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(finder, findsWidgets);
  }

  testWidgets(
    'Android UI reads the Web booking and persists reschedule and cancel',
    (tester) async {
      expect(username, isNotEmpty);
      expect(bookingId, isNotEmpty);
      await tester.pumpWidget(const GarageCustomerApp());
      await waitFor(tester, find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField).at(0), username);
      await tester.enterText(find.byType(TextFormField).at(1), password);
      await tester.tap(find.widgetWithText(PrimaryButton, 'Đăng nhập'));
      await waitFor(tester, find.byType(NavigationBar));
      await tester.tap(
        find
            .descendant(
              of: find.byType(NavigationBar),
              matching: find.text('Lịch hẹn'),
            )
            .first,
      );
      await waitFor(tester, find.text('Mã lịch: $bookingId'));
      expect(find.text('Đã xác nhận'), findsWidgets);
      await tester.tap(find.text('Dời lịch').first);
      await waitFor(tester, find.byType(DatePickerDialog));
      await tester.tap(find.text('OK'));
      await waitFor(tester, find.text(newTime));
      await tester.tap(find.text(newTime));
      await waitFor(tester, find.text('Dời lịch hẹn?'));
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await waitFor(tester, find.text('Chờ xác nhận'));
      expect(find.textContaining(newTime), findsWidgets);
      await tester.tap(find.text('Hủy lịch').first);
      await waitFor(tester, find.text('Hủy lịch hẹn?'));
      await tester.tap(find.widgetWithText(FilledButton, 'Xác nhận'));
      await waitFor(tester, find.text('Chưa có lịch hẹn'));
      await tester.tap(find.text('Đã hủy').first);
      await waitFor(tester, find.text('Mã lịch: $bookingId'));
      final session = await ApiAuthService().login(
        username: username,
        password: password,
      );
      final service = ApiAppointmentService(
        CustomerApi(() => session.accessToken),
      );
      final record = (await service.getAppointments(session.customerId))
          .singleWhere((a) => a.id == bookingId);
      expect(record.status, AppointmentStatus.cancelled);
      expect(record.time, newTime);
      expect(record.version, 3);
    },
  );
  testWidgets('Android UI creates a booking and reads it back from the API', (
    tester,
  ) async {
    const plate = String.fromEnvironment('VERIFY_PLATE');
    final date = DateTime.parse(const String.fromEnvironment('VERIFY_DATE'));
    await tester.pumpWidget(const GarageCustomerApp());
    await waitFor(tester, find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField).at(0), username);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Đăng nhập'));
    await waitFor(tester, find.byType(NavigationBar));
    await tester.tap(
      find
          .descendant(
            of: find.byType(NavigationBar),
            matching: find.text('Lịch hẹn'),
          )
          .first,
    );
    await waitFor(tester, find.text('Đặt lịch mới'));
    await tester.tap(find.text('Đặt lịch mới'));
    await waitFor(tester, find.text(plate));
    await tester.tap(find.text(plate));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Kiểm tra hệ thống phanh'),
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Kiểm tra hệ thống phanh'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Tiếp tục'));
    await tester.pumpAndSettle();
    final monthLabel =
        'Tháng ${date.month.toString().padLeft(2, '0')} / ${date.year}';
    for (var i = 0; i < 3 && find.text(monthLabel).evaluate().isEmpty; i++) {
      await tester.tap(find.byTooltip('Tháng sau'));
      await tester.pumpAndSettle();
    }
    await waitFor(tester, find.text(monthLabel));
    final day = find.text('${date.day}');
    await waitFor(tester, day);
    await tester.ensureVisible(day);
    await tester.tap(day);
    await waitFor(tester, find.text('09:30'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('09:30'));
    await tester.pumpAndSettle();
    if (find.text('09:30').hitTestable().evaluate().isEmpty) {
      await tester.drag(find.byType(ListView).last, const Offset(0, -250));
      await tester.pumpAndSettle();
    }
    expect(find.text('09:30').hitTestable(), findsOneWidget);
    await tester.tap(find.text('09:30'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Tiếp tục'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(PrimaryButton, 'Xác nhận đặt lịch'));
    await waitFor(tester, find.text('Gara đã ghi nhận lịch hẹn'));
    final session = await ApiAuthService().login(
      username: username,
      password: password,
    );
    final service = ApiAppointmentService(
      CustomerApi(() => session.accessToken),
    );
    final record = (await service.getAppointments(session.customerId))
        .singleWhere(
          (a) =>
              a.status == AppointmentStatus.pending &&
              a.vehicle.plate == plate &&
              a.date == date &&
              a.time == '09:30',
        );
    expect(record.id, isNot(bookingId));
    expect(record.version, 0);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Xem lịch hẹn'));
    await waitFor(tester, find.text('Mã lịch: ${record.id}'));
  });
}
