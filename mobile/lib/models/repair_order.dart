import 'vehicle.dart';

enum RepairStatus { pending, inspecting, inProgress, waitingParts, completed }

class RepairOrder {
  const RepairOrder({
    required this.id,
    required this.vehicle,
    required this.status,
    required this.updatedAt,
    required this.description,
    required this.technician,
  });
  final String id;
  final Vehicle vehicle;
  final RepairStatus status;
  final DateTime updatedAt;
  final String description;
  final String technician;
}
