enum CustomerNotificationType { appointment, repair, quotation, maintenance, general, parts, payment }

class CustomerNotification {
  const CustomerNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.type,
    required this.isRead,
    this.repairOrderId,this.appointmentId,
  });
  final int id;
  final int? repairOrderId,appointmentId;
  final String title;
  final String message;
  final DateTime createdAt;
  final CustomerNotificationType type;
  final bool isRead;

  CustomerNotification copyWith({bool? isRead}) => CustomerNotification(
    id: id,
    repairOrderId:repairOrderId,appointmentId:appointmentId,
    title: title,
    message: message,
    createdAt: createdAt,
    type: type,
    isRead: isRead ?? this.isRead,
  );
}
