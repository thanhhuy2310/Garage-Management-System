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
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 700;
            return RefreshIndicator(
              onRefresh: controller.loadHome,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  isWide ? 24 : 16,
                  12,
                  isWide ? 24 : 16,
                  32,
                ),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 920),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HomeHero(
                            name: profile?.fullName ?? 'Khách hàng',
                            upcomingAppointment: summary?.upcomingAppointment,
                            tall: isWide,
                            onBook: () => onOpenRoute(AppRoutes.booking),
                          ),
                          const SizedBox(height: 26),
                          const SectionHeader(
                            title: 'Tiện ích dành cho bạn',
                            subtitle: 'Thao tác nhanh trong một chạm',
                          ),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: isWide ? 4 : 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: isWide ? 1.36 : 1.42,
                            children: [
                              _QuickAction(
                                icon: Icons.calendar_month_outlined,
                                label: 'Đặt lịch',
                                description: 'Chọn dịch vụ và giờ',
                                accent: true,
                                onTap: () => onOpenRoute(AppRoutes.booking),
                              ),
                              _QuickAction(
                                icon: Icons.directions_car_outlined,
                                label: 'Xe của tôi',
                                description: 'Quản lý thông tin xe',
                                onTap: () => onOpenRoute(AppRoutes.vehicles),
                              ),
                              _QuickAction(
                                icon: Icons.car_repair_outlined,
                                label: 'Xem tiến độ',
                                description: 'Theo dõi sửa chữa',
                                onTap: () => onSelectTab(2),
                              ),
                              _QuickAction(
                                icon: Icons.history,
                                label: 'Lịch sử',
                                description: 'Dịch vụ đã sử dụng',
                                onTap: () => onOpenRoute(AppRoutes.history),
                              ),
                            ],
                          ),
                          const SizedBox(height: 26),
                          const SectionHeader(
                            title: 'Dịch vụ nổi bật',
                            subtitle: 'Chăm sóc xe toàn diện tại gara',
                          ),
                          const SizedBox(height: 12),
                          const SizedBox(
                            height: 116,
                            child: _ServiceHighlights(),
                          ),
                          const SizedBox(height: 26),
                          const SectionHeader(
                            title: 'Tổng quan',
                            subtitle: 'Thông tin cần bạn quan tâm',
                          ),
                          const SizedBox(height: 12),
                          LayoutBuilder(
                            builder: (context, overviewConstraints) {
                              final twoColumns =
                                  overviewConstraints.maxWidth >= 620;
                              final width = twoColumns
                                  ? (overviewConstraints.maxWidth - 12) / 2
                                  : overviewConstraints.maxWidth;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  SizedBox(
                                    width: width,
                                    child: _SummaryTile(
                                      icon: Icons.directions_car_outlined,
                                      label: 'Xe của tôi',
                                      value: '${summary?.vehicleCount ?? 0}',
                                      onTap: () =>
                                          onOpenRoute(AppRoutes.vehicles),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: _SummaryTile(
                                      icon: Icons.car_repair_outlined,
                                      label: 'Xe đang sửa chữa',
                                      value:
                                          '${summary?.activeRepairCount ?? 0}',
                                      onTap: () => onSelectTab(2),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: _SummaryTile(
                                      icon: Icons.request_quote_outlined,
                                      label: 'Báo giá chờ xác nhận',
                                      value:
                                          '${summary?.pendingQuotationCount ?? 0}',
                                      onTap: () =>
                                          onOpenRoute(AppRoutes.quotations),
                                    ),
                                  ),
                                  SizedBox(
                                    width: width,
                                    child: _SummaryTile(
                                      icon: Icons.notifications_none,
                                      label: 'Thông báo mới',
                                      value:
                                          '${summary?.unreadNotificationCount ?? 0}',
                                      onTap: () => onSelectTab(3),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 26),
                          Text(
                            AppConfig.garageName,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero({
    required this.name,
    required this.upcomingAppointment,
    required this.onBook,
    required this.tall,
  });

  final String name;
  final String? upcomingAppointment;
  final VoidCallback onBook;
  final bool tall;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Chào $name. Đặt lịch chăm sóc xe tại gara.',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: SizedBox(
          height: tall ? 292 : 258,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/garage_home_hero.png',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                excludeFromSemantics: true,
                errorBuilder: (_, _, _) =>
                    const ColoredBox(color: AppColors.brandDark),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF20B1F33),
                      Color(0xB30B1F33),
                      Color(0x260B1F33),
                    ],
                    stops: [0, 0.58, 1],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: const Text(
                        'CHĂM XE CHUYÊN NGHIỆP',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Xin chào, $name',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        height: 1.18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Đặt lịch nhanh, theo dõi rõ ràng.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: onBook,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      icon: const Icon(Icons.calendar_month_outlined, size: 19),
                      label: const Text('Đặt lịch ngay'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          color: AppColors.accent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            upcomingAppointment == null
                                ? 'Bạn chưa có lịch hẹn sắp tới'
                                : 'Lịch tiếp theo: $upcomingAppointment',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.accent = false,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label. $description',
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    icon,
                    color: accent ? AppColors.accent : AppColors.primary,
                    size: 22,
                  ),
                ),
                const Spacer(),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ServiceHighlights extends StatelessWidget {
  const _ServiceHighlights();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.settings_suggest_outlined, 'Bảo dưỡng', 'Đúng định kỳ'),
      (Icons.oil_barrel_outlined, 'Thay dầu', 'Nhanh và rõ giá'),
      (Icons.tire_repair_outlined, 'Lốp & phanh', 'Kiểm tra an toàn'),
    ];
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(width: 12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          width: 172,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.$1, color: AppColors.primary, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$2,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$3,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
        minTileHeight: 76,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        onTap: onTap,
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
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
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}
