import 'package:flutter/material.dart';

import '../../services/quotation_coverage_reader.dart';
import '../../core/utils/formatters.dart';

class QuotationInsurance extends StatefulWidget {
  const QuotationInsurance({
    super.key,
    required this.service,
    required this.id,
  });
  final QuotationCoverageReader service;
  final String id;
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
      final share = snapshot.data;
      if (share == null) return const SizedBox.shrink();
      final approved = share['approved'] as num?;
      return ListTile(
        title: const Text('Bảo hiểm vật chất xe'),
        subtitle: Text(
          approved == null
              ? 'Đang chờ kết quả chi trả.'
              : 'Bảo hiểm chấp thuận ${formatCurrency(approved)} · ${share['direct'] == true ? 'trả cho gara' : 'hoàn trả cho khách'}\n'
                    '${share['settled'] == true ? 'Phần khách theo hóa đơn' : 'Phần khách dự kiến trả gara'}: ${formatCurrency(share['customerAmount'] as num)}'
                    '${share['remaining'] == null ? '' : '\nCòn phải trả: ${formatCurrency(share['remaining'] as num)}'}',
        ),
      );
    },
  );
}
