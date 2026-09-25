import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_theme.dart';
import '../../core/widgets/feedback_states.dart';
import '../../models/customer_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.controller,
    this.embedded = false,
  });
  final AppController controller;
  final bool embedded;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.controller.loadCustomerExperience();
    } catch (_) {
      _error = 'Không thể tải thông báo.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = widget.controller.notifications
        .where((item) => !item.isRead)
        .length;
    final content = _loading
        ? const LoadingState(label: 'Đang tải thông báo...')
        : _error != null
        ? ErrorState(message: _error!, onRetry: _load)
        : widget.controller.notifications.isEmpty
        ? const EmptyState(
            icon: Icons.notifications_none,
            title: 'Chưa có thông báo',
            message: 'Cập nhật từ gara sẽ hiển thị tại đây.',
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (unread > 0) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$unread thông báo chưa đọc',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: widget.controller.markAllNotificationsRead,
                        child: const Text('Đánh dấu đã đọc'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                for (final item in widget.controller.notifications) ...[
                  _NotificationTile(
                    item: item,
                    onTap: () =>
                        widget.controller.markNotificationRead(item.id),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          );
    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppBar(title: const Text('Thông báo')),
      body: SafeArea(top: false, child: content),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});
  final CustomerNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      CustomerNotificationType.appointment => Icons.calendar_month_outlined,
      CustomerNotificationType.repair => Icons.car_repair_outlined,
      CustomerNotificationType.parts => Icons.inventory_2_outlined,
      CustomerNotificationType.payment => Icons.receipt_long_outlined,
    };
    return Card(
      color: item.isRead ? AppColors.surface : AppColors.primarySoft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: item.isRead ? AppColors.background : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: item.isRead
                            ? FontWeight.w600
                            : FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _relativeTime(item.createdAt),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                const Padding(
                  padding: EdgeInsets.only(top: 5),
                  child: Icon(Icons.circle, size: 9, color: AppColors.accent),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _relativeTime(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.inMinutes < 60) return '${difference.inMinutes} phút trước';
  if (difference.inHours < 24) return '${difference.inHours} giờ trước';
  return '${difference.inDays} ngày trước';
}
