import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

enum AppStatusTone { neutral, info, warning, success, danger }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
  });

  final String label;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final (background, foreground, icon) = switch (tone) {
      AppStatusTone.info => (
        AppColors.infoSoft,
        AppColors.info,
        Icons.info_outline,
      ),
      AppStatusTone.warning => (
        AppColors.warningSoft,
        AppColors.warning,
        Icons.schedule,
      ),
      AppStatusTone.success => (
        AppColors.successSoft,
        AppColors.success,
        Icons.check_circle_outline,
      ),
      AppStatusTone.danger => (
        AppColors.dangerSoft,
        AppColors.danger,
        Icons.cancel_outlined,
      ),
      AppStatusTone.neutral => (
        AppColors.primarySoft,
        AppColors.primary,
        Icons.circle_outlined,
      ),
    };
    return Semantics(
      label: 'Trạng thái: $label',
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
