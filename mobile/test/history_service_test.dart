// TV3-TUAN9
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/models/history.dart';
import 'package:garage_customer_mobile/services/history_service.dart';

const _listPayload = {
  'success': true,
  'message': 'ok',
  'data': [
    {
      'repairOrderId': 12,
      'vehicleId': 3,
      'licensePlate': '51G-123.45',
      'brand': 'Toyota',
      'model': 'Camry',
      'createdAt': '2026-09-18T08:00:00',
      'startedAt': '2026-09-19T08:00:00',
      'completedAt': '2026-09-20T10:00:00',
      'category': 'BAO_DUONG',
      'summary': 'Bảo dưỡng định kỳ',
      'serviceCount': 1,
      'partCount': 1,
      'totalCost': 1380000.0,
      'result': 'Hoàn tất tốt',
    },
  ],
};

const _detailPayload = {
  'success': true,
  'message': 'ok',
  'data': {
    'item': {
      'repairOrderId': 12,
      'vehicleId': 3,
      'licensePlate': '51G-123.45',
      'brand': 'Toyota',
      'model': 'Camry',
      'category': 'BAO_DUONG_SUA_CHUA',
      'summary': 'x',
      'serviceCount': 1,
      'partCount': 1,
      'totalCost': 1380000.0,
      'result': '',
    },
    'services': [
      {
        'serviceId': 2,
        'name': 'Bảo dưỡng định kỳ',
        'type': 'BAO_DUONG',
        'quantity': 1,
        'unitPrice': 1200000.0,
        'lineTotal': 1200000.0,
      },
    ],
    'parts': [
      {
        'partId': 9,
        'name': 'Lọc dầu',
        'quantity': 2,
        'unitPrice': 90000.0,
        'lineTotal': 180000.0,
      },
    ],
    'serviceTotal': 1200000.0,
    'partsTotal': 180000.0,
  },
};

class _Recorded {
  String? method;
  String? path;
  String? query;
  String? authorization;
}

Future<HttpServer> _serve(
  _Recorded recorded,
  int status,
  Object? body,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((request) async {
    recorded
      ..method = request.method
      ..path = request.uri.path
      ..query = request.uri.query
      ..authorization = request.headers.value(HttpHeaders.authorizationHeader);
    request.response.statusCode = status;
    request.response.headers.contentType = ContentType.json;
    request.response.write(body is String ? body : jsonEncode(body));
    await request.response.close();
  });
  return server;
}

ApiHistoryService _service(HttpServer server, {String? token = 'tok'}) =>
    ApiHistoryService(
      tokenProvider: () => token,
      baseUrl: 'http://127.0.0.1:${server.port}/api',
    );

void main() {
  test('getHistory sends the bearer token and parses the response', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _listPayload);
    addTearDown(() => server.close(force: true));

    final items = await _service(server).getHistory();

    expect(recorded.method, 'GET');
    expect(recorded.path, '/api/customers/me/history');
    expect(recorded.query, isEmpty);
    expect(recorded.authorization, 'Bearer tok');
    expect(items, hasLength(1));
    expect(items.first.repairOrderId, 12);
    expect(items.first.plate, '51G-123.45');
    expect(items.first.vehicleName, 'Toyota Camry');
    expect(items.first.category, HistoryCategory.maintenance);
    expect(items.first.totalCost, 1380000);
    expect(items.first.date, DateTime(2026, 9, 20, 10));
  });

  test('getHistory passes the vehicle filter as a query parameter', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, {'data': <Object>[]});
    addTearDown(() => server.close(force: true));

    final items = await _service(server).getHistory(vehicleId: 3);

    expect(recorded.query, 'vehicleId=3');
    expect(items, isEmpty);
  });

  test('getHistoryDetail parses services, parts and totals', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _detailPayload);
    addTearDown(() => server.close(force: true));

    final detail = await _service(server).getHistoryDetail(12);

    expect(recorded.path, '/api/customers/me/history/12');
    expect(detail.item.category, HistoryCategory.mixed);
    expect(detail.services.single.name, 'Bảo dưỡng định kỳ');
    expect(detail.parts.single.lineTotal, 180000);
    expect(detail.serviceTotal, 1200000);
    expect(detail.partsTotal, 180000);
  });

  test('a missing token fails before any request is made', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _listPayload);
    addTearDown(() => server.close(force: true));

    await expectLater(
      _service(server, token: null).getHistory(),
      throwsA(isA<HistoryException>()),
    );
    expect(recorded.method, isNull);
  });

  test('401, 403 and 404 map to clear messages', () async {
    final cases = <int, String>{
      401: 'Phiên đăng nhập đã hết hạn',
      403: 'không có quyền',
      404: 'Không tìm thấy xe.',
    };
    for (final entry in cases.entries) {
      final server = await _serve(_Recorded(), entry.key, {
        'success': false,
        'message': 'Không tìm thấy xe.',
      });
      addTearDown(() => server.close(force: true));

      await expectLater(
        _service(server).getHistory(),
        throwsA(
          isA<HistoryException>().having(
            (error) => error.message,
            'message',
            contains(entry.value),
          ),
        ),
      );
    }
  });

  test('an invalid payload is reported instead of crashing', () async {
    final server = await _serve(_Recorded(), 200, '<html>oops</html>');
    addTearDown(() => server.close(force: true));
    await expectLater(
      _service(server).getHistory(),
      throwsA(isA<HistoryException>()),
    );

    final wrongShape = await _serve(_Recorded(), 200, {'data': 'not a list'});
    addTearDown(() => wrongShape.close(force: true));
    await expectLater(
      _service(wrongShape).getHistory(),
      throwsA(isA<HistoryException>()),
    );
  });

  test('a refused connection becomes a friendly error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final service = _service(server);
    await server.close(force: true);

    await expectLater(
      service.getHistory(),
      throwsA(isA<HistoryException>()),
    );
  });
}
