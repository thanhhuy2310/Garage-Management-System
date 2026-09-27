import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/app/app.dart';
import 'package:garage_customer_mobile/models/vehicle.dart';
import 'package:garage_customer_mobile/services/auth_service.dart';
import 'package:garage_customer_mobile/services/home_service.dart';
import 'package:garage_customer_mobile/services/vehicle_service.dart';

void main() {
  testWidgets('customer can open login and enter the app', (tester) async {
    await tester.pumpWidget(
      const GarageCustomerApp(
        authService: MockAuthService(),
        homeService: MockHomeService(),
      ),
    );

    expect(find.text('Gara Ô Tô Thành Công'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Đăng nhập'), findsWidgets);
    await tester.enterText(find.byType(EditableText).at(0), 'customer');
    await tester.enterText(find.byType(EditableText).at(1), 'demo123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    expect(find.text('Trang chủ'), findsWidgets);
    expect(find.text('Xin chào, Nguyễn Văn An'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Đặt lịch ngay'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn xe cần sử dụng dịch vụ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('customer can add a vehicle inside a new booking', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GarageCustomerApp(
        authService: MockAuthService(),
        homeService: MockHomeService(),
        vehicleService: _EmptyVehicleService(),
      ),
    );

    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).at(0), 'customer');
    await tester.enterText(find.byType(EditableText).at(1), 'demo123');
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Đặt lịch ngay'));
    await tester.pumpAndSettle();

    expect(find.text('Bạn chưa có xe'), findsOneWidget);
    expect(find.text('Thêm xe để tiếp tục'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Thêm xe để tiếp tục'));
    await tester.pumpAndSettle();

    expect(find.text('Thêm xe mới'), findsOneWidget);
    expect(find.text('Biển số *'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _EmptyVehicleService implements VehicleService {
  const _EmptyVehicleService();

  @override
  Future<List<Vehicle>> getVehicles(int customerId) async => const [];

  @override
  Future<Vehicle> addVehicle(int customerId, VehicleInput input) async {
    return Vehicle(
      id: 1,
      customerId: customerId,
      plate: input.plate,
      brand: input.brand,
      model: input.model,
      year: input.year,
      mileage: input.mileage,
    );
  }
}
