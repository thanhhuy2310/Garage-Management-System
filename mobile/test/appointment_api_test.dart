import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/models/appointment.dart';
import 'package:garage_customer_mobile/services/api_appointment_service.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';

void main() {
  test('booking adapter uses authenticated API for create, reload, move and cancel', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requests = <String>[];
    final payloads = <Map<String, dynamic>>[];
    var row = <String, dynamic>{
      'id': 41,
      'customerId': 7,
      'customerName': 'Nguyễn Minh Anh',
      'vehicleId': 12,
      'plate': '51A-67890',
      'brand': 'Toyota',
      'model': 'Vios',
      'year': 2021,
      'mileage': 25000,
      'serviceId': 2,
      'serviceName': 'Kiểm tra phanh',
      'serviceType': 'KIEM_TRA',
      'unitPrice': 150000,
      'date': '2026-11-12',
      'time': '09:30:00',
      'note': 'Kiểm tra phanh',
      'status': 'CHO_XAC_NHAN',
      'version': 0,
    };
    server.listen((request) async {
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer customer-token',
      );
      requests.add('${request.method} ${request.uri.path}');
      Object data;
      if (request.method != 'GET') {
        final body = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        payloads.add(body);
        if (request.uri.path.endsWith('/reschedule')) {
          row = {
            ...row,
            'date': body['date'],
            'time': body['time'],
            'version': 1,
          };
        }
        if (request.uri.path.endsWith('/cancel')) {
          row = {...row, 'status': 'HUY', 'version': 2};
        }
        data = row;
      } else if (request.uri.path.endsWith('/availability')) {
        data = {
          'configured': true,
          'slots': [
            {'time': '09:30:00', 'remaining': 1, 'capacity': 1},
            {'time': '10:00:00', 'remaining': 0, 'capacity': 1},
          ],
        };
      } else {
        data = [row];
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'success': true, 'data': data}));
      await request.response.close();
    });
    final service = ApiAppointmentService(
      CustomerApi(
        () => 'customer-token',
        baseUrl: 'http://127.0.0.1:${server.port}/api',
      ),
    );
    final initial = (await service.getAppointments(7)).single;
    expect(initial.status, AppointmentStatus.pending);
    expect(
      (await service.getAvailability(DateTime(2026, 11, 12))).availableSlots,
      ['09:30'],
    );
    final created = await service.createAppointment(
      AppointmentInput(
        customerId: 999,
        vehicle: initial.vehicle,
        service: initial.service,
        date: initial.date,
        time: initial.time,
        note: initial.note,
      ),
    );
    expect(created.id, '41');
    expect(payloads.first.containsKey('customerId'), false);
    expect(payloads.first.containsKey('status'), false);
    final moved = await service.reschedule(
      created,
      DateTime(2026, 11, 13),
      '09:30',
      'Đổi ngày',
    );
    expect(moved.version, 1);
    expect(moved.date.day, 13);
    expect(
      (await service.cancel(moved, 'Không đến được')).status,
      AppointmentStatus.cancelled,
    );
    expect(
      (await service.getAppointments(7)).single.status,
      AppointmentStatus.cancelled,
    );
    expect(requests, contains('POST /api/appointments'));
    expect(requests, contains('PATCH /api/appointments/41/reschedule'));
    expect(payloads.last['version'], 1);
  });
  test(
    'capacity conflict must surface as an error, never fake success',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        await request.drain<void>();
        request.response.statusCode = 409;
        request.response.write(
          jsonEncode({'success': false, 'message': 'Khung giờ vừa hết chỗ.'}),
        );
        await request.response.close();
      });
      final api = CustomerApi(
        () => 'token',
        baseUrl: 'http://127.0.0.1:${server.port}/api',
      );
      await expectLater(
        api.request('/appointments', method: 'POST', body: {}),
        throwsA(isA<StateError>()),
      );
    },
  );
}
