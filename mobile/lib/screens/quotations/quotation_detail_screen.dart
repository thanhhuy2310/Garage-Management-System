import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_dialog.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/quotation.dart';

class QuotationDetailScreen extends StatefulWidget {
  const QuotationDetailScreen({
    super.key,
    required this.controller,
    required this.quotationId,
  });
  final AppController controller;
  final String quotationId;

  @override
  State<QuotationDetailScreen> createState() => _QuotationDetailScreenState();
}

class _QuotationDetailScreenState extends State<QuotationDetailScreen> {
  bool _saving = false;
  Quotation get _item => widget.controller.quotations.firstWhere(
    (item) => item.id == widget.quotationId,
  );

  Future<void> _respond(QuotationStatus status) async {
    final approve = status == QuotationStatus.confirmed;
    final accepted = await showAppConfirmationDialog(
      context: context,
      title: approve ? 'Đồng ý báo giá?' : 'Từ chối báo giá?',
      message: approve
          ? 'Bạn xác nhận đồng ý báo giá ${formatCurrency(_item.total)} để gara tiếp tục sửa chữa.'
          : 'Gara sẽ nhận được phản hồi từ chối báo giá này.',
      confirmLabel: approve ? 'Đồng ý' : 'Từ chối',
      destructive: !approve,
    );
    if (!accepted) return;
    setState(() => _saving = true);
    await widget.controller.respondToQuotation(_item.id, status);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(approve ? 'Đã đồng ý báo giá.' : 'Đã từ chối báo giá.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    final (label, tone) = switch (item.status) {
      QuotationStatus.draft => ('Bản nháp', AppStatusTone.neutral),
      QuotationStatus.pending => ('Chờ xác nhận', AppStatusTone.warning),
      QuotationStatus.confirmed => ('Đã đồng ý', AppStatusTone.success),
      QuotationStatus.rejected => ('Đã từ chối', AppStatusTone.danger),
    };
    return Scaffold(
      appBar: AppBar(title: Text(item.id)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Chi tiết báo giá',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                StatusBadge(label: label, tone: tone),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.service.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${item.vehicle.plate} · ${item.vehicle.brand} ${item.vehicle.model}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    const Divider(height: 28),
                    for (final line in item.lines)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${line.quantity} × ${formatCurrency(line.unitPrice)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatCurrency(line.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng cộng',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          formatCurrency(item.total),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: item.status != QuotationStatus.pending
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: PrimaryButton(
                        label: 'Từ chối',
                        destructive: true,
                        outlined: true,
                        onPressed: _saving
                            ? null
                            : () => _respond(QuotationStatus.rejected),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: PrimaryButton(
                        label: 'Đồng ý',
                        loading: _saving,
                        onPressed: () => _respond(QuotationStatus.confirmed),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
