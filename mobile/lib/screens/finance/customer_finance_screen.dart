import 'package:flutter/material.dart';

import '../../app/app_routes.dart';
import '../../core/utils/formatters.dart';
import '../../services/customer_api.dart';

class CustomerFinanceScreen extends StatefulWidget {
  const CustomerFinanceScreen({
    super.key,
    required this.api,
    this.statistics = false,
  });
  final CustomerApi api;
  final bool statistics;
  @override
  State<CustomerFinanceScreen> createState() => _CustomerFinanceScreenState();
}

class _CustomerFinanceScreenState extends State<CustomerFinanceScreen> {
  final _year = TextEditingController();
  List<dynamic> _vehicles = [];
  int? _vehicle;
  dynamic _data;
  String? _error;
  bool _loading = true;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _year.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final year = int.tryParse(_year.text.trim());
    if (widget.statistics &&
        _year.text.trim().isNotEmpty &&
        (year == null || year < 1900 || year > 9999)) {
      setState(() => _error = 'Nhập năm từ 1900 đến 9999 hoặc để trống.');
      return;
    }
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final params = <String, String>{
        if (_vehicle != null) 'vehicleId': '$_vehicle',
        if (year != null) 'year': '$year',
      };
      final path = widget.statistics
          ? '/customers/me/statistics'
          : '/customers/me/invoices';
      final data = await widget.api.request(
        '$path${params.isEmpty ? '' : '?${Uri(queryParameters: params).query}'}',
      );
      if (!mounted || request != _request) return;
      setState(() {
        _data = data;
        if (widget.statistics && _vehicle == null) {
          _vehicles = data['vehicles'] as List<dynamic>;
        }
      });
    } on SessionExpired {
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted && request == _request) setState(() => _error = e.toString());
    } finally {
      if (mounted && request == _request) setState(() => _loading = false);
    }
  }

  String _money(dynamic value) =>
      value == null ? 'Chờ đối chiếu' : formatCurrency(value);
  String _date(dynamic value) =>
      value == null ? 'Chưa có' : formatDate(DateTime.parse(value as String));
  Widget _card(List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    ),
  );

  Widget _invoice(Map<String, dynamic> h) {
    const statuses = {
      'CHO_DOI_CHIEU': 'Chờ đối chiếu bảo hiểm',
      'DA_THANH_TOAN': 'Đã thanh toán',
      'THANH_TOAN_MOT_PHAN': 'Thanh toán một phần',
      'CHUA_THANH_TOAN': 'Chưa thanh toán',
    };
    return _card([
      Text(
        'HĐ${h['id']} · ${h['licensePlate']}',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      Text(
        '${_date(h['createdAt'])} · ${statuses[h['status']] ?? h['status']}',
      ),
      Text('Tổng hóa đơn: ${_money(h['total'])}'),
      Text('Bảo hiểm hỗ trợ theo duyệt: ${_money(h['insuranceSupport'])}'),
      Text('Khách thanh toán gara: ${_money(h['customerDue'])}'),
      Text('Khách đã trả: ${_money(h['customerPaid'])}'),
      Text('Còn lại: ${_money(h['remaining'])}'),
      if ((h['insuranceSupport'] as num) > 0 && h['customerDue'] == h['total'])
        const Text(
          'Bảo hiểm hoàn tiền trực tiếp cho khách; khách vẫn thanh toán đầy đủ cho gara.',
        ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Chi tiết hóa đơn'),
        children: [
          for (final line in h['lines'] as List<dynamic>)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(line['name'] as String),
              subtitle: Text(
                '${line['type'] == 'PHU_TUNG' ? 'Phụ tùng' : 'Dịch vụ'} · ${line['quantity']} × ${_money(line['unitPrice'])}',
              ),
              trailing: Text(
                _money((line['quantity'] as num) * (line['unitPrice'] as num)),
              ),
            ),
          if ((h['payments'] as List).isEmpty)
            const Text('Chưa ghi nhận thanh toán.'),
          for (final payment in h['payments'] as List<dynamic>)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${payment['payer'] == 'INSURER' ? 'Bảo hiểm' : 'Khách hàng'} · ${_money(payment['amount'])}',
              ),
              subtitle: Text(
                '${_date(payment['paidAt'])} · ${payment['method'] == 'TIEN_MAT' ? 'Tiền mặt' : 'Chuyển khoản'}',
              ),
            ),
        ],
      ),
    ]);
  }

  List<Widget> _statistics(Map<String, dynamic> data) => [
    _card([
      Text('Tổng số xe: ${data['vehicleCount']}'),
      Text('Lượt hoàn thành: ${data['completedVisits']}'),
      Text(
        'Sửa chữa: ${data['repairVisits']} · Bảo dưỡng: ${data['maintenanceVisits']}',
      ),
      Text('Tổng chi phí: ${_money(data['totalCost'])}'),
      Text('Khách chịu sau bảo hiểm đã chốt: ${_money(data['customerCost'])}'),
      const Text(
        'Lượt có cả sửa chữa và bảo dưỡng tính ở cả hai loại, nhưng chỉ tính một lần trong tổng lượt và chi phí.',
      ),
      if ((data['awaitingInvoicesOrInsurance'] as num) > 0)
        Text(
          '${data['awaitingInvoicesOrInsurance']} lượt chưa lập hóa đơn hoặc chưa chốt bảo hiểm; chưa cộng phần khách chịu của các lượt này.',
        ),
      if (data['completedVisits'] == 0)
        const Text('Chưa có lượt hoàn thành trong phạm vi đã chọn.'),
    ]),
    for (final v in data['vehicles'] as List<dynamic>)
      _card([
        Text(
          v['vehicle']['licensePlate'] as String,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        Text(
          '${v['completedVisits']} lượt · ${v['repairVisits']} sửa chữa · ${v['maintenanceVisits']} bảo dưỡng',
        ),
        Text('Chi phí: ${_money(v['totalCost'])}'),
        Text('Khách chịu đã chốt: ${_money(v['customerCost'])}'),
        Text('Lần gần nhất: ${_date(v['lastRepair'])}'),
      ]),
    _card([
      Text(
        'Chi phí theo tháng',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      for (final m in data['months'] as List<dynamic>)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Tháng ${m['month']}/${m['year']}: ${m['completedVisits']} lượt\nTổng: ${_money(m['totalCost'])} · Khách chịu: ${_money(m['customerCost'])}',
          ),
        ),
    ]),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.statistics ? 'Thống kê xe của tôi' : 'Hóa đơn của tôi',
      ),
      actions: [
        IconButton(
          tooltip: 'Làm mới',
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.statistics) ...[
            DropdownButtonFormField<int>(
              initialValue: _vehicle,
              decoration: const InputDecoration(labelText: 'Xe'),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('Tất cả xe'),
                ),
                for (final v in _vehicles)
                  DropdownMenuItem<int>(
                    value: v['vehicle']['id'] as int,
                    child: Text(v['vehicle']['licensePlate'] as String),
                  ),
              ],
              onChanged: _loading
                  ? null
                  : (value) {
                      setState(() => _vehicle = value);
                      _load();
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _year,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Năm (bỏ trống để xem tất cả)',
              ),
              onSubmitted: (_) => _load(),
            ),
            TextButton(
              onPressed: _loading ? null : _load,
              child: const Text('Xem thống kê'),
            ),
          ] else
            const Text(
              'Thanh toán theo hướng dẫn của gara. Số tiền đã thu được cập nhật sau khi nhân viên xác nhận.',
            ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (_error != null)
            _card([
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Thử lại')),
            ]),
          if (!_loading && _error == null && _data != null)
            if (widget.statistics)
              ..._statistics(_data as Map<String, dynamic>)
            else if ((_data as List).isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('Bạn chưa có hóa đơn.'),
              )
            else
              for (final h in _data as List<dynamic>)
                _invoice(h as Map<String, dynamic>),
        ],
      ),
    ),
  );
}
