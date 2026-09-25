import 'package:flutter/material.dart';

import '../core/constants/app_config.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/shared/feature_placeholder_screen.dart';
import '../screens/shell/customer_shell.dart';
import '../services/auth_service.dart';
import '../services/home_service.dart';
import 'app_controller.dart';
import 'app_routes.dart';
import 'app_theme.dart';

class GarageCustomerApp extends StatefulWidget {
  const GarageCustomerApp({super.key, this.authService, this.homeService});

  final AuthService? authService;
  final HomeService? homeService;

  @override
  State<GarageCustomerApp> createState() => _GarageCustomerAppState();
}

class _GarageCustomerAppState extends State<GarageCustomerApp> {
  late final AppController controller = AppController(
    widget.authService ?? ApiAuthService(),
    widget.homeService ?? const MockHomeService(),
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
      AppRoutes.booking => CustomerShell(
        controller: controller,
        initialIndex: 1,
      ),
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
      AppRoutes.vehicles => const FeaturePlaceholderScreen(
        title: 'Xe của tôi',
        icon: Icons.directions_car_outlined,
      ),
      AppRoutes.appointments => const FeaturePlaceholderScreen(
        title: 'Lịch hẹn',
        icon: Icons.event_note_outlined,
      ),
      AppRoutes.quotations => const FeaturePlaceholderScreen(
        title: 'Báo giá',
        icon: Icons.request_quote_outlined,
      ),
      AppRoutes.history => const FeaturePlaceholderScreen(
        title: 'Lịch sử sửa chữa',
        icon: Icons.history,
      ),
      AppRoutes.changePassword => const FeaturePlaceholderScreen(
        title: 'Đổi mật khẩu',
        icon: Icons.password_outlined,
      ),
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
