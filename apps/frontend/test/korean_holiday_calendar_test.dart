import 'package:calendar/features/calendar/domain/services/korean_holiday_calendar.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const holidays = KoreanHolidayCalendar();

  test('marks fixed Korean public holidays as red days with labels', () {
    final style = holidays.styleFor(DateTime(2026, 3, 1));

    expect(style.isHoliday, isTrue);
    expect(style.isRedDay, isTrue);
    expect(style.label, '삼일절');
  });

  test('marks Saturday separately from Sunday red days', () {
    final saturday = holidays.styleFor(DateTime(2026, 5, 9));
    final sunday = holidays.styleFor(DateTime(2026, 5, 10));

    expect(saturday.isSaturday, isTrue);
    expect(saturday.isRedDay, isFalse);
    expect(sunday.isSaturday, isFalse);
    expect(sunday.isRedDay, isTrue);
  });
}
