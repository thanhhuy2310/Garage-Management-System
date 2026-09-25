import '../models/appointment.dart';
import '../models/vehicle.dart';

abstract interface class AppointmentService {
  Future<List<GarageServiceItem>> getServices();

  Future<List<Appointment>> getAppointments(int customerId);

  Future<BookingAvailability> getAvailability(DateTime date);

  Future<Appointment> createAppointment(AppointmentInput input);
}

class MockAppointmentService implements AppointmentService {
  MockAppointmentService();

  static const allSlots = [
    '08:00',
    '08:30',
    '09:00',
    '09:30',
    '10:00',
    '10:30',
    '11:00',
    '13:30',
    '14:00',
    '14:30',
    '15:00',
    '15:30',
    '16:00',
    '16:30',
  ];

  final List<GarageServiceItem> _services = const [
    GarageServiceItem(
      id: 1,
      name: 'Bảo dưỡng định kỳ',
      category: 'Bảo dưỡng',
      price: 250000,
      description: 'Kiểm tra và bảo dưỡng tổng quát.',
    ),
    GarageServiceItem(
      id: 2,
      name: 'Sửa chữa phanh',
      category: 'Sửa chữa',
      price: 200000,
      description: 'Kiểm tra hệ thống phanh.',
    ),
    GarageServiceItem(
      id: 3,
      name: 'Kiểm tra điều hòa',
      category: 'Điện - điều hòa',
      price: 250000,
      description: 'Kiểm tra hệ thống điều hòa.',
    ),
    GarageServiceItem(
      id: 4,
      name: 'Kiểm tra động cơ',
      category: 'Động cơ',
      price: 180000,
      description: 'Chẩn đoán tình trạng động cơ.',
    ),
    GarageServiceItem(
      id: 5,
      name: 'Thay lốp xe',
      category: 'Lốp',
      price: 120000,
      description: 'Tháo lắp và cân bằng lốp.',
    ),
    GarageServiceItem(
      id: 6,
      name: 'Thay dầu động cơ',
      category: 'Bảo dưỡng',
      price: 150000,
      description: 'Thay dầu động cơ theo tiêu chuẩn.',
    ),
  ];

  final List<Appointment> _appointments = [
    Appointment(
      id: 'LH001',
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
      date: DateTime.now().add(const Duration(days: 3)),
      time: '08:30',
      status: AppointmentStatus.confirmed,
      note: 'Kiểm tra tổng quát',
    ),
  ];

  @override
  Future<List<GarageServiceItem>> getServices() async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    return List.unmodifiable(_services);
  }

  @override
  Future<List<Appointment>> getAppointments(int customerId) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return List.unmodifiable(
      _appointments.where((item) => item.vehicle.customerId == customerId),
    );
  }

  @override
  Future<BookingAvailability> getAvailability(DateTime date) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    final normalized = DateTime(date.year, date.month, date.day);
    final today = DateTime.now();
    final current = DateTime(today.year, today.month, today.day);
    final fullyBooked =
        normalized.weekday == DateTime.sunday || normalized.day % 11 == 0;
    if (normalized.isBefore(current) || fullyBooked) {
      return const BookingAvailability(availableSlots: [], fullyBooked: true);
    }
    final available = allSlots
        .where((slot) => (allSlots.indexOf(slot) + normalized.day) % 3 != 0)
        .toList();
    return BookingAvailability(availableSlots: available, fullyBooked: false);
  }

  @override
  Future<Appointment> createAppointment(AppointmentInput input) async {
    await Future<void>.delayed(const Duration(milliseconds: 320));
    final appointment = Appointment(
      id: 'LH${(_appointments.length + 1).toString().padLeft(3, '0')}',
      vehicle: input.vehicle,
      service: input.service,
      date: input.date,
      time: input.time,
      status: AppointmentStatus.pending,
      note: input.note,
    );
    _appointments.add(appointment);
    return appointment;
  }
}
