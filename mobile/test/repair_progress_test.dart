import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/app/app_controller.dart';
import 'package:garage_customer_mobile/models/repair_order.dart';
import 'package:garage_customer_mobile/models/user_session.dart';
import 'package:garage_customer_mobile/screens/repairs/repair_progress_screen.dart';
import 'package:garage_customer_mobile/services/appointment_service.dart';
import 'package:garage_customer_mobile/services/auth_service.dart';
import 'package:garage_customer_mobile/services/home_service.dart';
import 'package:garage_customer_mobile/services/notification_service.dart';
import 'package:garage_customer_mobile/services/profile_service.dart';
import 'package:garage_customer_mobile/services/quotation_service.dart';
import 'package:garage_customer_mobile/services/repair_service.dart';
import 'package:garage_customer_mobile/services/vehicle_service.dart';

const session = UserSession(
  accessToken: 'test-token',
  accountId: 8,
  username: 'customer-test',
  customerId: 7,
);
Map<String, dynamic> repairJson({String status = 'DANG_SUA'}) => {
  'order': {
    'id': 42,
    'vehicleId': 9,
    'customerId': 7,
    'licensePlate': '51A-12345',
    'brand': null,
    'model': null,
    'createdAt': '2026-10-06T08:00:00',
    'status': status,
    'customerRequest': 'Kiểm tra phanh',
  },
  'services': [
    {'id': 3, 'name': 'Kiểm tra hệ thống phanh', 'status': 'HOAN_TAT'},
  ],
  'assignments': [],
  'progress': [
    {
      'id': 12,
      'serviceId': 3,
      'status': 'HOAN_TAT',
      'notes': 'Đã kiểm tra má phanh.',
      'createdAt': '2026-10-06T09:30:00',
    },
  ],
};

void main() {
  test('maps SQL IDs, nullable fields and actual event timestamps', () {
    final repair = RepairOrder.fromJson(repairJson());
    expect(repair.vehicle.id, 9);
    expect(repair.vehicle.customerId, 7);
    expect(repair.technician, 'Chưa phân công');
    expect(repair.completedServices, 1);
    expect(repair.updatedAt.toUtc(), DateTime.utc(2026, 10, 6, 2, 30));
    expect(
      RepairOrder.fromJson(repairJson(status: 'UNKNOWN')).status,
      RepairStatus.unknown,
    );
    final legacy = repairJson()..['progress'] = [];
    expect(RepairOrder.fromJson(legacy).progress, isEmpty);
  });

  testWidgets(
    'narrow screen shows actual progress, history and refresh without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final service = TestRepairService();
      final controller = makeController(service);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.3)),
            child: child!,
          ),
          home: RepairProgressScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('51A-12345'), findsOneWidget);
      expect(find.text('1/1 dịch vụ đã hoàn tất'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Đã kết thúc'));
      await tester.pumpAndSettle();
      expect(find.text('Chưa có lịch sử sửa chữa'), findsOneWidget);
      service.completed = true;
      await tester.tap(find.byTooltip('Làm mới tiến độ'));
      await tester.pumpAndSettle();
      expect(find.text('51A-12345'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'failed requests show retry instead of stale or fabricated repairs',
    (tester) async {
      final service = TestRepairService()..fail = true;
      final controller = makeController(service);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(home: RepairProgressScreen(controller: controller)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Không thể tải dữ liệu'), findsOneWidget);
      expect(find.text('51A-12345'), findsNothing);
      service.fail = false;
      await tester.tap(find.text('Thử lại'));
      await tester.pumpAndSettle();
      expect(find.text('51A-12345'), findsOneWidget);
    },
  );
}

AppController makeController(RepairService service) => AppController(
  const MockAuthService(),
  const MockHomeService(),
  MockVehicleService(),
  MockAppointmentService(),
  MockQuotationService(),
  service,
  MockNotificationService(),
  MockProfileService(),
)..session = session;

class TestRepairService implements RepairService {
  bool fail = false;
  bool completed = false;
  @override
  Future<List<RepairOrder>> getRepairs(UserSession session) async {
    if (fail) throw const RepairApiException('Mất kết nối.');
    return [
      RepairOrder.fromJson(
        repairJson(status: completed ? 'HOAN_TAT' : 'DANG_SUA'),
      ),
    ];
  }
}
