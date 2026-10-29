import '../models/customer_notification.dart';
import 'customer_api.dart';
export '../demo/notification_demo.dart';

abstract interface class NotificationService {
  Future<List<CustomerNotification>> getNotifications(int customerId);
  Future<CustomerNotification> markRead(int id);
  Future<List<CustomerNotification>> markAllRead();
}

class ApiNotificationService implements NotificationService {
  ApiNotificationService(this.api);

  final CustomerApi api;
  int? _customerId;

  CustomerNotification _parse(Map<String, dynamic> value) {
    final type = switch (value['type']) {
      'appointment' => CustomerNotificationType.appointment,
      'repair' => CustomerNotificationType.repair,
      'maintenance' => CustomerNotificationType.maintenance,
      _ => CustomerNotificationType.general,
    };
    return CustomerNotification(
      id: value['id'] as int,
      title: value['title'] as String,
      message: value['message'] as String,
      createdAt: DateTime.parse(value['createdAt'] as String),
      type: type,
      isRead: value['isRead'] as bool,
    );
  }

  @override
  Future<List<CustomerNotification>> getNotifications(int customerId) async {
    _customerId = customerId;
    final result = <CustomerNotification>[];
    var page = 0;
    while (true) {
      final response = await api.request(
        '/customers/me/notifications?page=$page&size=100',
      ) as Map<String, dynamic>;
      result.addAll((response['items'] as List)
          .map((item) => _parse(item as Map<String, dynamic>)));
      page++;
      if (page >= (response['totalPages'] as int)) return result;
    }
  }

  @override
  Future<CustomerNotification> markRead(int id) async {
    final response = await api.request(
      '/customers/me/notifications/$id/read',
      method: 'PATCH',
    ) as Map<String, dynamic>;
    return _parse(response);
  }

  @override
  Future<List<CustomerNotification>> markAllRead() async {
    await api.request('/customers/me/notifications/read-all', method: 'PATCH');
    final customerId = _customerId;
    if (customerId == null) return const [];
    return getNotifications(customerId);
  }
}
