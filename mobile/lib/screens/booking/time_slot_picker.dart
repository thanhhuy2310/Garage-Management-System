import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../services/appointment_service.dart';

class TimeSlotPicker extends StatelessWidget {
  const TimeSlotPicker({
    super.key,
    required this.availableSlots,
    required this.selectedSlot,
    required this.onSelected,
  });

  final List<String> availableSlots;
  final String? selectedSlot;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final morning = MockAppointmentService.allSlots
        .where((slot) => int.parse(slot.substring(0, 2)) < 12)
        .toList();
    final afternoon = MockAppointmentService.allSlots
        .where((slot) => int.parse(slot.substring(0, 2)) >= 12)
        .toList();
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Column(
        key: ValueKey(availableSlots.join(',')),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SlotGroup(
            title: 'Buổi sáng',
            slots: morning,
            availableSlots: availableSlots,
            selectedSlot: selectedSlot,
            onSelected: onSelected,
          ),
          const SizedBox(height: 20),
          _SlotGroup(
            title: 'Buổi chiều',
            slots: afternoon,
            availableSlots: availableSlots,
            selectedSlot: selectedSlot,
            onSelected: onSelected,
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 17, color: AppColors.muted),
              SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Khung giờ mờ hiện không còn chỗ.',
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SlotGroup extends StatelessWidget {
  const _SlotGroup({
    required this.title,
    required this.slots,
    required this.availableSlots,
    required this.selectedSlot,
    required this.onSelected,
  });

  final String title;
  final List<String> slots;
  final List<String> availableSlots;
  final String? selectedSlot;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.muted,
            letterSpacing: .5,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) {
            final available = availableSlots.contains(slot);
            final selected = selectedSlot == slot;
            return Semantics(
              label: '$slot, ${available ? 'còn trống' : 'hết chỗ'}',
              selected: selected,
              enabled: available,
              child: ChoiceChip(
                label: Text(slot),
                selected: selected,
                onSelected: available ? (_) => onSelected(slot) : null,
                showCheckmark: false,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
