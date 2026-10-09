// TV3-TUAN9
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/history.dart';
import '../../services/history_service.dart';
import 'history_screen.dart' show historyCategoryPresentation;

/// Chi tiết một lượt sửa chữa/bảo dưỡng: tải lại từ API để backend kiểm tra quyền sở hữu.
class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({
    super.key,
    required this.service,
    required this.repairOrderId,
  });

  final HistoryService service;
  final int repairOrderId;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  bool _loading = true;
  String? _error;
  HistoryDetail? _detail;

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
      final detail = await widget.service.getHistoryDetail(
        widget.repairOrderId,
      );
      if (mounted) setState(() => _detail = detail);
    } on HistoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải chi tiết lịch sử.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
    final Widget body;
    if (_loading) {
      body = const LoadingState(label: 'Đang tải chi tiết...');
    } else if (_error != null || detail == null) {
      body = ErrorState(
        message: _error ?? 'Không thể tải chi tiết lịch sử.',
        onRetry: _load,
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: _DetailBody(detail: detail),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text('Phiếu #${widget.repairOrderId}')),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.detail});

  final HistoryDetail detail;

  @override
  Widget build(BuildContext context) {
    final item = detail.item;
    final (label, tone) = historyCategoryPresentation(item.category);
    final titleStyle = Theme.of(context).textTheme.titleMedium;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Phiếu sửa chữa #${item.repairOrderId}',
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
                _InfoRow(label: 'Biển số', value: item.plate),
                if (item.vehicleName.isNotEmpty)
                  _InfoRow(label: 'Xe', value: item.vehicleName),
                _InfoRow(label: 'Ngày lập', value: _date(item.createdAt)),
                _InfoRow(label: 'Ngày bắt đầu', value: _date(item.startedAt)),
                _InfoRow(
                  label: 'Ngày hoàn thành',
                  value: _date(item.completedAt),
                ),
                if (item.result.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Kết quả sửa chữa', style: titleStyle),
                  const SizedBox(height: 4),
                  Text(item.result),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Hạng mục dịch vụ', style: titleStyle),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: detail.services.isEmpty
                ? const Text(
                    'Không có hạng mục dịch vụ.',
                    style: TextStyle(color: AppColors.muted),
                  )
                : Column(
                    children: [
                      for (final line in detail.services)
                        _LineRow(
                          name: line.name,
                          quantity: line.quantity,
                          unitPrice: line.unitPrice,
                          lineTotal: line.lineTotal,
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Text('Phụ tùng đã thay', style: titleStyle),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: detail.parts.isEmpty
                ? const Text(
                    'Không thay phụ tùng.',
                    style: TextStyle(color: AppColors.muted),
                  )
                : Column(
                    children: [
                      for (final line in detail.parts)
                        _LineRow(
                          name: line.name,
                          quantity: line.quantity,
                          unitPrice: line.unitPrice,
                          lineTotal: line.lineTotal,
                        ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _InfoRow(
                  label: 'Tiền dịch vụ',
                  value: formatCurrency(detail.serviceTotal),
                ),
                _InfoRow(
                  label: 'Tiền phụ tùng',
                  value: formatCurrency(detail.partsTotal),
                ),
                const Divider(height: 24),
                _InfoRow(
                  label: 'Tổng chi phí',
                  value: formatCurrency(item.totalCost),
                  emphasize: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _date(DateTime? value) => value == null ? '—' : formatDate(value);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
      fontSize: emphasize ? 16 : 14,
      color: emphasize ? AppColors.primary : AppColors.foreground,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.muted)),
          ),
          const SizedBox(width: 12),
          Flexible(child: Text(value, style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String name;
  final int quantity;
  final int unitPrice;
  final int lineTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(
                  '$quantity × ${formatCurrency(unitPrice)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            formatCurrency(lineTotal),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
