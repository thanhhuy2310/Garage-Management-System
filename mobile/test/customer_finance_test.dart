import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/screens/finance/customer_finance_screen.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';

class FixtureApi extends CustomerApi {
  FixtureApi(this.response) : super(() => 'fixture-token');
  dynamic response;
  final paths = <String>[];
  @override
  Future<dynamic> request(String path, {String method = 'GET', Map<String, dynamic>? body}) async {
    paths.add(path);
    if (response is Exception) throw response as Exception;
    return response;
  }
}

void main() {
  testWidgets('empty and error states do not invent invoice data', (tester) async {
    final api = FixtureApi([]);
    await tester.pumpWidget(MaterialApp(home: CustomerFinanceScreen(api: api)));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có hóa đơn.'), findsOneWidget);
    expect(api.paths.single, '/customers/me/invoices');
    api.response = Exception('Mất kết nối');
    await tester.tap(find.byTooltip('Làm mới'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Mất kết nối'), findsOneWidget);
    expect(find.text('Bạn chưa có hóa đơn.'), findsNothing);
    api.response = [];
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();
    expect(find.text('Bạn chưa có hóa đơn.'), findsOneWidget);
  });

  testWidgets('statistics sends selected year and preserves server totals', (tester) async {
    final api = FixtureApi({'vehicleCount': 1, 'completedVisits': 3, 'repairVisits': 3, 'maintenanceVisits': 1, 'totalCost': 750000, 'customerCost': 600000, 'awaitingInvoicesOrInsurance': 0, 'vehicles': [], 'months': []});
    await tester.pumpWidget(MaterialApp(home: CustomerFinanceScreen(api: api, statistics: true)));
    await tester.pumpAndSettle();
    expect(find.text('Lượt hoàn thành: 3'), findsOneWidget);
    expect(find.text('Tổng chi phí: 750.000 ₫'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '2026');
    await tester.tap(find.text('Xem thống kê'));
    await tester.pumpAndSettle();
    expect(api.paths.last, '/customers/me/statistics?year=2026');
    await tester.enterText(find.byType(TextField), '0');
    await tester.tap(find.text('Xem thống kê'));
    await tester.pumpAndSettle();
    expect(api.paths.length, 2);
    expect(find.text('Nhập năm từ 1900 đến 9999 hoặc để trống.'), findsOneWidget);
  });
}
