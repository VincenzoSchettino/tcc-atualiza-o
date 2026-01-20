DateTime addMonths(DateTime date, int months) {
  final year = date.year + ((date.month - 1 + months) ~/ 12);
  final month = ((date.month - 1 + months) % 12) + 1;

  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  final day = date.day <= lastDayOfMonth ? date.day : lastDayOfMonth;

  return DateTime(year, month, day);
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);
