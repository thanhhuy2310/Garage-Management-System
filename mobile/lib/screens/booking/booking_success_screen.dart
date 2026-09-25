import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/appointment.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Đặt lịch thành công'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Icon(Icons.check_circle, size: 76, color: AppColors.success),
            const SizedBox(height: 16),
            Text(
              'Gara đã ghi nhận lịch hẹn',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Chúng tôi sẽ xác nhận lịch với bạn trong thời gian sớm nhất.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Mã lịch hẹn', value: appointment.id),
                    _SummaryRow(
                      label: 'Xe',
                      value:
                          '${appointment.vehicle.plate} · ${appointment.vehicle.brand} ${appointment.vehicle.model}',
                    ),
                    _SummaryRow(
                      label: 'Dịch vụ',
                      value: appointment.service.name,
                    ),
                    _SummaryRow(
                      label: 'Thời gian',
                      value:
                          '${appointment.time} · ${formatDate(appointment.date)}',
                    ),
                    const Divider(height: 28),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trạng thái',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        StatusBadge(
                          label: 'Chờ xác nhận',
                          tone: AppStatusTone.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Xem lịch hẹn',
              onPressed: () => Navigator.pop(context, true),
              icon: Icons.event_note_outlined,
            ),
            const SizedBox(height: 10),
            PrimaryButton(
              label: 'Về trang chủ',
              outlined: true,
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
