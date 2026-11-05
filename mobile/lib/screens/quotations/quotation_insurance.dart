import 'package:flutter/material.dart';

import '../../services/quotation_coverage_reader.dart';
import '../../core/utils/formatters.dart';

class QuotationInsurance extends StatefulWidget {
  const QuotationInsurance({
    super.key,
    required this.service,
    required this.id,
    required this.total,
  });
  final QuotationCoverageReader service;
  final String id;
  final num total;
  @override
  State<QuotationInsurance> createState() => _QuotationInsuranceState();
}

class _QuotationInsuranceState extends State<QuotationInsurance> {
  late Future<Map<String, dynamic>?> coverage = widget.service.getCoverage(
    widget.id,
  );
  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>?>(
    future: coverage,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return TextButton(
          onPressed: () => setState(() {
            coverage = widget.service.getCoverage(widget.id);
          }),
          child: const Text('Không tải được chi phí bảo hiểm. Thử lại'),
        );
      }
      if (snapshot.connectionState != ConnectionState.done) {
        return const LinearProgressIndicator();
      }
      return Text(coverageSummary(snapshot.data, widget.total));
    },
  );
}

String coverageSummary(Map<String, dynamic>? share, num total) {
  if (share == null) {
    return 'Khách thanh toán tại gara: ${formatCurrency(total)} · Không có hồ sơ bảo hiểm.';
  }
  final gross = formatCurrency(share['total'] ?? total);
  final approved = share['approved'] as num?;
  if (approved == null) {
    return 'Tổng chi phí sửa chữa: $gross\nĐang chờ bảo hiểm duyệt. Phần khách thực trả chưa xác định.';
  }
  return 'Tổng chi phí sửa chữa: $gross\nBảo hiểm chấp thuận: ${formatCurrency(approved)}'
      '\nBảo hiểm trả trực tiếp cho gara: ${formatCurrency(share['garageAmount'] ?? (share['direct'] == true ? approved : 0))}'
      '${share['direct'] == false ? ' (hoàn tiền cho khách)' : ''}'
      '\nKhách thanh toán tại gara: ${formatCurrency(share['customerAmount'])}'
      '${share['remaining'] == null ? '' : '\nCòn phải trả: ${formatCurrency(share['remaining'])}'}';
}
