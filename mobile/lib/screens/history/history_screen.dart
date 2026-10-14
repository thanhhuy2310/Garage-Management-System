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

/// Lịch sử sửa chữa, bảo dưỡng đã hoàn tất của khách hàng, lấy từ Spring Boot API theo từng trang.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.service});

  final HistoryService service;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const _pageSize = 10;

  // Mỗi lần tải lại (đổi bộ lọc, làm mới) tăng số này; phản hồi của yêu cầu cũ bị bỏ qua.
  int _requestId = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  String? _moreError;
  List<HistoryItem> _items = const [];
  List<HistoryVehicle> _vehicles = const [];
  int? _vehicleId;
  int _nextPage = 0;
  int _total = 0;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _reload();
    _loadVehicles();
  }

  /// Danh sách xe để lọc lấy riêng từ toàn bộ lịch sử của khách hàng, không phải từ trang đầu.
  Future<void> _loadVehicles() async {
    try {
      final vehicles = await widget.service.getHistoryVehicles();
      if (mounted) setState(() => _vehicles = vehicles);
    } on HistoryException catch (_) {
      // Bộ lọc xe không bắt buộc: lịch sử vẫn hiển thị khi chưa tải được danh sách xe.
    } catch (_) {
      // Như trên.
    }
  }

  Future<void> _reload({bool showLoading = true}) async {
    final requestId = ++_requestId;
    setState(() {
      _loadingMore = false;
      _moreError = null;
      if (showLoading) {
        _loading = true;
        _error = null;
      }
    });
    try {
      final page = await widget.service.getHistory(
        vehicleId: _vehicleId,
        page: 0,
        size: _pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _items = page.items;
        _nextPage = 1;
        _total = page.totalElements;
        _hasMore = page.hasMore;
        _loading = false;
        _error = null;
      });
    } on HistoryException catch (error) {
      _fail(requestId, error.message);
    } catch (_) {
      _fail(requestId, 'Không thể tải lịch sử sửa chữa.');
    }
  }

  void _fail(int requestId, String message) {
    if (!mounted || requestId != _requestId) return;
    setState(() {
      _loading = false;
      if (_items.isEmpty) _error = message;
    });
    if (_items.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _loadMore() async {
    if (_loading || _loadingMore || !_hasMore) return;
    final requestId = _requestId;
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    try {
      final page = await widget.service.getHistory(
        vehicleId: _vehicleId,
        page: _nextPage,
        size: _pageSize,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        // Loại trùng phòng khi dữ liệu mới phát sinh làm lệch ranh giới giữa các trang.
        final known = _items.map((item) => item.repairOrderId).toSet();
        _items = [
          ..._items,
          ...page.items.where((item) => !known.contains(item.repairOrderId)),
        ];
        _nextPage += 1;
        _total = page.totalElements;
        _hasMore = page.hasMore;
        _loadingMore = false;
      });
    } on HistoryException catch (error) {
      _failMore(requestId, error.message);
    } catch (_) {
      _failMore(requestId, 'Không thể tải thêm lịch sử.');
    }
  }

  void _failMore(int requestId, String message) {
    if (!mounted || requestId != _requestId) return;
    setState(() {
      _loadingMore = false;
      _moreError = message;
    });
  }

  void _selectVehicle(int? vehicleId) {
    if (vehicleId == _vehicleId) return;
    setState(() {
      _vehicleId = vehicleId;
      _items = const [];
      _hasMore = false;
      _total = 0;
    });
    _reload();
  }

  Future<void> _refresh() async {
    _loadVehicles();
    await _reload(showLoading: false);
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
      return _refreshable(ErrorState(message: _error!, onRetry: _reload));
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
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        // 0: dòng tổng số; 1..n: các lượt; cuối: nút/trạng thái tải thêm.
        itemCount: _items.length + 2,
        itemBuilder: (_, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Hiển thị ${_items.length}/$_total lượt',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            );
          }
          if (index == _items.length + 1) return _buildFooter();
          final item = _items[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HistoryCard(item: item, onTap: () => _open(item)),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    if (_loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_moreError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              _moreError!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
            TextButton(onPressed: _loadMore, child: const Text('Thử lại')),
          ],
        ),
      );
    }
    if (_hasMore) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: OutlinedButton(
          onPressed: _loadMore,
          child: const Text('Tải thêm'),
        ),
      );
    }
    return const SizedBox(height: 8);
  }

  /// Cho phép kéo để làm mới ngay cả khi đang hiển thị trạng thái rỗng/lỗi.
  Widget _refreshable(Widget child) {
    return RefreshIndicator(
      onRefresh: _refresh,
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
