import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_routes.dart';
import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/appointment.dart';

enum _AppointmentFilter { upcoming, completed, cancelled }

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({
    super.key,
    required this.controller,
    this.embedded = false,
  });

  final AppController controller;
  final bool embedded;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  _AppointmentFilter _filter = _AppointmentFilter.upcoming;
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
      await widget.controller.loadBookingData();
    } catch (_) {
      _error = 'Không thể tải lịch hẹn.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Appointment> get _items => widget.controller.appointments
      .where(
        (item) => switch (_filter) {
          _AppointmentFilter.upcoming =>
            item.status != AppointmentStatus.completed &&
                item.status != AppointmentStatus.cancelled,
          _AppointmentFilter.completed =>
            item.status == AppointmentStatus.completed,
          _AppointmentFilter.cancelled =>
            item.status == AppointmentStatus.cancelled,
        },
      )
      .toList();

  Future<void> _book() async {
    await Navigator.pushNamed(context, AppRoutes.booking);
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const LoadingState(label: 'Đang tải lịch hẹn...')
        : _error != null
        ? ErrorState(message: _error!, onRetry: _load)
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
              children: [
                if (widget.embedded) ...[
                  FilledButton.icon(
                    onPressed: _book,
                    icon: const Icon(Icons.add),
                    label: const Text('Đặt lịch mới'),
                  ),
                  const SizedBox(height: 16),
                ],
                SegmentedButton<_AppointmentFilter>(
                  segments: const [
                    ButtonSegment(
                      value: _AppointmentFilter.upcoming,
                      label: Text('Sắp tới'),
                    ),
                    ButtonSegment(
                      value: _AppointmentFilter.completed,
                      label: Text('Hoàn tất'),
                    ),
                    ButtonSegment(
                      value: _AppointmentFilter.cancelled,
                      label: Text('Đã hủy'),
                    ),
                  ],
                  selected: {_filter},
                  onSelectionChanged: (values) =>
                      setState(() => _filter = values.first),
                ),
                const SizedBox(height: 18),
                if (_items.isEmpty)
                  const EmptyState(
                    icon: Icons.event_busy_outlined,
                    title: 'Chưa có lịch hẹn',
                    message: 'Các lịch hẹn phù hợp sẽ hiển thị tại đây.',
                  )
                else
                  for (final item in _items) ...[
                    _AppointmentCard(appointment: item),
                    const SizedBox(height: 12),
                  ],
              ],
            ),
          );
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(title: const Text('Lịch hẹn')),
      body: SafeArea(top: false, child: content),
      floatingActionButton: widget.embedded
          ? null
          : FloatingActionButton.extended(
              onPressed: _book,
              icon: const Icon(Icons.add),
              label: const Text('Đặt lịch mới'),
            ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  const _AppointmentCard({required this.appointment});
  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = switch (appointment.status) {
      AppointmentStatus.pending => ('Chờ xác nhận', AppStatusTone.warning),
      AppointmentStatus.confirmed => ('Đã xác nhận', AppStatusTone.info),
      AppointmentStatus.arrived => ('Đã tiếp nhận', AppStatusTone.info),
      AppointmentStatus.cancelled => ('Đã hủy', AppStatusTone.danger),
      AppointmentStatus.completed => ('Hoàn tất', AppStatusTone.success),
    };
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
                    appointment.service.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                StatusBadge(label: label, tone: tone),
              ],
            ),
            const SizedBox(height: 14),
            _Info(
              icon: Icons.calendar_month_outlined,
              text: '${appointment.time} · ${formatDate(appointment.date)}',
            ),
            const SizedBox(height: 8),
            _Info(
              icon: Icons.directions_car_outlined,
              text:
                  '${appointment.vehicle.plate} · ${appointment.vehicle.brand} ${appointment.vehicle.model}',
            ),
            const SizedBox(height: 10),
            Text(
              'Mã lịch: ${appointment.id}',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 19, color: AppColors.primary),
      const SizedBox(width: 9),
      Expanded(child: Text(text)),
    ],
  );
}
