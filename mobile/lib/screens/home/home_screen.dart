import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_routes.dart';
import '../../app/app_theme.dart';
import '../../core/constants/app_config.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.controller,
    required this.onSelectTab,
    required this.onOpenRoute,
  });

  final AppController controller;
  final ValueChanged<int> onSelectTab;
  final ValueChanged<String> onOpenRoute;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loadingHome && controller.summary == null) {
          return const LoadingState();
        }
        if (controller.homeError != null && controller.summary == null) {
          return ErrorState(
            message: controller.homeError!,
            onRetry: controller.loadHome,
          );
        }
        final profile = controller.profile;
        final summary = controller.summary;
        return RefreshIndicator(
          onRefresh: controller.loadHome,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.brandDark,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Xin chào,',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.fullName ?? 'Khách hàng',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: AppColors.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            summary?.upcomingAppointment == null
                                ? 'Chưa có lịch hẹn sắp tới'
                                : 'Lịch hẹn tiếp theo: ${summary!.upcomingAppointment}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Truy cập nhanh'),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: MediaQuery.sizeOf(context).width >= 600 ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.28,
                children: [
                  _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Đặt lịch',
                    onTap: () => onSelectTab(1),
                  ),
                  _QuickAction(
                    icon: Icons.directions_car_outlined,
                    label: 'Xe của tôi',
                    onTap: () => onOpenRoute(AppRoutes.vehicles),
                  ),
                  _QuickAction(
                    icon: Icons.build_circle_outlined,
                    label: 'Xem tiến độ',
                    onTap: () => onSelectTab(2),
                  ),
                  _QuickAction(
                    icon: Icons.history,
                    label: 'Lịch sử',
                    onTap: () => onOpenRoute(AppRoutes.history),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Thông tin của bạn'),
              const SizedBox(height: 12),
              _SummaryTile(
                icon: Icons.directions_car_outlined,
                label: 'Xe của tôi',
                value: '${summary?.vehicleCount ?? 0}',
                onTap: () => onOpenRoute(AppRoutes.vehicles),
              ),
              const SizedBox(height: 10),
              _SummaryTile(
                icon: Icons.car_repair_outlined,
                label: 'Xe đang sửa chữa',
                value: '${summary?.activeRepairCount ?? 0}',
                onTap: () => onSelectTab(2),
              ),
              const SizedBox(height: 10),
              _SummaryTile(
                icon: Icons.request_quote_outlined,
                label: 'Báo giá chờ xác nhận',
                value: '${summary?.pendingQuotationCount ?? 0}',
                onTap: () => onOpenRoute(AppRoutes.quotations),
              ),
              const SizedBox(height: 10),
              _SummaryTile(
                icon: Icons.notifications_none,
                label: 'Thông báo mới',
                value: '${summary?.unreadNotificationCount ?? 0}',
                onTap: () => onSelectTab(3),
              ),
              const SizedBox(height: 24),
              Text(
                AppConfig.garageName,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 23),
              ),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        minTileHeight: 72,
        onTap: onTap,
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
