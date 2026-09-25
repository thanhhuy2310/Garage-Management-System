import 'package:flutter/foundation.dart';

import '../models/customer_profile.dart';
import '../models/customer_notification.dart';
import '../models/home_summary.dart';
import '../models/quotation.dart';
import '../models/repair_order.dart';
import '../models/user_session.dart';
import '../models/vehicle.dart';
import '../models/appointment.dart';
import '../services/appointment_service.dart';
import '../services/auth_service.dart';
import '../services/home_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/quotation_service.dart';
import '../services/repair_service.dart';
import '../services/vehicle_service.dart';

class AppController extends ChangeNotifier {
  AppController(
    this._authService,
    this._homeService,
    this.vehicleService,
    this.appointmentService,
    this.quotationService,
    this.repairService,
    this.notificationService,
    this.profileService,
  );

  final AuthService _authService;
  final HomeService _homeService;
  final VehicleService vehicleService;
  final AppointmentService appointmentService;
  final QuotationService quotationService;
  final RepairService repairService;
  final NotificationService notificationService;
  final ProfileService profileService;

  UserSession? session;
  CustomerProfile? profile;
  HomeSummary? summary;
  bool initialized = false;
  bool signingIn = false;
  bool loadingHome = false;
  String? authError;
  String? homeError;
  List<Vehicle> vehicles = const [];
  List<GarageServiceItem> services = const [];
  List<Appointment> appointments = const [];
  List<Quotation> quotations = const [];
  List<RepairOrder> repairs = const [];
  List<CustomerNotification> notifications = const [];

  bool get isLoggedIn => session != null;

  Future<void> initialize() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    initialized = true;
    notifyListeners();
  }

  Future<bool> signIn({
    required String username,
    required String password,
  }) async {
    signingIn = true;
    authError = null;
    notifyListeners();
    try {
      session = await _authService.login(
        username: username,
        password: password,
      );
      await loadHome();
      return true;
    } on AuthException catch (error) {
      authError = error.message;
      return false;
    } finally {
      signingIn = false;
      notifyListeners();
    }
  }

  Future<void> loadHome() async {
    final current = session;
    if (current == null) return;
    loadingHome = true;
    homeError = null;
    notifyListeners();
    try {
      final values = await Future.wait([
        _homeService.getProfile(current.customerId),
        _homeService.getSummary(current.customerId),
      ]);
      profile = values[0] as CustomerProfile;
      summary = values[1] as HomeSummary;
    } catch (_) {
      homeError = 'Không thể tải thông tin. Vui lòng thử lại.';
    } finally {
      loadingHome = false;
      notifyListeners();
    }
  }

  Future<void> loadBookingData() async {
    final current = session;
    if (current == null) return;
    final values = await Future.wait([
      vehicleService.getVehicles(current.customerId),
      appointmentService.getServices(),
      appointmentService.getAppointments(current.customerId),
    ]);
    vehicles = values[0] as List<Vehicle>;
    services = values[1] as List<GarageServiceItem>;
    appointments = values[2] as List<Appointment>;
    notifyListeners();
  }

  Future<Vehicle> addVehicle(VehicleInput input) async {
    final current = session;
    if (current == null) throw StateError('Chưa đăng nhập.');
    final vehicle = await vehicleService.addVehicle(current.customerId, input);
    vehicles = [...vehicles, vehicle];
    notifyListeners();
    return vehicle;
  }

  Future<Appointment> createAppointment(AppointmentInput input) async {
    final appointment = await appointmentService.createAppointment(input);
    appointments = [appointment, ...appointments];
    notifyListeners();
    return appointment;
  }

  Future<void> loadCustomerExperience() async {
    final current = session;
    if (current == null) return;
    final values = await Future.wait([
      quotationService.getQuotations(current.customerId),
      repairService.getRepairs(current.customerId),
      notificationService.getNotifications(current.customerId),
    ]);
    quotations = values[0] as List<Quotation>;
    repairs = values[1] as List<RepairOrder>;
    notifications = values[2] as List<CustomerNotification>;
    notifyListeners();
  }

  Future<void> respondToQuotation(String id, QuotationStatus status) async {
    final updated = await quotationService.updateStatus(id, status);
    quotations = [
      for (final item in quotations)
        if (item.id == id) updated else item,
    ];
    notifyListeners();
  }

  Future<void> markNotificationRead(int id) async {
    final updated = await notificationService.markRead(id);
    notifications = [
      for (final item in notifications)
        if (item.id == id) updated else item,
    ];
    notifyListeners();
  }

  Future<void> markAllNotificationsRead() async {
    notifications = await notificationService.markAllRead();
    notifyListeners();
  }

  Future<void> saveProfile(CustomerProfile value) async {
    profile = await profileService.updateProfile(value);
    notifyListeners();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => profileService.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  void updateProfile(CustomerProfile value) {
    profile = value;
    notifyListeners();
  }

  Future<void> signOut() async {
    final current = session;
    session = null;
    profile = null;
    summary = null;
    vehicles = const [];
    services = const [];
    appointments = const [];
    quotations = const [];
    repairs = const [];
    notifications = const [];
    notifyListeners();
    if (current != null) await _authService.logout(current);
  }
}
