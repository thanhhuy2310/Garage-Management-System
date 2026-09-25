import 'package:flutter_test/flutter_test.dart';
import 'package:garage_customer_mobile/models/quotation.dart';
import 'package:garage_customer_mobile/services/notification_service.dart';
import 'package:garage_customer_mobile/services/quotation_service.dart';

void main() {
  test('customer can confirm a pending quotation', () async {
    final service = MockQuotationService();
    final pending = (await service.getQuotations(1))
        .firstWhere((item) => item.status == QuotationStatus.pending);

    final updated = await service.updateStatus(
      pending.id,
      QuotationStatus.confirmed,
    );

    expect(updated.status, QuotationStatus.confirmed);
  });

  test('customer can mark all notifications as read', () async {
    final service = MockNotificationService();
    expect(
      (await service.getNotifications(1)).any((item) => !item.isRead),
      isTrue,
    );

    final updated = await service.markAllRead();

    expect(updated.every((item) => item.isRead), isTrue);
  });
}
