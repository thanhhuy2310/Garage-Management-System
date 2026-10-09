// TV3-TUAN9
import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/status_badge.dart';
import '../../models/history.dart';
import '../../services/history_service.dart';
import 'history_detail_screen.dart';

(String, AppStatusTone) historyCategoryPresentation(HistoryCategory category) =>
    switch (category) {
      HistoryCategory.maintenance => ('Bảo dưỡng', AppStatusTone.info),
      HistoryCategory.repair => ('Sửa chữa', AppStatusTone.neutral),
      HistoryCategory.mixed => ('Bảo dưỡng & sửa chữa', AppStatusTone.info),
    };

class _VehicleOption {
  const _VehicleOption({required this.id, required this.plate});

  final int id;
  final String plate;
}

/// Lịch sử sửa chữa, bảo dưỡng đã hoàn tất của khách hàng, lấy từ Spring Boot API.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.service});

  final HistoryService service;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loading = true;
  String? _error;
  List<HistoryItem> _items = const [];
  List<_VehicleOption> _vehicles = const [];
  int? _vehicleId;

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
      final items = await widget.service.getHistory(vehicleId: _vehicleId);
      if (!mounted) return;
      setState(() {
        _items = items;
        // Danh sách xe để lọc lấy từ lịch sử chưa lọc của chính khách hàng.
        if (_vehicleId == null) _vehicles = _distinctVehicles(items);
      });
    } on HistoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Không thể tải lịch sử sửa chữa.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<_VehicleOption> _distinctVehicles(List<HistoryItem> items) {
    final seen = <int>{};
    return [
      for (final item in items)
        if (seen.add(item.vehicleId))
          _VehicleOption(id: item.vehicleId, plate: item.plate),
    ];
  }

  void _selectVehicle(int? vehicleId) {
    if (vehicleId == _vehicleId) return;
    setState(() => _vehicleId = vehicleId);
    _load();
  }

  void _open(HistoryItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HistoryDetailScreen(
          service: widget.service,
          repairOrderId: item.repairOrderId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử sửa chữa')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_vehicles.length > 1) _buildVehicleFilter(),
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleFilter() {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('Tất cả xe'),
              selected: _vehicleId == null,
              onSelected: (_) => _selectVehicle(null),
            ),
          ),
          for (final vehicle in _vehicles)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(vehicle.plate),
                selected: _vehicleId == vehicle.id,
                onSelected: (_) => _selectVehicle(vehicle.id),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const LoadingState(label: 'Đang tải lịch sử...');
    if (_error != null) {
      return _refreshable(ErrorState(message: _error!, onRetry: _load));
    }
    if (_items.isEmpty) {
      return _refreshable(
        EmptyState(
          icon: Icons.history,
          title: 'Chưa có lịch sử sửa chữa',
          message: _vehicleId == null
              ? 'Các lượt sửa chữa, bảo dưỡng đã hoàn tất sẽ hiển thị tại đây.'
              : 'Xe này chưa có lượt sửa chữa, bảo dưỡng nào hoàn tất.',
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, index) =>
            _HistoryCard(item: _items[index], onTap: () => _open(_items[index])),
      ),
    );
  }

  /// Cho phép kéo để làm mới ngay cả khi đang hiển thị trạng thái rỗng/lỗi.
  Widget _refreshable(Widget child) {
    return RefreshIndicator(
      onRefresh: _load,
      child: LayoutBuilder(
        builder: (context, constraints) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [SizedBox(height: constraints.maxHeight, child: child)],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.item, required this.onTap});

  final HistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (label, tone) = historyCategoryPresentation(item.category);
    final date = item.date;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Phiếu #${item.repairOrderId}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  StatusBadge(label: label, tone: tone),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.vehicleName.isEmpty
                    ? item.plate
                    : '${item.plate} · ${item.vehicleName}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                item.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      date == null ? '—' : 'Hoàn thành: ${formatDate(date)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                  Text(
                    formatCurrency(item.totalCost),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
