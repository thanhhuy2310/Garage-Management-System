import '../models/customer_notification.dart';

abstract interface class NotificationService {
  Future<List<CustomerNotification>> getNotifications(int customerId);
  Future<CustomerNotification> markRead(int id);
  Future<List<CustomerNotification>> markAllRead();
}

class MockNotificationService implements NotificationService {
  final List<CustomerNotification> _items = [
    CustomerNotification(
      id: 1,
      title: 'Lịch hẹn đã được xác nhận',
      message: 'Lịch hẹn 08:30 của bạn đã được gara xác nhận.',
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      type: CustomerNotificationType.appointment,
      isRead: false,
    ),
    CustomerNotification(
      id: 2,
      title: 'Xe đang được sửa chữa',
      message: 'Kỹ thuật viên đã bắt đầu thực hiện hạng mục bảo dưỡng.',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      type: CustomerNotificationType.repair,
      isRead: false,
    ),
    CustomerNotification(
      id: 3,
      title: 'Phụ tùng đang được chuẩn bị',
      message: 'Má phanh mới dự kiến có tại gara vào ngày mai.',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      type: CustomerNotificationType.parts,
      isRead: true,
    ),
    CustomerNotification(
      id: 4,
      title: 'Hóa đơn đã thanh toán',
      message: 'Gara đã ghi nhận khoản thanh toán 1.115.000 ₫.',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      type: CustomerNotificationType.payment,
      isRead: true,
    ),
  ];

  @override
  Future<List<CustomerNotification>> getNotifications(int customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List.unmodifiable(_items);
  }

  @override
  Future<CustomerNotification> markRead(int id) async {
    final index = _items.indexWhere((item) => item.id == id);
    _items[index] = _items[index].copyWith(isRead: true);
    return _items[index];
  }

  @override
  Future<List<CustomerNotification>> markAllRead() async {
    for (var index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
    return List.unmodifiable(_items);
  }
}
