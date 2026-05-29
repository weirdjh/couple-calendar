import '../../../../core/time/calendar_date_utils.dart' as dates;

class CalendarDayStyle {
  const CalendarDayStyle({
    required this.date,
    this.isWeekend = false,
    this.isHoliday = false,
    this.label,
  });

  final DateTime date;
  final bool isWeekend;
  final bool isHoliday;
  final String? label;

  bool get isRedDay => isHoliday || date.weekday == DateTime.sunday;
  bool get isSaturday => date.weekday == DateTime.saturday;
}

class KoreanHolidayCalendar {
  const KoreanHolidayCalendar();

  CalendarDayStyle styleFor(DateTime date) {
    final normalized = dates.dateOnly(date);
    final label = _fixedHolidayLabel(normalized);
    return CalendarDayStyle(
      date: normalized,
      isWeekend:
          normalized.weekday == DateTime.saturday ||
          normalized.weekday == DateTime.sunday,
      isHoliday: label != null,
      label: label,
    );
  }

  String? _fixedHolidayLabel(DateTime date) {
    return switch ((date.month, date.day)) {
      (1, 1) => '신정',
      (3, 1) => '삼일절',
      (5, 5) => '어린이날',
      (6, 6) => '현충일',
      (8, 15) => '광복절',
      (10, 3) => '개천절',
      (10, 9) => '한글날',
      (12, 25) => '성탄절',
      _ => null,
    };
  }
}
