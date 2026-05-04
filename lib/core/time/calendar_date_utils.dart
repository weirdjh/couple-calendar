class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool overlaps(DateTime startAt, DateTime endAt) {
    return startAt.isBefore(end) && !endAt.isBefore(start);
  }
}

DateTime dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime monthStart(DateTime value) {
  return DateTime(value.year, value.month);
}

DateTime nextMonth(DateTime value) {
  return DateTime(value.year, value.month + 1);
}

DateRange visibleMonthRange(DateTime focusedMonth) {
  final firstDay = monthStart(focusedMonth);
  final leadingDays = firstDay.weekday % DateTime.daysPerWeek;
  final gridStart = firstDay.subtract(Duration(days: leadingDays));
  return DateRange(
    start: gridStart,
    end: gridStart.add(const Duration(days: 42)),
  );
}

bool isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

List<DateTime> calendarGridDays(DateTime focusedMonth) {
  final range = visibleMonthRange(focusedMonth);
  return List.generate(42, (index) => range.start.add(Duration(days: index)));
}

String formatMonthLabel(DateTime value) {
  return '${value.year}.${value.month.toString().padLeft(2, '0')}';
}

String formatDateLabel(DateTime value) {
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
}

String formatTimeLabel(DateTime value) {
  return '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}
