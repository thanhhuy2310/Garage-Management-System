// TV3-TUAN9
import 'dart:async';
import 'dart:math';

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

HistoryPage _page(List<HistoryItem> items, {int page = 0, int? total, int size = 10}) {
  final count = total ?? items.length;
  return HistoryPage(
    items: items,
    page: page,
    size: size,
    totalElements: count,
    totalPages: (count + size - 1) ~/ size,
  );
}

List<HistoryVehicle> _vehiclesOf(List<HistoryItem> items) {
  final seen = <int>{};
  return [
    for (final item in items)
      if (seen.add(item.vehicleId))
        HistoryVehicle(
          id: item.vehicleId,
          plate: item.plate,
          brand: item.brand,
          model: item.model,
          completedCount: 1,
        ),
  ];
}

HistoryDetail _detailOf(HistoryItem item) => HistoryDetail(
  item: item,
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

/// Test double của giao diện HistoryService: phân trang/lọc trên dữ liệu cấu hình sẵn và ghi lại các lần gọi.
class _FakeHistoryService implements HistoryService {
  _FakeHistoryService({this.items = const [], this.failFirst = false});

  List<HistoryItem> items;
  bool failFirst;
  final List<({int? vehicleId, int page})> calls = [];
  int detailCalls = 0;

  @override
  Future<HistoryPage> getHistory({
    int? vehicleId,
    int page = 0,
    int size = 10,
  }) async {
    calls.add((vehicleId: vehicleId, page: page));
    if (failFirst) {
      failFirst = false;
      throw const HistoryException('Không thể kết nối đến hệ thống.');
    }
    final filtered = vehicleId == null
        ? items
        : items.where((item) => item.vehicleId == vehicleId).toList();
    final start = page * size;
    final slice = start >= filtered.length
        ? <HistoryItem>[]
        : filtered.sublist(start, min(start + size, filtered.length));
    return _page(slice, page: page, total: filtered.length, size: size);
  }

  @override
  Future<List<HistoryVehicle>> getHistoryVehicles() async => _vehiclesOf(items);

  @override
  Future<HistoryDetail> getHistoryDetail(int repairOrderId) async {
    detailCalls++;
    return _detailOf(
      items.firstWhere((item) => item.repairOrderId == repairOrderId),
    );
  }
}

/// Mỗi lần gọi getHistory trả về một Completer để test chủ động quyết định thời điểm phản hồi.
class _ControlledService implements HistoryService {
  final List<int?> requested = [];
  final List<Completer<HistoryPage>> pending = [];

  @override
  Future<HistoryPage> getHistory({
    int? vehicleId,
    int page = 0,
    int size = 10,
  }) {
    requested.add(vehicleId);
    final completer = Completer<HistoryPage>();
    pending.add(completer);
    return completer.future;
  }

  @override
  Future<List<HistoryVehicle>> getHistoryVehicles() async => const [
    HistoryVehicle(id: 1, plate: '51G-123.45', brand: 'Toyota', model: 'Camry', completedCount: 1),
    HistoryVehicle(id: 2, plate: '51A-456.78', brand: 'Kia', model: 'Seltos', completedCount: 1),
  ];

  @override
  Future<HistoryDetail> getHistoryDetail(int repairOrderId) =>
      throw UnimplementedError();
}

// Danh sách chính (cuộn dọc); hàng chip lọc xe cuộn ngang nên không được dùng làm đích cuộn.
final _mainList = find.byWidgetPredicate(
  (widget) => widget is Scrollable && widget.axisDirection == AxisDirection.down,
);

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
    expect(find.text('Hiển thị 2/2 lượt'), findsOneWidget);
    expect(find.text('Tải thêm'), findsNothing);
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
    expect(service.calls.map((call) => call.page), [0, 0]);
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

    expect(service.calls.last.vehicleId, 2);
    expect(service.calls.last.page, 0);
    expect(find.text('Phiếu #5'), findsOneWidget);
    expect(find.text('Phiếu #12'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Tất cả xe'));
    await tester.pumpAndSettle();

    expect(service.calls.last.vehicleId, isNull);
    expect(find.text('Phiếu #12'), findsOneWidget);
  });

  testWidgets('loads the next page on demand and keeps the order', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final service = _FakeHistoryService(
      items: [for (var id = 100; id > 88; id--) _item(id)],
    );

    await _pump(tester, service);
    expect(find.text('Hiển thị 10/12 lượt'), findsOneWidget);
    expect(service.calls.map((call) => call.page), [0]);

    await tester.scrollUntilVisible(
      find.text('Tải thêm'),
      300,
      scrollable: _mainList.first,
    );
    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();

    expect(service.calls.map((call) => call.page), [0, 1]);
    await tester.scrollUntilVisible(
      find.text('Phiếu #89'),
      300,
      scrollable: _mainList.first,
    );
    expect(find.text('Phiếu #89'), findsOneWidget);
    expect(find.text('Tải thêm'), findsNothing);
  });

  testWidgets('changing the vehicle filter resets to the first page', (tester) async {
    final service = _FakeHistoryService(
      items: [
        for (var id = 100; id > 88; id--) _item(id, vehicleId: 1, plate: '51G-123.45'),
        _item(5, vehicleId: 2, plate: '51A-456.78'),
      ],
    );

    await _pump(tester, service);
    await tester.scrollUntilVisible(
      find.text('Tải thêm'),
      300,
      scrollable: _mainList.first,
    );
    await tester.tap(find.text('Tải thêm'));
    await tester.pumpAndSettle();
    expect(service.calls.map((call) => call.page), [0, 1]);

    await tester.tap(find.widgetWithText(ChoiceChip, '51A-456.78'));
    await tester.pumpAndSettle();

    expect(service.calls.last.vehicleId, 2);
    expect(service.calls.last.page, 0);
    expect(find.text('Phiếu #5'), findsOneWidget);
    expect(find.text('Phiếu #100'), findsNothing);
  });

  testWidgets('pull to refresh reloads from the first page', (tester) async {
      final service = _FakeHistoryService(items: [_item(12)]);
      await _pump(tester, service);
      expect(service.calls, hasLength(1));

      final refresh = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
      await refresh.onRefresh();
      await tester.pumpAndSettle();

      expect(service.calls.length, greaterThanOrEqualTo(2));
      expect(service.calls.last.page, 0);
    });

  testWidgets('a late response for an old filter never overwrites the new list', (
    tester,
  ) async {
    final service = _ControlledService();
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.light, home: HistoryScreen(service: service)),
    );
    await tester.pump();
    service.pending[0].complete(
      _page([_item(12, vehicleId: 1), _item(5, vehicleId: 2, plate: '51A-456.78')]),
    );
    await tester.pump();

    // Người dùng đổi bộ lọc liên tục: xe 1 rồi xe 2.
    await tester.tap(find.widgetWithText(ChoiceChip, '51G-123.45'));
    await tester.pump();
    await tester.tap(find.widgetWithText(ChoiceChip, '51A-456.78'));
    await tester.pump();
    expect(service.requested, [null, 1, 2]);

    // Phản hồi của xe 2 (mới nhất) về trước, phản hồi trễ của xe 1 về sau.
    service.pending[2].complete(_page([_item(5, vehicleId: 2, plate: '51A-456.78')]));
    await tester.pump();
    service.pending[1].complete(_page([_item(12, vehicleId: 1)]));
    await tester.pump();

    expect(find.text('Phiếu #5'), findsOneWidget);
    expect(find.text('Phiếu #12'), findsNothing);
  });

  testWidgets('opening a repair shows services, parts and totals from the API', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    final service = _FakeHistoryService(items: [_item(12)]);
    await _pump(tester, service);

    await tester.tap(find.text('Phiếu #12'));
    await tester.pumpAndSettle();

    expect(service.detailCalls, 1);
    expect(find.text('Thay dầu động cơ'), findsOneWidget);
    expect(find.text('Lọc dầu'), findsOneWidget);
    expect(find.text('2 × 90.000 ₫'), findsOneWidget);
    expect(find.text('180.000 ₫'), findsWidgets);
    expect(find.text('Tổng chi phí'), findsOneWidget);
    expect(find.text('Hoàn tất tốt'), findsOneWidget);
  });
}
