import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/services/auth_service.dart';
import 'package:garage_customer_mobile/services/api_appointment_service.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';
import 'package:garage_customer_mobile/models/appointment.dart';

// Real HTTP/SQL check. Separate from fixture-backed unit tests; run only after Web creates a booking.
void main() {
  final path = Platform.environment['GARAGE_VERIFY_CREDENTIALS'];
  test(
    'Flutter authenticates, reads Web booking, reschedules, cancels and reloads from SQL',
    () async {
      final fixture =
          jsonDecode(await File(path!).readAsString()) as Map<String, dynamic>;
      expect(
        fixture['database'].toString(),
        startsWith('QuanLyGaraOTo_Verify_'),
      );
      final customer = fixture['customer'] as Map<String, dynamic>;
      final auth = ApiAuthService();
      final session = await auth.login(
        username: customer['username'] as String,
        password: customer['password'] as String,
      );
      final service = ApiAppointmentService(
        CustomerApi(() => session.accessToken),
      );
      final id = fixture['bookingId'].toString();
      var item = (await service.getAppointments(session.customerId))
          .singleWhere((item) => item.id == id);
      expect(item.status, AppointmentStatus.confirmed);
      expect(item.vehicle.plate, fixture['plate']);
      item = await service.reschedule(
        item,
        item.date,
        fixture['newTime'] as String,
        'Dời lịch từ ứng dụng khách hàng',
      );
      expect(item.status, AppointmentStatus.pending);
      expect(item.time, fixture['newTime']);
      item = (await service.getAppointments(session.customerId))
          .singleWhere((item) => item.id == id);
      expect(item.version, 2);
      item = await service.cancel(item, 'Khách hàng hủy sau khi đổi kế hoạch');
      expect(item.status, AppointmentStatus.cancelled);
      final reloaded = (await service.getAppointments(session.customerId))
          .singleWhere((item) => item.id == id);
      expect(reloaded.status, AppointmentStatus.cancelled);
      expect(reloaded.version, 3);
      await auth.logout(session);
    },
    skip: path == null
        ? 'Set GARAGE_VERIFY_CREDENTIALS and --dart-define=API_BASE_URL=http://127.0.0.1:8088/api'
        : false,
  );
}
