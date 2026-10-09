// TV3-TUAN9
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/app/app_theme.dart';
import 'package:garage_customer_mobile/models/history.dart';
import 'package:garage_customer_mobile/screens/history/history_screen.dart';
import 'package:garage_customer_mobile/services/history_service.dart';

HistoryItem _item(
  int id, {
  int vehicleId = 1,
  String plate = '51G-123.45',
  HistoryCategory category = HistoryCategory.maintenance,
  String summary = 'Bảo dưỡng định kỳ',
  int total = 1380000,
}) => HistoryItem(
  repairOrderId: id,
  vehicleId: vehicleId,
  plate: plate,
  brand: 'Toyota',
  model: 'Camry',
  category: category,
  summary: summary,
  serviceCount: 1,
  partCount: 0,
  totalCost: total,
  result: 'Hoàn tất tốt',
  completedAt: DateTime(2026, 9, 20),
);

/// Test double của giao diện HistoryService: ghi lại các lần gọi và trả dữ liệu cấu hình sẵn.
class _FakeHistoryService implements HistoryService {
  _FakeHistoryService({this.items = const [], this.failFirst = false});

  List<HistoryItem> items;
  bool failFirst;
  final List<int?> calls = [];
  int detailCalls = 0;

  @override
  Future<List<HistoryItem>> getHistory({int? vehicleId}) async {
    calls.add(vehicleId);
    if (failFirst) {
      failFirst = false;
      throw const HistoryException('Không thể kết nối đến hệ thống.');
    }
    return vehicleId == null
        ? items
        : items.where((item) => item.vehicleId == vehicleId).toList();
  }

  @override
  Future<HistoryDetail> getHistoryDetail(int repairOrderId) async {
    detailCalls++;
    return HistoryDetail(
      item: items.firstWhere((item) => item.repairOrderId == repairOrderId),
      services: const [
        HistoryServiceLine(
          serviceId: 2,
          name: 'Thay dầu động cơ',
          type: 'BAO_DUONG',
          quantity: 1,
          unitPrice: 450000,
          lineTotal: 450000,
        ),
      ],
      parts: const [
        HistoryPartLine(
          partId: 9,
          name: 'Lọc dầu',
          quantity: 2,
          unitPrice: 90000,
          lineTotal: 180000,
        ),
      ],
      serviceTotal: 450000,
      partsTotal: 180000,
    );
  }
}

Future<void> _pump(WidgetTester tester, HistoryService service) async {
  await tester.pumpWidget(
    MaterialApp(theme: AppTheme.light, home: HistoryScreen(service: service)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows completed repairs from the service, newest first', (
    tester,
  ) async {
    final service = _FakeHistoryService(
      items: [
        _item(12, summary: 'Bảo dưỡng định kỳ'),
        _item(
          5,
          summary: 'Thay má phanh trước',
          category: HistoryCategory.repair,
          total: 500000,
        ),
      ],
    );

    await _pump(tester, service);

    expect(find.text('Phiếu #12'), findsOneWidget);
    expect(find.text('Phiếu #5'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Phiếu #12')).dy,
      lessThan(tester.getTopLeft(find.text('Phiếu #5')).dy),
    );
    expect(find.text('Bảo dưỡng'), findsOneWidget);
    expect(find.text('Sửa chữa'), findsOneWidget);
    expect(find.text('1.380.000 ₫'), findsOneWidget);
    expect(find.text('Hoàn thành: 20/09/2026'), findsNWidgets(2));
  });

  testWidgets('shows the empty state when there is no history', (tester) async {
    await _pump(tester, _FakeHistoryService());

    expect(find.text('Chưa có lịch sử sửa chữa'), findsOneWidget);
  });

  testWidgets('shows an error and retries', (tester) async {
    final service = _FakeHistoryService(items: [_item(12)], failFirst: true);

    await _pump(tester, service);
    expect(find.text('Không thể kết nối đến hệ thống.'), findsOneWidget);

    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Phiếu #12'), findsOneWidget);
    expect(service.calls, [null, null]);
  });

  testWidgets('lets the customer filter by vehicle', (tester) async {
    final service = _FakeHistoryService(
      items: [
        _item(12, vehicleId: 1, plate: '51G-123.45'),
        _item(5, vehicleId: 2, plate: '51A-456.78', summary: 'Kiểm tra phanh'),
      ],
    );

    await _pump(tester, service);
    expect(find.text('Phiếu #12'), findsOneWidget);
    expect(find.text('Phiếu #5'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, '51A-456.78'));
    await tester.pumpAndSettle();

    expect(service.calls.last, 2);
    expect(find.text('Phiếu #5'), findsOneWidget);
    expect(find.text('Phiếu #12'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả xe'));
    await tester.pumpAndSettle();

    expect(service.calls.last, isNull);
    expect(find.text('Phiếu #12'), findsOneWidget);
  });

  testWidgets('pull to refresh reloads the history', (tester) async {
    final service = _FakeHistoryService(items: [_item(12)]);
    await _pump(tester, service);
    expect(service.calls, hasLength(1));

    await tester.fling(find.byType(ListView).first, const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(service.calls.length, greaterThanOrEqualTo(2));
  });

  testWidgets('opening a repair shows services, parts and totals from the API', (
    tester,
  ) async {
    final service = _FakeHistoryService(items: [_item(12)]);
    await _pump(tester, service);

    await tester.tap(find.text('Phiếu #12'));
    await tester.pumpAndSettle();

    expect(service.detailCalls, 1);
    expect(find.text('Thay dầu động cơ'), findsOneWidget);
    expect(find.text('Lọc dầu'), findsOneWidget);
    expect(find.text('2 × 90.000 ₫'), findsOneWidget);
    expect(find.text('180.000 ₫'), findsWidgets);
    await tester.scrollUntilVisible(find.text('Tổng chi phí'), 200);
    expect(find.text('Tổng chi phí'), findsOneWidget);
    expect(find.text('Hoàn tất tốt'), findsOneWidget);
  });
}
