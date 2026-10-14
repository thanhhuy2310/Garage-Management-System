// TV3-TUAN9
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/models/history.dart';
import 'package:garage_customer_mobile/services/history_service.dart';

const _item = {
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
};

const _pagePayload = {
  'success': true,
  'message': 'ok',
  'data': {
    'items': [_item],
    'page': 0,
    'size': 10,
    'totalElements': 23,
    'totalPages': 3,
  },
};

final _detailPayload = {
  'success': true,
  'message': 'ok',
  'data': {
    'item': {..._item, 'category': 'BAO_DUONG_SUA_CHUA', 'result': null},
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

Future<HttpServer> _serve(_Recorded recorded, int status, Object? body) async {
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

ApiHistoryService _service(
  HttpServer server, {
  String? token = 'tok',
  String suffix = '',
}) => ApiHistoryService(
  tokenProvider: () => token,
  baseUrl: 'http://127.0.0.1:${server.port}/api$suffix',
);

void main() {
  test('getHistory sends the bearer token and the page parameters', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _pagePayload);
    addTearDown(() => server.close(force: true));

    final page = await _service(server).getHistory(page: 1, size: 5);

    expect(recorded.method, 'GET');
    expect(recorded.path, '/api/customers/me/history');
    expect(Uri.splitQueryString(recorded.query!), {'page': '1', 'size': '5'});
    expect(recorded.authorization, 'Bearer tok');
    expect(page.items, hasLength(1));
    expect(page.totalElements, 23);
    expect(page.totalPages, 3);
    expect(page.hasMore, isTrue);
    final item = page.items.single;
    expect(item.repairOrderId, 12);
    expect(item.plate, '51G-123.45');
    expect(item.vehicleName, 'Toyota Camry');
    expect(item.category, HistoryCategory.maintenance);
    expect(item.totalCost, 1380000);
    expect(item.date, DateTime(2026, 9, 20, 10));
  });

  test('the last page reports that there is nothing more to load', () async {
    final server = await _serve(_Recorded(), 200, {
      'data': {
        'items': <Object>[],
        'page': 2,
        'size': 10,
        'totalElements': 23,
        'totalPages': 3,
      },
    });
    addTearDown(() => server.close(force: true));

    final page = await _service(server).getHistory(page: 2);

    expect(page.hasMore, isFalse);
  });

  test('getHistory passes the vehicle filter next to the page', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _pagePayload);
    addTearDown(() => server.close(force: true));

    await _service(server).getHistory(vehicleId: 3);

    expect(Uri.splitQueryString(recorded.query!), {
      'page': '0',
      'size': '10',
      'vehicleId': '3',
    });
  });

  test('getHistoryVehicles reads the dedicated vehicle endpoint', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, {
      'data': [
        {
          'vehicleId': 3,
          'licensePlate': '51G-123.45',
          'brand': 'Toyota',
          'model': 'Camry',
          'completedCount': 14,
        },
        {'vehicleId': 4, 'licensePlate': '51A-456.78', 'brand': null},
      ],
    });
    addTearDown(() => server.close(force: true));

    final vehicles = await _service(server).getHistoryVehicles();

    expect(recorded.path, '/api/customers/me/history/vehicles');
    expect(recorded.authorization, 'Bearer tok');
    expect(vehicles.map((v) => v.id), [3, 4]);
    expect(vehicles.first.completedCount, 14);
    expect(vehicles.last.brand, '');
  });

  test('getHistoryDetail parses services, parts, totals and a null result', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _detailPayload);
    addTearDown(() => server.close(force: true));

    final detail = await _service(server).getHistoryDetail(12);

    expect(recorded.path, '/api/customers/me/history/12');
    expect(detail.item.category, HistoryCategory.mixed);
    expect(detail.item.result, isEmpty);
    expect(detail.services.single.name, 'Bảo dưỡng định kỳ');
    expect(detail.parts.single.lineTotal, 180000);
    expect(detail.serviceTotal, 1200000);
    expect(detail.partsTotal, 180000);
  });

  test('decimal money from SQL Server is rounded consistently to whole dong', () {
    final item = HistoryItem.fromJson({..._item, 'totalCost': 1380000.49});
    final line = HistoryServiceLine.fromJson({
      'serviceId': 1,
      'name': 'x',
      'type': 'y',
      'quantity': 1,
      'unitPrice': 1000.5,
      'lineTotal': 1000.5,
    });

    expect(item.totalCost, 1380000);
    expect(line.lineTotal, 1001);
  });

  test('null dates and result do not break parsing', () {
    final item = HistoryItem.fromJson({
      'repairOrderId': 4,
      'vehicleId': 1,
      'licensePlate': '51G-123.45',
      'category': 'SUA_CHUA',
      'summary': '',
      'totalCost': 0,
    });

    expect(item.date, isNull);
    expect(item.result, isEmpty);
    expect(item.vehicleName, isEmpty);
    expect(item.category, HistoryCategory.repair);
  });

  test('a trailing slash in the base URL does not produce a double slash', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _pagePayload);
    addTearDown(() => server.close(force: true));

    await _service(server, suffix: '/').getHistory();

    expect(recorded.path, '/api/customers/me/history');
  });

  test('a missing token fails before any request is made', () async {
    final recorded = _Recorded();
    final server = await _serve(recorded, 200, _pagePayload);
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
      await expectLater(
        _service(server).getHistoryDetail(1),
        throwsA(isA<HistoryException>()),
      );
    }
  });

  test('an invalid payload is reported instead of crashing', () async {
    final html = await _serve(_Recorded(), 200, '<html>oops</html>');
    addTearDown(() => html.close(force: true));
    await expectLater(
      _service(html).getHistory(),
      throwsA(isA<HistoryException>()),
    );

    final wrongShape = await _serve(_Recorded(), 200, {'data': 'not a page'});
    addTearDown(() => wrongShape.close(force: true));
    await expectLater(
      _service(wrongShape).getHistory(),
      throwsA(isA<HistoryException>()),
    );
    await expectLater(
      _service(wrongShape).getHistoryVehicles(),
      throwsA(isA<HistoryException>()),
    );
  });

  test('a refused connection becomes a friendly error', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final service = _service(server);
    await server.close(force: true);

    await expectLater(service.getHistory(), throwsA(isA<HistoryException>()));
  });
}
