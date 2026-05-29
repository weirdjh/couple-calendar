import 'package:calendar/core/time/calendar_date_utils.dart' as dates;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats multi-day event date ranges without time details', () {
    final label = dates.formatEventDateRangeLabel(
      startAt: DateTime(2026, 5, 13, 9),
      endAt: DateTime(2026, 5, 15, 18),
      isAllDay: false,
    );

    expect(label, '2026.05.13 - 2026.05.15');
  });

  test('uses inclusive end date for all-day event date ranges', () {
    final label = dates.formatEventDateRangeLabel(
      startAt: DateTime(2026, 5, 13),
      endAt: DateTime(2026, 5, 16),
      isAllDay: true,
    );

    expect(label, '2026.05.13 - 2026.05.15');
  });
}
