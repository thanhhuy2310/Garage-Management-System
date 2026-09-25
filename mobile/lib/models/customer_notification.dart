enum CustomerNotificationType { appointment, repair, parts, payment }

class CustomerNotification {
  const CustomerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.isRead,
  });
  final int id;
  final String title;
  final String message;
  final DateTime createdAt;
  final CustomerNotificationType type;
  final bool isRead;

  CustomerNotification copyWith({bool? isRead}) => CustomerNotification(
    id: id,
    title: title,
    message: message,
    createdAt: createdAt,
    type: type,
    isRead: isRead ?? this.isRead,
  );
}
