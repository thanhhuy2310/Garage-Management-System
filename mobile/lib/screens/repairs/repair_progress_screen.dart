import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/repair_order.dart';
import '../../services/repair_service.dart';

class RepairProgressScreen extends StatefulWidget {
  const RepairProgressScreen({
    super.key,
    required this.controller,
    this.historyOnly = false,
    this.embedded = false,
    this.active = true,
  });
  final AppController controller;
  final bool historyOnly;
  final bool embedded;
  final bool active;
  @override
  State<RepairProgressScreen> createState() => _RepairProgressScreenState();
}

class _RepairProgressScreenState extends State<RepairProgressScreen>
    with WidgetsBindingObserver {
  bool _loading = true;
  bool _requesting = false;
  bool _history = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _history = widget.historyOnly;
    WidgetsBinding.instance.addObserver(this);
    if (widget.active) {
      _load();
    } else {
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(covariant RepairProgressScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (widget.active && state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    if (_requesting) return;
    _requesting = true;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.controller.loadRepairs();
    } catch (error) {
      if (mounted) {
        _error = error is RepairApiException
            ? error.message
            : 'Không thể tải tiến độ sửa chữa. Vui lòng thử lại.';
      }
    } finally {
      _requesting = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.controller.repairs.where((item) {
      final ended =
          item.status == RepairStatus.completed ||
          item.status == RepairStatus.cancelled;
      return _history ? ended : !ended;
    }).toList();
    final content = RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (!widget.historyOnly)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Đang sửa chữa'),
                  selected: !_history,
                  onSelected: (_) => setState(() => _history = false),
                ),
                ChoiceChip(
                  label: const Text('Đã kết thúc'),
                  selected: _history,
                  onSelected: (_) => setState(() => _history = true),
                ),
                IconButton(
                  tooltip: 'Làm mới tiến độ',
                  onPressed: _loading ? null : _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          const SizedBox(height: 12),
          if (_loading)
            const LoadingState(label: 'Đang tải tiến độ...')
          else if (_error != null)
            ErrorState(message: _error!, onRetry: _load)
          else if (items.isEmpty)
            EmptyState(
              icon: _history ? Icons.history : Icons.car_repair_outlined,
              title: _history
                  ? 'Chưa có lịch sử sửa chữa'
                  : 'Không có xe đang sửa',
              message: _history ? 'Các phiếu đã kết thúc sẽ hiển thị tại đây.' : 'Khi gara lập phiếu sửa chữa cho xe của bạn, tiến độ sẽ hiển thị tại đây.',
            )
          else
            for (final item in items)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _RepairCard(order: item),
              ),
        ],
      ),
    );
    if (widget.embedded) return content;
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
  const _RepairCard({required this.order});
  final RepairOrder order;
  @override
  Widget build(BuildContext context) {
    final (label, tone) = repairStatusPresentation(order.status);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Phiếu ${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                StatusBadge(label: label, tone: tone),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              order.vehicle.plate,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
            ),
            Text(
              '${order.vehicle.brand} ${order.vehicle.model}'.trim(),
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Text(order.description),
            const SizedBox(height: 12),
            Text('Kỹ thuật viên: ${order.technician}'),
            const SizedBox(height: 4),
            Text(
              'Cập nhật: ${_dateTime(order.updatedAt)}',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            if (order.services.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                '${order.completedServices}/${order.services.length} dịch vụ đã hoàn tất',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: order.completedServices / order.services.length,
                minHeight: 6,
                semanticsLabel: 'Tiến độ dịch vụ',
              ),
              const SizedBox(height: 12),
              for (final line in order.services)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        line.status == 'HOAN_TAT'
                            ? Icons.check_circle_outline
                            : Icons.build_outlined,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${line.name}\n${_statusLabel(line.status)}',
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (order.result?.isNotEmpty == true) ...[
              const Divider(height: 28),
              const Text(
                'Kết quả sửa chữa',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(order.result!),
            ],
            const Divider(height: 28),
            const Text(
              'Lịch sử cập nhật',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (order.progress.isEmpty)
              const Text(
                'Chưa có nhật ký cập nhật cho phiếu này.',
                style: TextStyle(color: AppColors.muted),
              )
            else
              for (final event in order.progress)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.history,
                        size: 20,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _statusLabel(event.status),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              _dateTime(event.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                            if (event.serviceId != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                order.services
                                    .where((line) => line.id == event.serviceId)
                                    .map((line) => line.name)
                                    .join(', '),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(event.notes),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

String _dateTime(DateTime date) =>
    '${formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String _statusLabel(String status) => switch (status) {
  'MOI_TAO' => 'Mới tiếp nhận',
  'CHO_SUA' || 'CHUA_THUC_HIEN' => 'Chờ thực hiện',
  'DANG_KIEM_TRA' => 'Đang kiểm tra',
  'DANG_SUA' => 'Đang thực hiện',
  'CHO_PHU_TUNG' => 'Chờ phụ tùng',
  'HOAN_TAT' => 'Hoàn tất',
  'HUY' || 'DA_HUY' => 'Đã hủy',
  _ => 'Chưa cập nhật',
};
(String, AppStatusTone) repairStatusPresentation(RepairStatus status) =>
    switch (status) {
      RepairStatus.pending => ('Chờ sửa chữa', AppStatusTone.info),
      RepairStatus.inspecting => ('Đang kiểm tra', AppStatusTone.info),
      RepairStatus.inProgress => ('Đang sửa chữa', AppStatusTone.warning),
      RepairStatus.waitingParts => ('Chờ phụ tùng', AppStatusTone.warning),
      RepairStatus.completed => ('Hoàn tất', AppStatusTone.success),
      RepairStatus.cancelled => ('Đã hủy', AppStatusTone.neutral),
      RepairStatus.unknown => ('Chưa cập nhật', AppStatusTone.neutral),
    };
