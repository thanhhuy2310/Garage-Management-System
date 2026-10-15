import '../models/customer_notification.dart';
export '../demo/notification_demo.dart';

abstract interface class NotificationService {
  Future<List<CustomerNotification>> getNotifications(int customerId);
  Future<CustomerNotification> markRead(int id);
  Future<List<CustomerNotification>> markAllRead();
}
