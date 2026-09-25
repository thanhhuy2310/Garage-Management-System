import 'package:flutter/material.dart';

import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/vehicle.dart';

class VehicleFormSheet extends StatefulWidget {
  const VehicleFormSheet({super.key, required this.onSubmit});

  final Future<Vehicle> Function(VehicleInput input) onSubmit;

  @override
  State<VehicleFormSheet> createState() => _VehicleFormSheetState();
}

class _VehicleFormSheetState extends State<VehicleFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _plate = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _mileage = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _plate.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _mileage.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final vehicle = await widget.onSubmit(
        VehicleInput(
          plate: _plate.text,
          brand: _brand.text,
          model: _model.text,
          year: _year.text.isEmpty ? null : int.parse(_year.text),
          mileage: _mileage.text.isEmpty ? null : int.parse(_mileage.text),
        ),
      );
      if (mounted) Navigator.pop(context, vehicle);
    } catch (_) {
      setState(() => _error = 'Không thể thêm xe. Vui lòng thử lại.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Thêm xe mới',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Đóng',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _plate,
                  label: 'Biển số *',
                  hint: '51G-123.45',
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập biển số.'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _brand,
                  label: 'Hãng xe *',
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập hãng xe.'
                      : null,
                ),
                const SizedBox(height: 14),
                AppTextField(
                  controller: _model,
                  label: 'Dòng xe *',
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Vui lòng nhập dòng xe.'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppTextField(
                        controller: _year,
                        label: 'Năm sản xuất',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final year = int.tryParse(value);
                          if (year == null ||
                              year < 1950 ||
                              year > DateTime.now().year + 1) {
                            return 'Năm không hợp lệ.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppTextField(
                        controller: _mileage,
                        label: 'Số km',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final mileage = int.tryParse(value);
                          return mileage == null || mileage < 0
                              ? 'Số km không hợp lệ.'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                PrimaryButton(
                  label: 'Lưu xe',
                  onPressed: _submit,
                  loading: _saving,
                  icon: Icons.add,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<Vehicle?> showVehicleFormSheet(
  BuildContext context, {
  required Future<Vehicle> Function(VehicleInput input) onSubmit,
}) {
  return showModalBottomSheet<Vehicle>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => VehicleFormSheet(onSubmit: onSubmit),
  );
}
