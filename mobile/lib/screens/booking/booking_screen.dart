import 'package:flutter/material.dart';

import '../../app/app_controller.dart';
import '../../app/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/feedback_states.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/service_card.dart';
import '../../core/widgets/vehicle_card.dart';
import '../../models/appointment.dart';
import '../../models/vehicle.dart';
import '../vehicles/vehicle_form_sheet.dart';
import 'booking_calendar.dart';
import 'booking_success_screen.dart';
import 'time_slot_picker.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _note = TextEditingController();
  final _pageController = PageController();
  int _step = 0;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Vehicle? _vehicle;
  GarageServiceItem? _service;
  DateTime? _date;
  String? _time;
  late DateTime _visibleMonth;
  List<String> _availableSlots = const [];
  Set<DateTime> _fullyBookedDates = const {};

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _maxDate => _today.add(const Duration(days: 90));

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(_today.year, _today.month);
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.controller.loadBookingData();
      await _loadMonthAvailability(_visibleMonth);
    } catch (_) {
      _error = 'Không thể tải dữ liệu đặt lịch. Vui lòng thử lại.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMonthAvailability(DateTime month) async {
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final results = await Future.wait([
      for (var day = 1; day <= days; day++)
        widget.controller.appointmentService.getAvailability(
          DateTime(month.year, month.month, day),
        ),
    ]);
    if (!mounted) return;
    setState(() {
      _fullyBookedDates = {
        for (var day = 1; day <= days; day++)
          if (results[day - 1].fullyBooked)
            DateTime(month.year, month.month, day),
      };
    });
  }

  Future<void> _changeMonth(DateTime month) async {
    setState(() {
      _visibleMonth = month;
      _fullyBookedDates = const {};
    });
    await _loadMonthAvailability(month);
  }

  Future<void> _selectDate(DateTime date) async {
    final availability = await widget.controller.appointmentService
        .getAvailability(date);
    if (!mounted) return;
    setState(() {
      _date = date;
      _time = null;
      _availableSlots = availability.availableSlots;
    });
  }

  Future<void> _addVehicle() async {
    final vehicle = await showVehicleFormSheet(
      context,
      onSubmit: widget.controller.addVehicle,
    );
    if (vehicle != null && mounted) setState(() => _vehicle = vehicle);
  }

  bool get _canContinue => switch (_step) {
    0 => _vehicle != null,
    1 => _service != null,
    2 => _date != null && _time != null,
    _ => true,
  };

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _continue() async {
    if (!_canContinue) return;
    if (_step < 3) {
      _goTo(_step + 1);
      return;
    }
    await _submit();
  }

  Future<void> _submit() async {
    if (_time == '09:30') {
      final alternatives = _availableSlots
          .where((slot) => slot != _time)
          .take(3)
          .toList();
      final replacement = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Khung giờ vừa hết chỗ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Khung giờ 09:30 hiện không còn trống. Bạn có thể chọn:',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final slot in alternatives)
                    ActionChip(
                      label: Text(slot),
                      onPressed: () => Navigator.pop(context, slot),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Chọn lại'),
            ),
          ],
        ),
      );
      if (replacement == null) {
        _goTo(2);
        return;
      }
      setState(() => _time = replacement);
    }
    final session = widget.controller.session;
    if (session == null) return;
    setState(() => _saving = true);
    try {
      final appointment = await widget.controller.createAppointment(
        AppointmentInput(
          customerId: session.customerId,
          vehicle: _vehicle!,
          service: _service!,
          date: _date!,
          time: _time!,
          note: _note.text.trim(),
        ),
      );
      if (!mounted) return;
      await Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(
          builder: (_) => BookingSuccessScreen(appointment: appointment),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể tạo lịch hẹn. Vui lòng thử lại.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đặt lịch mới')),
      body: SafeArea(
        top: false,
        child: _loading
            ? const LoadingState(label: 'Đang chuẩn bị lịch...')
            : _error != null
            ? ErrorState(message: _error!, onRetry: _load)
            : Column(
                children: [
                  _StepHeader(current: _step),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _vehicleStep(),
                        _serviceStep(),
                        _dateTimeStep(),
                        _confirmStep(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: _loading || _error != null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    if (_step > 0) ...[
                      Expanded(
                        child: PrimaryButton(
                          label: 'Quay lại',
                          outlined: true,
                          onPressed: () => _goTo(_step - 1),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    Expanded(
                      flex: _step > 0 ? 1 : 2,
                      child: PrimaryButton(
                        label: _step == 3 ? 'Xác nhận đặt lịch' : 'Tiếp tục',
                        onPressed: _canContinue ? _continue : null,
                        loading: _saving,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _vehicleStep() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Chọn xe cần sử dụng dịch vụ',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'Thông tin xe giúp gara chuẩn bị đúng phụ tùng và quy trình.',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 20),
      if (widget.controller.vehicles.isEmpty)
        EmptyState(
          icon: Icons.directions_car_outlined,
          title: 'Bạn chưa có xe',
          message: 'Hãy thêm xe trước khi đặt lịch.',
          action: FilledButton.icon(
            onPressed: _addVehicle,
            icon: const Icon(Icons.add),
            label: const Text('Thêm xe'),
          ),
        )
      else ...[
        for (final vehicle in widget.controller.vehicles) ...[
          VehicleCard(
            vehicle: vehicle,
            selected: _vehicle?.id == vehicle.id,
            onTap: () => setState(() => _vehicle = vehicle),
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          onPressed: _addVehicle,
          icon: const Icon(Icons.add),
          label: const Text('Thêm xe khác'),
        ),
      ],
    ],
  );

  Widget _serviceStep() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Chọn dịch vụ',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      const Text(
        'Giá hiển thị là mức tham khảo và sẽ được gara xác nhận sau kiểm tra.',
        style: TextStyle(color: AppColors.muted),
      ),
      const SizedBox(height: 20),
      for (final service in widget.controller.services) ...[
        ServiceCard(
          service: service,
          selected: _service?.id == service.id,
          onTap: () => setState(() => _service = service),
        ),
        const SizedBox(height: 10),
      ],
    ],
  );

  Widget _dateTimeStep() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Chọn ngày và giờ',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 14),
      BookingCalendar(
        visibleMonth: _visibleMonth,
        maxDate: _maxDate,
        selectedDate: _date,
        fullyBookedDates: _fullyBookedDates,
        onMonthChanged: _changeMonth,
        onDateSelected: _selectDate,
      ),
      if (_date != null) ...[
        const SizedBox(height: 22),
        Text(
          'Khung giờ còn trống',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          formatDate(_date!),
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        TimeSlotPicker(
          availableSlots: _availableSlots,
          selectedSlot: _time,
          onSelected: (value) => setState(() => _time = value),
        ),
      ],
    ],
  );

  Widget _confirmStep() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      Text(
        'Xác nhận thông tin',
        style: Theme.of(context).textTheme.titleLarge
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 18),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              _ConfirmRow(
                icon: Icons.directions_car_outlined,
                label: 'Xe',
                value:
                    '${_vehicle!.plate} · ${_vehicle!.brand} ${_vehicle!.model}',
              ),
              const Divider(height: 26),
              _ConfirmRow(
                icon: Icons.build_outlined,
                label: 'Dịch vụ',
                value: _service!.name,
              ),
              const Divider(height: 26),
              _ConfirmRow(
                icon: Icons.calendar_month_outlined,
                label: 'Thời gian',
                value: '$_time · ${formatDate(_date!)}',
              ),
              const Divider(height: 26),
              _ConfirmRow(
                icon: Icons.payments_outlined,
                label: 'Giá tham khảo',
                value: formatCurrency(_service!.price),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 18),
      TextField(
        controller: _note,
        maxLines: 4,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Ghi chú cho gara (không bắt buộc)',
          hintText: 'Mô tả tình trạng xe hoặc yêu cầu của bạn',
        ),
      ),
    ],
  );
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.current});
  final int current;

  @override
  Widget build(BuildContext context) {
    const labels = ['Xe', 'Dịch vụ', 'Ngày giờ', 'Xác nhận'];
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Row(
        children: [
          for (var index = 0; index < labels.length; index++) ...[
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= current
                          ? AppColors.primary
                          : AppColors.border,
                    ),
                    child: Center(
                      child: index < current
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                color: index <= current
                                    ? Colors.white
                                    : AppColors.muted,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: index == current
                          ? AppColors.primary
                          : AppColors.muted,
                      fontWeight: index == current
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (index < labels.length - 1)
              Container(
                width: 10,
                height: 2,
                color: index < current ? AppColors.primary : AppColors.border,
              ),
          ],
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, color: AppColors.primary),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 3),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ],
  );
}
