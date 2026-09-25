import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/quotation.dart';
import 'quotation_detail_screen.dart';

class QuotationsScreen extends StatefulWidget {
  const QuotationsScreen({super.key, required this.controller});
  final AppController controller;

  @override
  State<QuotationsScreen> createState() => _QuotationsScreenState();
}

class _QuotationsScreenState extends State<QuotationsScreen> {
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
      _error = 'Không thể tải danh sách báo giá.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Báo giá')),
      body: SafeArea(
        top: false,
        child: _loading
            ? const LoadingState(label: 'Đang tải báo giá...')
            : _error != null
            ? ErrorState(message: _error!, onRetry: _load)
            : widget.controller.quotations.isEmpty
            ? const EmptyState(
                icon: Icons.request_quote_outlined,
                title: 'Chưa có báo giá',
                message: 'Báo giá từ gara sẽ hiển thị tại đây.',
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.controller.quotations.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) {
                    final item = widget.controller.quotations[index];
                    final (label, tone) = _quotationStatus(item.status);
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => QuotationDetailScreen(
                                controller: widget.controller,
                                quotationId: item.id,
                              ),
                            ),
                          );
                          if (mounted) setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.id,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  StatusBadge(label: label, tone: tone),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.service.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${item.vehicle.plate} · ${formatDate(item.createdAt)}',
                                style: const TextStyle(color: AppColors.muted),
                              ),
                              const Divider(height: 26),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Tổng cộng'),
                                  Text(
                                    formatCurrency(item.total),
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

(String, AppStatusTone) _quotationStatus(QuotationStatus status) =>
    switch (status) {
      QuotationStatus.draft => ('Bản nháp', AppStatusTone.neutral),
      QuotationStatus.pending => ('Chờ xác nhận', AppStatusTone.warning),
      QuotationStatus.confirmed => ('Đã đồng ý', AppStatusTone.success),
      QuotationStatus.rejected => ('Đã từ chối', AppStatusTone.danger),
    };
