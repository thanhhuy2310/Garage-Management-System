import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';

void main() {
  test('customer finance uses authenticated HTTP and reads the server envelope', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final client = HttpClient();
    final api = CustomerApi(() => 'customer-token', client: client, baseUrl: 'http://127.0.0.1:${server.port}/api');
    final handled = server.first.then((request) async {
      expect(request.uri.path, '/api/customers/me/statistics');
      expect(request.uri.queryParameters, {'vehicleId': '7', 'year': '2026'});
      expect(request.headers.value('authorization'), 'Bearer customer-token');
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'success': true, 'data': {'completedVisits': 3, 'totalCost': 750000}}));
      await request.response.close();
    });
    try {
      final data = await api.request('/customers/me/statistics?vehicleId=7&year=2026');
      expect(data['completedVisits'], 3);
      expect(data['totalCost'], 750000);
      await handled;
    } finally { client.close(force: true); await server.close(force: true); }
  });
}
