import 'package:flutter/material.dart';

class TimeSlotPicker extends StatelessWidget {
  const TimeSlotPicker({
    super.key,
    required this.availableSlots,
    required this.selectedSlot,
    required this.onSelected,
    this.statuses = const {},
  });
  final List<String> availableSlots;
  final Map<String, String> statuses;
  final String? selectedSlot;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final times = statuses.isEmpty ? availableSlots : statuses.keys;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final time in times)
          Builder(
            builder: (context) {
              final open = availableSlots.contains(time);
              final full = statuses[time] == 'FULL';
              final color = open
                  ? Colors.green
                  : full
                  ? Colors.red
                  : Colors.grey;
              final label = open
                  ? 'Còn trống'
                  : full
                  ? 'Hết chỗ'
                  : 'Không khả dụng';
              return Semantics(
                label: '$time, $label',
                enabled: open,
                child: ChoiceChip(
                  label: Text('$time\n$label', textAlign: TextAlign.center),
                  labelStyle: TextStyle(color: color.shade900),
                  backgroundColor: color.shade100,
                  disabledColor: color.shade100,
                  selectedColor: color.shade300,
                  selected: selectedSlot == time,
                  onSelected: open ? (_) => onSelected(time) : null,
                ),
              );
            },
          ),
      ],
    );
  }
}
