import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/models/customer_notification.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';
import 'package:garage_customer_mobile/services/notification_service.dart';

void main() {
  test('notification adapter reads all API pages and persists read actions', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final requests = <String>[];
    var allRead = false;
    server.listen((request) async {
      expect(request.headers.value(HttpHeaders.authorizationHeader), 'Bearer session-token');
      requests.add('${request.method} ${request.uri.path}?${request.uri.query}');
      Object? data;
      if (request.uri.path.endsWith('/read-all')) {
        allRead = true;
        data = {'updatedCount': 2, 'unreadCount': 0};
      } else if (request.uri.path.endsWith('/read')) {
        data = notification(1, true);
      } else {
        final page = int.parse(request.uri.queryParameters['page']!);
        data = {
          'items': [notification(page + 1, allRead)],
          'page': page,
          'size': 100,
          'totalElements': 2,
          'totalPages': 2,
        };
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'success': true, 'data': data}));
      await request.response.close();
    });

    final api = CustomerApi(() => 'session-token',
        baseUrl: 'http://127.0.0.1:${server.port}/api');
    final service = ApiNotificationService(api);
    final initial = await service.getNotifications(42);
    expect(initial.map((item) => item.id), [1, 2]);
    expect(initial.first.type, CustomerNotificationType.maintenance);
    expect((await service.markRead(1)).isRead, true);
    expect((await service.markAllRead()).every((item) => item.isRead), true);
    expect(requests, contains('PATCH /api/customers/me/notifications/1/read?'));
    expect(requests, contains('PATCH /api/customers/me/notifications/read-all?'));
    expect(requests.where((path) => path.contains('page=1')).length, 2);
  });
}

Map<String, dynamic> notification(int id, bool isRead) => {
      'id': id,
      'title': 'Nhắc bảo dưỡng',
      'message': 'Xe đã đến kỳ kiểm tra.',
      'createdAt': '2026-10-29T08:00:00',
      'type': 'maintenance',
      'isRead': isRead,
    };
