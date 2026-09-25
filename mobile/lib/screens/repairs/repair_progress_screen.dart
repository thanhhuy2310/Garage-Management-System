import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/repair_order.dart';

class RepairProgressScreen extends StatefulWidget {
  const RepairProgressScreen({
    super.key,
    required this.controller,
    this.historyOnly = false,
    this.embedded = false,
  });
  final AppController controller;
  final bool historyOnly;
  final bool embedded;

  @override
  State<RepairProgressScreen> createState() => _RepairProgressScreenState();
}

class _RepairProgressScreenState extends State<RepairProgressScreen> {
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
      _error = 'Không thể tải tiến độ sửa chữa.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.controller.repairs
        .where(
          (item) => widget.historyOnly
              ? item.status == RepairStatus.completed
              : item.status != RepairStatus.completed,
        )
        .toList();
    final content = _loading
        ? const LoadingState(label: 'Đang tải tiến độ...')
        : _error != null
        ? ErrorState(message: _error!, onRetry: _load)
        : items.isEmpty
        ? EmptyState(
            icon: widget.historyOnly
                ? Icons.history
                : Icons.car_repair_outlined,
            title: widget.historyOnly
                ? 'Chưa có lịch sử sửa chữa'
                : 'Không có xe đang sửa',
            message: widget.historyOnly
                ? 'Các phiếu sửa chữa hoàn tất sẽ hiển thị tại đây.'
                : 'Khi gara tiếp nhận xe, tiến độ sẽ hiển thị tại đây.',
          )
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (_, index) => _RepairCard(
                order: items[index],
                showTimeline: !widget.historyOnly,
              ),
            ),
          );
    if (widget.embedded) {
      return content;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.historyOnly ? 'Lịch sử sửa chữa' : 'Theo dõi sửa chữa',
        ),
      ),
      body: SafeArea(top: false, child: content),
    );
  }
}

class _RepairCard extends StatelessWidget {
  const _RepairCard({required this.order, required this.showTimeline});
  final RepairOrder order;
  final bool showTimeline;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = repairStatusPresentation(order.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.id,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusBadge(label: label, tone: tone),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${order.vehicle.plate} · ${order.vehicle.brand} ${order.vehicle.model}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 5),
            Text(
              order.description,
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              'Kỹ thuật viên: ${order.technician}',
              style: const TextStyle(fontSize: 13),
            ),
            Text(
              'Cập nhật: ${formatDate(order.updatedAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            if (showTimeline) ...[
              const Divider(height: 28),
              _RepairTimeline(status: order.status),
            ],
          ],
        ),
      ),
    );
  }
}

class _RepairTimeline extends StatelessWidget {
  const _RepairTimeline({required this.status});
  final RepairStatus status;

  @override
  Widget build(BuildContext context) {
    const steps = [
      (RepairStatus.pending, 'Đã tiếp nhận'),
      (RepairStatus.inspecting, 'Đang kiểm tra'),
      (RepairStatus.inProgress, 'Đang sửa chữa'),
      (RepairStatus.waitingParts, 'Chờ phụ tùng'),
      (RepairStatus.completed, 'Hoàn tất'),
    ];
    final current = steps.indexWhere((step) => step.$1 == status);
    return Column(
      children: [
        for (var index = 0; index < steps.length; index++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= current
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    child: index < current
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                  if (index < steps.length - 1)
                    Container(
                      width: 2,
                      height: 28,
                      color: index < current
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  steps[index].$2,
                  style: TextStyle(
                    fontWeight: index == current
                        ? FontWeight.w800
                        : FontWeight.w500,
                    color: index <= current
                        ? AppColors.foreground
                        : AppColors.muted,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

(String, AppStatusTone) repairStatusPresentation(RepairStatus status) =>
    switch (status) {
      RepairStatus.pending => ('Đã tiếp nhận', AppStatusTone.info),
      RepairStatus.inspecting => ('Đang kiểm tra', AppStatusTone.info),
      RepairStatus.inProgress => ('Đang sửa chữa', AppStatusTone.warning),
      RepairStatus.waitingParts => ('Chờ phụ tùng', AppStatusTone.warning),
      RepairStatus.completed => ('Hoàn tất', AppStatusTone.success),
    };
