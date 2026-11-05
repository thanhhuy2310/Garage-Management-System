import 'vehicle.dart';

enum AppointmentStatus { pending, confirmed, arrived, cancelled, completed }

class GarageServiceItem {
  const GarageServiceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
  });

  final int id;
  final String name;
  final String category;
  final num price;
  final String description;
}

class Appointment {
  const Appointment({
    required this.id,
    required this.vehicle,
    required this.service,
    required this.date,
    required this.time,
    required this.status,
    required this.note,
    this.version = 0,
  });

  final String id;
  final Vehicle vehicle;
  final GarageServiceItem service;
  final DateTime date;
  final String time;
  final AppointmentStatus status;
  final String note;
  final int version;
}

class AppointmentInput {
  const AppointmentInput({
    required this.customerId,
    required this.vehicle,
    required this.service,
    required this.date,
    required this.time,
    required this.note,
  });

  final int customerId;
  final Vehicle vehicle;
  final GarageServiceItem service;
  final DateTime date;
  final String time;
  final String note;
}

DateTime garageToday() {
  final local = DateTime.now().toUtc().add(const Duration(hours: 7));
  return DateTime(local.year, local.month, local.day);
}

class BookingAvailability {
  const BookingAvailability({
    required this.availableSlots,
    required this.fullyBooked,
    this.configured = true,
    this.statuses = const {},
  });

  final List<String> availableSlots;
  final bool fullyBooked;
  final bool configured;
  final Map<String, String> statuses;
}
