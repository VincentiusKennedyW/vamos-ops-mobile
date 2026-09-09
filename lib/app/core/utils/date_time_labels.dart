String clockLabel(DateTime? value) {
  if (value == null) return '—';
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}

String dateTimeLabel(DateTime value) {
  final local = value.toLocal();
  return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} ${clockLabel(local)}';
}

String durationLabel(DateTime start, DateTime end) {
  final minutes = end.difference(start).inMinutes;
  if (minutes < 60) return '$minutes menit';
  final hours = minutes ~/ 60;
  final remainder = minutes % 60;
  return remainder == 0 ? '$hours jam' : '$hours jam $remainder menit';
}
