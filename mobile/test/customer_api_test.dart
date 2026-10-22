import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';
import 'package:garage_customer_mobile/services/vehicle_service.dart';
import 'package:garage_customer_mobile/services/home_service.dart';
import 'package:garage_customer_mobile/services/profile_service.dart';
import 'package:garage_customer_mobile/models/vehicle.dart';
import 'package:garage_customer_mobile/core/utils/formatters.dart';
void main() {
  test('real adapters use the signed-in token, API vehicle fields and password endpoint', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requests = <String>[];
    server.listen((req) async {
      expect(req.headers.value('Authorization'), 'Bearer current-session');
      requests.add('${req.method} ${req.uri.path}');
      Object? data;
      final vehicle = {'id': 8, 'customerId': 42, 'licensePlate': '51A-123.45', 'brand': 'Toyota', 'model': 'Vios', 'year': 2020, 'mileage': 42000};
      if (req.uri.path.endsWith('/profile')) { data = {'id': 42, 'fullName': 'Trần An', 'phone': '0900000042'}; }
      else if (req.uri.path.endsWith('/vehicles') && req.method == 'GET') { data = [vehicle]; }
      else if (req.uri.path.endsWith('/vehicles')) {
        final body = jsonDecode(await utf8.decoder.bind(req).join());
        expect(body['customerId'], 42); expect(body['licensePlate'], '51A-123.45'); data = vehicle;
      } else if (req.uri.path.endsWith('/change-password')) {
        final body = jsonDecode(await utf8.decoder.bind(req).join());
        expect(req.method, 'PUT'); expect(body['currentPassword'], 'old-pass'); expect(body['newPassword'], 'new-pass-123');
      }
      req.response.headers.contentType = ContentType.json;
      req.response.write(jsonEncode({'success': true, 'data': data})); await req.response.close();
    });
    final api = CustomerApi(() => 'current-session', baseUrl: 'http://127.0.0.1:${server.port}/api');
    expect((await ApiHomeService(api).getProfile(42)).fullName, 'Trần An');
    final vehicles = ApiVehicleService(api);
    expect((await vehicles.getVehicles(42)).single.customerId, 42);
    expect((await vehicles.addVehicle(42, const VehicleInput(plate: '51A-123.45', brand: 'Toyota', model: 'Vios'))).id, 8);
    await ApiProfileService(api).changePassword(currentPassword: 'old-pass', newPassword: 'new-pass-123');
    expect(requests, contains('GET /api/customers/42/vehicles'));
  });
  test('missing session never sends a request or falls back to demo', () async {
    final api = CustomerApi(() => null);
    await expectLater(ApiVehicleService(api).getVehicles(42), throwsStateError);
  });
  test('currency preserves cents and large decimal strings', () {
    expect(formatCurrency('9999999999999999.99'), '9.999.999.999.999.999,99 ₫');
    expect(formatCurrency(125000.50), '125.000,50 ₫');
  });
}
