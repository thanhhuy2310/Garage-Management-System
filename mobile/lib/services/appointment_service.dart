export '../demo/appointment_demo.dart';
import '../models/appointment.dart';

abstract interface class AppointmentService {
  Future<List<GarageServiceItem>> getServices();

  Future<List<Appointment>> getAppointments(int customerId);

  Future<BookingAvailability> getAvailability(DateTime date);

  Future<Appointment> createAppointment(AppointmentInput input);
}
