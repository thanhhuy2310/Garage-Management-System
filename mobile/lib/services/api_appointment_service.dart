import '../models/appointment.dart';
import '../models/vehicle.dart';
import 'appointment_service.dart';
import 'customer_api.dart';

/// Production booking adapter. Customer ownership and capacity are checked by the API.
class ApiAppointmentService implements AppointmentService, AppointmentChanges {
  ApiAppointmentService(this.api);
  final CustomerApi api;
  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  static Appointment fromJson(Map<String, dynamic> data) => Appointment(
    id: data['id'].toString(),
    vehicle: Vehicle(
      id: data['vehicleId'] as int,
      customerId: data['customerId'] as int,
      plate: data['plate'] as String,
      brand: data['brand'] as String? ?? '',
      model: data['model'] as String? ?? '',
      year: data['year'] as int?,
      mileage: data['mileage'] as int?,
    ),
    service: GarageServiceItem(
      id: data['serviceId'] as int? ?? 0,
      name: data['serviceName'] as String? ?? 'Tư vấn chung',
      category: data['serviceType'] as String? ?? '',
      price: data['unitPrice'] as num? ?? 0,
      description: '',
    ),
    date: DateTime.parse(data['date'] as String),
    time: (data['time'] as String).substring(0, 5),
    status: switch (data['status']) {
      'CHO_XAC_NHAN' => AppointmentStatus.pending,
      'DA_XAC_NHAN' => AppointmentStatus.confirmed,
      'DA_DEN' => AppointmentStatus.arrived,
      'HUY' || 'DA_HUY' => AppointmentStatus.cancelled,
      'HOAN_TAT' => AppointmentStatus.completed,
      _ => throw FormatException(
        'Trạng thái lịch hẹn không được hỗ trợ: ${data['status']}',
      ),
    },
    note: data['note'] as String? ?? '',
    version: data['version'] as int,
  );
  @override
  Future<List<GarageServiceItem>> getServices() async {
    final data = await api.request('/services') as List;
    return data
        .map(
          (s) => GarageServiceItem(
            id: s['id'] as int,
            name: s['name'] as String,
            category: s['type'] as String? ?? '',
            price: s['unitPrice'] as num,
            description: s['description'] as String? ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<List<Appointment>> getAppointments(int customerId) async {
    final data = await api.request('/appointments') as List;
    return data.map((r) => fromJson(r as Map<String, dynamic>)).toList();
  }

  @override
  Future<BookingAvailability> getAvailability(DateTime date) async {
    final data = await api.request(
      '/appointments/availability?date=${dateKey(date)}',
    ) as Map<String, dynamic>;
    final slots = (data['slots'] as List)
        .where((s) => (s['remaining'] as int) > 0)
        .map((s) => (s['time'] as String).substring(0, 5))
        .toList();
    return BookingAvailability(
      availableSlots: slots,
      fullyBooked: slots.isEmpty,
      configured: data['configured'] as bool,
    );
  }

  @override
  Future<Appointment> createAppointment(AppointmentInput input) async =>
      fromJson(
        await api.request(
          '/appointments',
          method: 'POST',
          body: {
            'vehicleId': input.vehicle.id,
            'serviceId': input.service.id == 0 ? null : input.service.id,
            'date': dateKey(input.date),
            'time': input.time,
            'note': input.note,
          },
        ) as Map<String, dynamic>,
      );
  @override
  Future<Appointment> cancel(Appointment item, String reason) async => fromJson(
    await api.request(
      '/appointments/${item.id}/cancel',
      method: 'PATCH',
      body: {'version': item.version, 'reason': reason},
    ) as Map<String, dynamic>,
  );
  @override
  Future<Appointment> reschedule(
    Appointment item,
    DateTime date,
    String time,
    String reason,
  ) async => fromJson(
    await api.request(
      '/appointments/${item.id}/reschedule',
      method: 'PATCH',
      body: {
        'version': item.version,
        'date': dateKey(date),
        'time': time,
        'reason': reason,
      },
    ) as Map<String, dynamic>,
  );
}
