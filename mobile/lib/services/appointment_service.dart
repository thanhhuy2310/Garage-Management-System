export '../demo/appointment_demo.dart';
import '../models/appointment.dart';

abstract interface class AppointmentService {
  Future<List<GarageServiceItem>> getServices();

  Future<List<Appointment>> getAppointments(int customerId);

  Future<BookingAvailability> getAvailability(DateTime date);

  Future<Appointment> createAppointment(AppointmentInput input);
}

/// Separate capability keeps existing booking fixtures compatible.
abstract interface class AppointmentChanges {
  Future<Appointment> cancel(Appointment item, String reason);
  Future<Appointment> reschedule(
    Appointment item,
    DateTime date,
    String time,
    String reason,
  );
}
