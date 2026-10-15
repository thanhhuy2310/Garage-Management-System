// Format decimal text directly so SQL decimal amounts retain their fractional digits.
String formatCurrency(Object value) {
  final text = value.toString();
  final match = RegExp(r'^(-?)([0-9]+)(?:\.([0-9]{1,2}))?$').firstMatch(text);
  if (match == null) return '—';
  final whole = match.group(2)!;
  final grouped = whole.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.');
  final fraction = match.group(3);
  final suffix = fraction == null || int.parse(fraction) == 0 ? '' : ',${fraction.padRight(2, '0')}';
  return '${match.group(1)}$grouped$suffix ₫';
}

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String formatMileage(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write('.');
    buffer.write(digits[index]);
  }
  return '${buffer.toString()} km';
}
