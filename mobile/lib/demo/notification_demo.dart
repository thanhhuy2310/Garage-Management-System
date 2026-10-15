// MOCK_ONLY: in-memory demo, never persisted to the garage.
import '../models/customer_notification.dart';
import '../services/notification_service.dart';

class MockNotificationService implements NotificationService {
  int? _customerId;
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
    _customerId = customerId;
    return List.unmodifiable(customerId == 1 ? _items : <CustomerNotification>[]);
  }

  @override
  Future<CustomerNotification> markRead(int id) async {
    if (_customerId != 1) throw StateError('Không có thông báo minh họa cho tài khoản này.');
    final index = _items.indexWhere((item) => item.id == id);
    _items[index] = _items[index].copyWith(isRead: true);
    return _items[index];
  }

  @override
  Future<List<CustomerNotification>> markAllRead() async {
    if (_customerId != 1) return const [];
    for (var index = 0; index < _items.length; index++) {
      _items[index] = _items[index].copyWith(isRead: true);
    }
    return List.unmodifiable(_items);
  }
}
