import '../models/repair_order.dart';
import '../models/vehicle.dart';

abstract interface class RepairService {
  Future<List<RepairOrder>> getRepairs(int customerId);
}

class MockRepairService implements RepairService {
  final List<RepairOrder> _items = [
    RepairOrder(
      id: 'SC-2026-024',
      vehicle: const Vehicle(
        id: 1,
        customerId: 1,
        plate: '51G-123.45',
        brand: 'Toyota',
        model: 'Camry',
        year: 2020,
        mileage: 45200,
      ),
      status: RepairStatus.inProgress,
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      description: 'Bảo dưỡng định kỳ và kiểm tra hệ thống phanh.',
      technician: 'Nguyễn Minh Khang',
    ),
    RepairOrder(
      id: 'SC-2026-017',
      vehicle: const Vehicle(
        id: 2,
        customerId: 1,
        plate: '51K-678.90',
        brand: 'Honda',
        model: 'CR-V',
        year: 2022,
        mileage: 21800,
      ),
      status: RepairStatus.waitingParts,
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      description: 'Thay má phanh trước.',
      technician: 'Trần Quốc Bảo',
    ),
    RepairOrder(
      id: 'SC-2026-006',
      vehicle: const Vehicle(
        id: 1,
        customerId: 1,
        plate: '51G-123.45',
        brand: 'Toyota',
        model: 'Camry',
        year: 2020,
        mileage: 43800,
      ),
      status: RepairStatus.completed,
      updatedAt: DateTime.now().subtract(const Duration(days: 38)),
      description: 'Thay dầu động cơ và lọc dầu.',
      technician: 'Nguyễn Minh Khang',
    ),
  ];

  @override
  Future<List<RepairOrder>> getRepairs(int customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 240));
    return List.unmodifiable(
      _items.where((item) => item.vehicle.customerId == customerId),
    );
  }
}
