import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/app/app.dart';
import 'package:garage_customer_mobile/services/auth_service.dart';
import 'package:garage_customer_mobile/services/home_service.dart';

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
    expect(find.text('Nguyễn Văn An'), findsOneWidget);

    await tester.tap(find.text('Đặt lịch'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đặt lịch mới'));
    await tester.pumpAndSettle();

    expect(find.text('Chọn xe cần sử dụng dịch vụ'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
