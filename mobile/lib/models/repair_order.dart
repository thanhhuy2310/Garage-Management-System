import 'vehicle.dart';

enum RepairStatus {
  pending,
  inspecting,
  inProgress,
  waitingParts,
  completed,
  cancelled,
  unknown,
}

class RepairOrder {
  const RepairOrder({
    required this.id,
    required this.vehicle,
    required this.status,
    required this.updatedAt,
    required this.description,
    required this.technician,
    this.result,
    this.services = const [],
    this.progress = const [],
  });
  final String id;
  final Vehicle vehicle;
  final RepairStatus status;
  final DateTime updatedAt;
  final String description;
  final String technician;
  final String? result;
  final List<RepairServiceLine> services;
  final List<RepairProgressEvent> progress;

  int get completedServices =>
      services.where((line) => line.status == 'HOAN_TAT').length;

  factory RepairOrder.fromJson(Map<String, dynamic> json) {
    final order = json['order'] as Map<String, dynamic>;
    final progress = (json['progress'] as List? ?? [])
        .map(
          (value) =>
              RepairProgressEvent.fromJson(value as Map<String, dynamic>),
        )
        .toList();
    final names = (json['assignments'] as List? ?? [])
        .map((value) => (value['technician']['fullName'] as String))
        .join(', ');
    return RepairOrder(
      id: '#${order['id']}',
      vehicle: Vehicle(
        id: order['vehicleId'] as int,
        customerId: order['customerId'] as int,
        plate: order['licensePlate'] as String,
        brand: order['brand'] as String? ?? '',
        model: order['model'] as String? ?? '',
        year: null,
        mileage: null,
      ),
      status: switch (order['status']) {
        'MOI_TAO' || 'CHO_SUA' || 'CHO_XAC_NHAN' => RepairStatus.pending,
        'DANG_KIEM_TRA' => RepairStatus.inspecting,
        'DANG_SUA' => RepairStatus.inProgress,
        'CHO_PHU_TUNG' => RepairStatus.waitingParts,
        'HOAN_TAT' => RepairStatus.completed,
        'HUY' || 'DA_HUY' => RepairStatus.cancelled,
        _ => RepairStatus.unknown,
      },
      updatedAt: progress.isNotEmpty
          ? progress.first.createdAt
          : parseGarageDate(
              (order['completedAt'] ?? order['startedAt'] ?? order['createdAt'])
                  as String,
            ),
      description:
          order['customerRequest'] as String? ??
          'Chưa ghi nhận yêu cầu sửa chữa.',
      technician: names.isEmpty ? 'Chưa phân công' : names,
      result: order['result'] as String?,
      services: (json['services'] as List? ?? [])
          .map(
            (value) => RepairServiceLine(
              id: value['id'] as int,
              name: value['name'] as String,
              status: value['status'] as String? ?? 'CHO_SUA',
            ),
          )
          .toList(),
      progress: progress,
    );
  }
}

class RepairServiceLine {
  const RepairServiceLine({
    required this.id,
    required this.name,
    required this.status,
  });
  final int id;
  final String name;
  final String status;
}

class RepairProgressEvent {
  const RepairProgressEvent({
    required this.id,
    required this.status,
    required this.notes,
    required this.createdAt,
    this.serviceId,
  });
  final int id;
  final String status;
  final String notes;
  final DateTime createdAt;
  final int? serviceId;
  factory RepairProgressEvent.fromJson(Map<String, dynamic> json) =>
      RepairProgressEvent(
        id: json['id'] as int,
        status: json['status'] as String,
        notes: json['notes'] as String,
        createdAt: parseGarageDate(json['createdAt'] as String),
        serviceId: json['serviceId'] as int?,
      );
}

DateTime parseGarageDate(String value) => DateTime.parse(
  RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value) ? value : '$value+07:00',
).toLocal();
