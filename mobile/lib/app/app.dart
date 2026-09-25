import 'package:flutter/material.dart';

import '../core/constants/app_config.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/booking/booking_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/quotations/quotations_screen.dart';
import '../screens/repairs/repair_progress_screen.dart';
import '../screens/shared/feature_placeholder_screen.dart';
import '../screens/shell/customer_shell.dart';
import '../screens/vehicles/vehicles_screen.dart';
import '../services/auth_service.dart';
import '../services/appointment_service.dart';
import '../services/home_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../services/quotation_service.dart';
import '../services/repair_service.dart';
import '../services/vehicle_service.dart';
import 'app_controller.dart';
import 'app_routes.dart';
import 'app_theme.dart';

class GarageCustomerApp extends StatefulWidget {
  const GarageCustomerApp({
    super.key,
    this.authService,
    this.homeService,
    this.vehicleService,
    this.appointmentService,
  });

  final AuthService? authService;
  final HomeService? homeService;
  final VehicleService? vehicleService;
  final AppointmentService? appointmentService;

  @override
  State<GarageCustomerApp> createState() => _GarageCustomerAppState();
}

class _GarageCustomerAppState extends State<GarageCustomerApp> {
  late final AppController controller = AppController(
    widget.authService ?? ApiAuthService(),
    widget.homeService ?? const MockHomeService(),
    widget.vehicleService ?? MockVehicleService(),
    widget.appointmentService ?? MockAppointmentService(),
    MockQuotationService(),
    MockRepairService(),
    MockNotificationService(),
    MockProfileService(),
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Route<dynamic> _route(RouteSettings settings) {
    final page = switch (settings.name) {
      AppRoutes.splash => SplashScreen(controller: controller),
      AppRoutes.login => LoginScreen(controller: controller),
      AppRoutes.home => CustomerShell(controller: controller),
      AppRoutes.booking => BookingScreen(controller: controller),
      AppRoutes.repairProgress => CustomerShell(
        controller: controller,
        initialIndex: 2,
      ),
      AppRoutes.notifications => CustomerShell(
        controller: controller,
        initialIndex: 3,
      ),
      AppRoutes.profile => CustomerShell(
        controller: controller,
        initialIndex: 4,
      ),
      AppRoutes.vehicles => VehiclesScreen(controller: controller),
      AppRoutes.appointments => CustomerShell(
        controller: controller,
        initialIndex: 1,
      ),
      AppRoutes.quotations => QuotationsScreen(controller: controller),
      AppRoutes.history => RepairProgressScreen(
        controller: controller,
        historyOnly: true,
      ),
      AppRoutes.changePassword => ChangePasswordScreen(controller: controller),
      _ => const FeaturePlaceholderScreen(
        title: 'Không tìm thấy trang',
        icon: Icons.error_outline,
      ),
    };
    return PageRouteBuilder<void>(
      settings: settings,
      pageBuilder: (_, animation, secondaryAnimation) => page,
      transitionsBuilder: (_, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          ),
      transitionDuration: const Duration(milliseconds: 220),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.garageName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: _route,
    );
  }
}
