import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_states.dart';
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
  bool _submitting = false;
  bool _loading = false;
  String? _error;
  Quotation? get _item {
    for (final item in widget.controller.quotations) {
      if (item.id == widget.quotationId) return item;
    }
    return null;
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.controller.loadQuotations();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(QuotationStatus status) async {
    final item = _item;
    if (item == null || _saving) return;
    final approve = status == QuotationStatus.confirmed;
    setState(() {
      _saving = true;
      _error = null;
    });
    String note = '';
    try {
      final reason = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(approve ? 'Đồng ý báo giá?' : 'Từ chối báo giá?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'BG${item.id} · Lần ${item.revision}\nTổng tiền: ${formatCurrency(item.total)}',
                ),
                const SizedBox(height: 16),
                TextField(
                  maxLength: 500,
                  maxLines: 3,
                  onChanged: (value) => note = value,
                  decoration: const InputDecoration(
                    labelText: 'Ghi chú (không bắt buộc)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, note),
              child: Text(approve ? 'Đồng ý' : 'Từ chối'),
            ),
          ],
        ),
      );
      if (reason == null) return;
      if (!mounted) return;
      setState(() => _submitting = true);
      await widget.controller.respondToQuotation(
        item.id,
        status,
        version: item.version,
        reason: reason,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Đã đồng ý báo giá.' : 'Đã từ chối báo giá.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error.toString().replaceFirst('Bad state: ', ''),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    if (item == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Báo giá')),
        body: ErrorState(
          message: 'Báo giá không còn trong danh sách hiện hành. Gara có thể đang chuẩn bị lần điều chỉnh.',
          onRetry: _reload,
        ),
      );
    }
    final (label, tone) = switch (item.status) {
      QuotationStatus.draft => ('Bản nháp', AppStatusTone.neutral),
      QuotationStatus.pending => ('Chờ xác nhận', AppStatusTone.warning),
      QuotationStatus.confirmed => ('Đã đồng ý', AppStatusTone.success),
      QuotationStatus.rejected => ('Đã từ chối', AppStatusTone.danger),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text('BG${item.id} · Lần ${item.revision}'),
        actions: [
          IconButton(
            onPressed: _saving || _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại báo giá',
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
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
                                    '${line.kind == 'PART' ? 'Phụ tùng: ' : ''}${line.name}',
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
            if (item.rejectionReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text('Lý do từ chối: ${item.rejectionReason}'),
              ),
          ],
        ),
      ),
      bottomNavigationBar: item.status != QuotationStatus.pending || _loading
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
                        loading: _submitting,
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
