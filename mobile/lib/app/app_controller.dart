import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/remembered_session.dart';
import '../services/customer_api.dart';

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

  late final RememberedSession? _storage = _authService is ApiAuthService
      ? RememberedSession()
      : null;
  Timer? _expiry;
  VoidCallback? onExpired;

  void _activate(UserSession current) {
    session = current;
    _expiry?.cancel();
    if (_storage != null) {
      _expiry = Timer(
        RememberedSession.remaining(current.accessToken),
        () async {
          _clear();
          onExpired?.call();
          await _storage.save(null);
        },
      );
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    super.dispose();
  }

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
    try {
      final saved = await _storage?.restore();
      if (saved != null) {
        _activate(saved);
        await loadHome();
      }
    } catch (_) {
      authError = 'Không thể khôi phục phiên. Vui lòng kiểm tra kết nối hoặc đăng nhập lại.';
    }
    initialized = true;
    notifyListeners();
  }

  Future<bool> signIn({
    required String username,
    required String password,
    bool remember = false,
  }) async {
    signingIn = true;
    authError = null;
    notifyListeners();
    try {
      final current = await _authService.login(
        username: username,
        password: password,
      );
      await _storage?.save(remember ? current.accessToken : null);
      _activate(current);
      await loadHome();
      return true;
    } on AuthException catch (error) {
      authError = error.message;
      return false;
    } catch (_) {
      authError = 'Không thể mở phiên đăng nhập. Vui lòng thử lại.';
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
      if (!identical(session, current)) return;
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
    if (!identical(session, current)) return;
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
      notificationService.getNotifications(current.customerId),
    ]);
    if (!identical(session, current)) return;
    quotations = values[0] as List<Quotation>;
    notifications = values[1] as List<CustomerNotification>;
    notifyListeners();
  }

  Future<void> loadRepairs() async {
    final current = session;
    if (current == null) return;
    final loaded = await repairService.getRepairs(current);
    if (!identical(session, current)) return;
    repairs = loaded;
    notifyListeners();
  }

  Future<void> loadQuotations() async {
    final current = session;
    if (current == null) return;
    final loaded = await quotationService.getQuotations(current.customerId);
    if (!identical(session, current)) return;
    quotations = loaded;
    notifyListeners();
  }

  Future<void> respondToQuotation(
    String id,
    QuotationStatus status, {
    int? version,
    String? reason,
  }) async {
    final current = session;
    final viewed = quotations.firstWhere((item) => item.id == id);
    final updated = await quotationService.updateStatus(
      id,
      status,
      version: version ?? viewed.version,
      reason: reason,
    );
    if (!identical(session, current)) return;
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
    if (current != null) {
      if (_storage != null) {
        try {
          await CustomerApi(() => current.accessToken)
              .request('/auth/logout', method: 'POST');
        } on SessionExpired {
          /* Already invalid. */
        }
      } else {
        await _authService.logout(current);
      }
    }
    await _storage?.save(null);
    _clear();
  }

  void _clear() {
    _expiry?.cancel();
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
  }
}
