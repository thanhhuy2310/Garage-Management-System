import '../models/appointment.dart';
import '../models/quotation.dart';
import '../models/vehicle.dart';

abstract interface class QuotationService {
  Future<List<Quotation>> getQuotations(int customerId);
  Future<Quotation> updateStatus(String id, QuotationStatus status);
}

class MockQuotationService implements QuotationService {
  final List<Quotation> _items = [
    Quotation(
      id: 'BG-2026-018',
      vehicle: const Vehicle(
        id: 1,
        customerId: 1,
        plate: '51G-123.45',
        brand: 'Toyota',
        model: 'Camry',
        year: 2020,
        mileage: 45200,
      ),
      service: const GarageServiceItem(
        id: 1,
        name: 'Bảo dưỡng định kỳ',
        category: 'Bảo dưỡng',
        price: 250000,
        description: 'Kiểm tra và bảo dưỡng tổng quát.',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      status: QuotationStatus.pending,
      lines: const [
        QuotationLine(name: 'Công bảo dưỡng', quantity: 1, unitPrice: 250000),
        QuotationLine(name: 'Dầu động cơ', quantity: 4, unitPrice: 180000),
        QuotationLine(name: 'Lọc dầu', quantity: 1, unitPrice: 145000),
      ],
    ),
    Quotation(
      id: 'BG-2026-011',
      vehicle: const Vehicle(
        id: 2,
        customerId: 1,
        plate: '51K-678.90',
        brand: 'Honda',
        model: 'CR-V',
        year: 2022,
        mileage: 21800,
      ),
      service: const GarageServiceItem(
        id: 2,
        name: 'Sửa chữa phanh',
        category: 'Sửa chữa',
        price: 200000,
        description: 'Kiểm tra hệ thống phanh.',
      ),
      createdAt: DateTime.now().subtract(const Duration(days: 12)),
      status: QuotationStatus.confirmed,
      lines: const [
        QuotationLine(name: 'Má phanh trước', quantity: 1, unitPrice: 1250000),
        QuotationLine(name: 'Công thay thế', quantity: 1, unitPrice: 250000),
      ],
    ),
  ];

  @override
  Future<List<Quotation>> getQuotations(int customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return List.unmodifiable(
      _items.where((item) => item.vehicle.customerId == customerId),
    );
  }

  @override
  Future<Quotation> updateStatus(String id, QuotationStatus status) async {
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final index = _items.indexWhere((item) => item.id == id);
    final updated = _items[index].copyWith(status: status);
    _items[index] = updated;
    return updated;
  }
}
