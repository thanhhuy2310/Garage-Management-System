import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:garage_customer_mobile/app/app.dart';
import 'package:garage_customer_mobile/core/widgets/primary_button.dart';
import 'package:garage_customer_mobile/services/auth_service.dart';
import 'package:garage_customer_mobile/services/api_quotation_service.dart';
import 'package:garage_customer_mobile/services/customer_api.dart';
import 'package:garage_customer_mobile/models/quotation.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const username = String.fromEnvironment('VERIFY_USERNAME');
  const password = String.fromEnvironment('VERIFY_PASSWORD');
  const quoteId = String.fromEnvironment('VERIFY_QUOTE_ID');
  Future<void> waitFor(WidgetTester tester, Finder finder) async {
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 300));
    }
    expect(finder, findsWidgets);
  }

  Future<void> openQuote(
    WidgetTester tester,
    int revision,
    String total,
  ) async {
    expect(username, isNotEmpty);
    expect(quoteId, isNotEmpty);
    await tester.pumpWidget(const GarageCustomerApp());
    await waitFor(tester, find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField).at(0), username);
    await tester.enterText(find.byType(TextFormField).at(1), password);
    await tester.tap(find.widgetWithText(PrimaryButton, 'Đăng nhập'));
    await waitFor(tester, find.byType(NavigationBar));
    await waitFor(tester, find.text('Báo giá chờ xác nhận'));
    await tester.scrollUntilVisible(
      find.text('Báo giá chờ xác nhận').first,
      250,
      scrollable: find
          .descendant(
            of: find.byType(ListView).first,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Báo giá chờ xác nhận').first);
    final title = find.text('BG$quoteId · Lần $revision');
    await waitFor(tester, title);
    await tester.tap(title);
    await waitFor(tester, find.text('Chi tiết báo giá'));
    await tester.pumpAndSettle();
    expect(find.text(total), findsOneWidget);
    expect(find.text('Chờ xác nhận'), findsOneWidget);
  }

  Future<void> verifyDecision(
    QuotationStatus status,
    int version,
    num total,
  ) async {
    final session = await ApiAuthService().login(
      username: username,
      password: password,
    );
    final api = ApiQuotationService(CustomerApi(() => session.accessToken));
    final record = (await api.getQuotations(session.customerId))
        .singleWhere((q) => q.id == quoteId);
    expect(record.status, status);
    expect(record.version, version);
    expect(record.total, total);
  }

  testWidgets('quotation Android stage 1 rejects Web quote with reason', (
    tester,
  ) async {
    await openQuote(tester, 1, '200.000 ₫');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Từ chối'));
    await waitFor(tester, find.text('Từ chối báo giá?'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Xem lại số lượng dịch vụ');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Từ chối'),
      ),
    );
    await waitFor(tester, find.text('Đã từ chối'));
    expect(
      find.text('Lý do từ chối: Xem lại số lượng dịch vụ'),
      findsOneWidget,
    );
    await verifyDecision(QuotationStatus.rejected, 2, 200000.00);
    await tester.tap(find.byTooltip('Tải lại báo giá'));
    await tester.pumpAndSettle();
    expect(find.text('Đã từ chối'), findsOneWidget);
  });

  testWidgets('quotation Android stage 2 approves revised Web quote', (
    tester,
  ) async {
    await openQuote(tester, 2, '350.000 ₫');
    await tester.tap(find.widgetWithText(PrimaryButton, 'Đồng ý'));
    await waitFor(tester, find.text('Đồng ý báo giá?'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Đồng ý'),
      ),
    );
    await waitFor(tester, find.text('Đã đồng ý'));
    await verifyDecision(QuotationStatus.confirmed, 6, 350000);
    await tester.tap(find.byTooltip('Tải lại báo giá'));
    await tester.pumpAndSettle();
    expect(find.text('Đã đồng ý'), findsOneWidget);
  });
}
