import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/models/quotation.dart';
import 'package:garage_customer_mobile/services/api_quotation_service.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';

// Historical quotations retain their original SQL amounts; new prices are validated by Backend.
Map<String, dynamic> quote() => {
  'id': 14,
  'repairOrderId': 19,
  'vehicleId': 12,
  'customerId': 7,
  'plate': '51A-67890',
  'createdAt': '2026-10-30T10:30:00',
  'status': 'CHO_XAC_NHAN',
  'version': 5,
  'revision': 2,
  'total': 350001.00,
  'lines': [
    {
      'kind': 'SERVICE',
      'name': 'Kiểm tra phanh',
      'quantity': 2,
      'unitPrice': 150000.25,
      'amount': 300000.50,
    },
    {
      'kind': 'PART',
      'name': 'Lọc dầu',
      'quantity': 1,
      'unitPrice': 50000.50,
      'amount': 50000.50,
    },
  ],
};

void main() {
  test('historical quotation retains server amounts and sends the viewed version', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    Map<String, dynamic>? decision;
    final paths = <String>[];
    server.listen((request) async {
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer customer-token',
      );
      paths.add('${request.method} ${request.uri.path}');
      final row = quote();
      Object data = [row];
      if (request.method == 'POST') {
        decision = jsonDecode(
          await utf8.decoder.bind(request).join(),
        ) as Map<String, dynamic>;
        data = {
          ...row,
          'status': 'KHONG_DONG_Y',
          'version': 6,
          'rejectionReason': decision!['reason'],
        };
      }
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'success': true, 'data': data}));
      await request.response.close();
    });
    final service = ApiQuotationService(
      CustomerApi(
        () => 'customer-token',
        baseUrl: 'http://127.0.0.1:${server.port}/api',
      ),
    );
    final current = (await service.getQuotations(999)).single;
    expect(current.total, 350001);
    expect(current.lines.first.amount, 300000.50);
    expect(current.lines.last.unitPrice, 50000.50);
    expect(current.revision, 2);
    final updated = await service.updateStatus(
      current.id,
      QuotationStatus.rejected,
      version: current.version,
      reason: 'Kiểm tra lại chi phí',
    );
    expect(decision, {
      'version': 5,
      'accepted': false,
      'reason': 'Kiểm tra lại chi phí',
    });
    expect(paths, ['GET /api/quotations', 'POST /api/quotations/14/decision']);
    expect(updated.status, QuotationStatus.rejected);
    expect(updated.version, 6);
  });

  test('stale decision surfaces conflict and does not retry approval against a newer version', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    var calls = 0;
    server.listen((request) async {
      calls++;
      await request.drain<void>();
      request.response.statusCode = 409;
      request.response.write(
        jsonEncode({
          'success': false,
          'message': 'Báo giá đã thay đổi. Vui lòng tải lại.',
        }),
      );
      await request.response.close();
    });
    final service = ApiQuotationService(
      CustomerApi(
        () => 'token',
        baseUrl: 'http://127.0.0.1:${server.port}/api',
      ),
    );
    await expectLater(
      service.updateStatus('14', QuotationStatus.confirmed, version: 1),
      throwsA(isA<StateError>()),
    );
    expect(calls, 1);
    await expectLater(
      service.updateStatus('14', QuotationStatus.confirmed),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      service.updateStatus('14', QuotationStatus.draft, version: 1),
      throwsA(isA<StateError>()),
    );
    expect(calls, 1);
  });
}
