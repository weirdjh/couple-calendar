import 'package:calendar/core/time/calendar_date_utils.dart';
import 'package:calendar/features/anniversaries/domain/models/anniversary.dart';
import 'package:calendar/features/anniversaries/domain/services/anniversary_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calculates 100 day anniversary inside the visible range', () {
    final anniversary = Anniversary(
      id: 'a1',
      coupleId: 'c1',
      title: '처음 만난 날',
      baseDate: DateTime(2026),
      kind: AnniversaryKind.firstMet,
      createdBy: 'u1',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    final occurrences = calculateAnniversaryOccurrences(
      anniversary: anniversary,
      visibleRange: DateRange(start: DateTime(2026, 4), end: DateTime(2026, 5)),
    );

    expect(occurrences.single.label, '100일');
    expect(occurrences.single.date, DateTime(2026, 4, 10));
  });

  test('calculates yearly anniversary inside the visible range', () {
    final anniversary = Anniversary(
      id: 'a1',
      coupleId: 'c1',
      title: '사귄 날',
      baseDate: DateTime(2024, 5, 4),
      kind: AnniversaryKind.relationshipStart,
      createdBy: 'u1',
      createdAt: DateTime(2024, 5, 4),
      updatedAt: DateTime(2024, 5, 4),
    );

    final occurrences = calculateAnniversaryOccurrences(
      anniversary: anniversary,
      visibleRange: DateRange(start: DateTime(2026, 5), end: DateTime(2026, 6)),
    );

    expect(occurrences.single.label, '2주년');
    expect(occurrences.single.date, DateTime(2026, 5, 4));
  });
}
