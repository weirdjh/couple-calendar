class DateRange {
  const DateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  bool overlaps(DateTime startAt, DateTime endAt) {
    return startAt.isBefore(end) && endAt.isAfter(start);
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

String formatEventRangeLabel({
  required DateTime startAt,
  required DateTime endAt,
  required bool isAllDay,
}) {
  if (isAllDay) {
    final inclusiveEnd = dateOnly(endAt).subtract(const Duration(days: 1));
    if (isSameDate(startAt, inclusiveEnd)) {
      return '${formatDateLabel(startAt)} · 하루 종일';
    }
    return '${formatDateLabel(startAt)} - ${formatDateLabel(inclusiveEnd)} · 하루 종일';
  }

  if (isSameDate(startAt, endAt)) {
    return '${formatDateLabel(startAt)} ${formatTimeLabel(startAt)} - ${formatTimeLabel(endAt)}';
  }
  return '${formatDateLabel(startAt)} ${formatTimeLabel(startAt)} - ${formatDateLabel(endAt)} ${formatTimeLabel(endAt)}';
}

String formatEventDateRangeLabel({
  required DateTime startAt,
  required DateTime endAt,
  required bool isAllDay,
}) {
  final start = dateOnly(startAt);
  final end = isAllDay
      ? dateOnly(endAt).subtract(const Duration(days: 1))
      : dateOnly(endAt);
  if (isSameDate(start, end)) {
    return formatDateLabel(start);
  }
  return '${formatDateLabel(start)} - ${formatDateLabel(end)}';
}
