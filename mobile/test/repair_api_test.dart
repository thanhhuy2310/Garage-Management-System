import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/services/repair_service.dart';

import 'repair_progress_test.dart' show repairJson, session;

// Keep HTTP tests separate from widget binding, which disables real network requests.
void main() {
  test('API uses bearer identity and does not send a customer ID', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      expect(request.uri.path, '/api/customer/repairs');
      expect(request.uri.query, isEmpty);
      expect(request.headers.value('authorization'), 'Bearer test-token');
      request.response.headers.contentType = ContentType.json;
      request.response.write(
        jsonEncode({
          'success': true,
          'data': [repairJson()],
        }),
      );
      await request.response.close();
    });
    final values = await ApiRepairService(
      baseUrl: 'http://127.0.0.1:${server.port}/api',
    ).getRepairs(session);
    expect(values.single.progress.single.notes, 'Đã kiểm tra má phanh.');
  });

  test('expired session returns error rather than sample repairs', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      request.response.statusCode = 401;
      await request.response.close();
    });
    await expectLater(
      ApiRepairService(baseUrl: 'http://127.0.0.1:${server.port}/api')
          .getRepairs(session),
      throwsA(isA<RepairApiException>()),
    );
  });
}
