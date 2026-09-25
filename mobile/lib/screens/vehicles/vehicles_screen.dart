import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/vehicle_card.dart';
import 'vehicle_form_sheet.dart';

class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
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
      await widget.controller.loadBookingData();
    } catch (_) {
      _error = 'Không thể tải danh sách xe. Vui lòng thử lại.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addVehicle() async {
    final vehicle = await showVehicleFormSheet(
      context,
      onSubmit: widget.controller.addVehicle,
    );
    if (vehicle != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã thêm xe.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xe của tôi')),
      body: SafeArea(
        top: false,
        child: _loading
            ? const LoadingState(label: 'Đang tải danh sách xe...')
            : _error != null
            ? ErrorState(message: _error!, onRetry: _load)
            : widget.controller.vehicles.isEmpty
            ? EmptyState(
                icon: Icons.directions_car_outlined,
                title: 'Bạn chưa có xe nào',
                message: 'Thêm xe để bắt đầu đặt lịch sửa chữa.',
                action: FilledButton.icon(
                  onPressed: _addVehicle,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm xe'),
                ),
              )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: widget.controller.vehicles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) =>
                      VehicleCard(vehicle: widget.controller.vehicles[index]),
                ),
              ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: PrimaryButton(
            label: 'Thêm xe',
            onPressed: _addVehicle,
            icon: Icons.add,
          ),
        ),
      ),
    );
  }
}
