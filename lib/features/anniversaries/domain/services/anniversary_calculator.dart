import '../../../../core/time/calendar_date_utils.dart';
import '../models/anniversary.dart';

List<AnniversaryOccurrence> calculateAnniversaryOccurrences({
  required Anniversary anniversary,
  required DateRange visibleRange,
}) {
  final baseDate = dateOnly(anniversary.baseDate);
  final occurrences = <AnniversaryOccurrence>[];

  for (final dayCount in _dayMilestones) {
    final date = baseDate.add(Duration(days: dayCount - 1));
    if (_containsDate(visibleRange, date)) {
      occurrences.add(
        AnniversaryOccurrence(
          anniversaryId: anniversary.id,
          title: anniversary.title,
          date: date,
          label: '$dayCount일',
          sortOrder: dayCount,
          dayCount: dayCount,
        ),
      );
    }
  }

  final startYear = visibleRange.start.year - baseDate.year;
  final endYear = visibleRange.end.year - baseDate.year + 1;
  for (var year = startYear; year <= endYear; year += 1) {
    if (year <= 0) {
      continue;
    }
    final date = _safeAnniversaryDate(baseDate, year);
    if (_containsDate(visibleRange, date)) {
      occurrences.add(
        AnniversaryOccurrence(
          anniversaryId: anniversary.id,
          title: anniversary.title,
          date: date,
          label: '$year주년',
          sortOrder: 10000 + year,
          yearCount: year,
        ),
      );
    }
  }

  occurrences.sort((left, right) {
    final dateCompare = left.date.compareTo(right.date);
    if (dateCompare != 0) {
      return dateCompare;
    }
    return left.sortOrder.compareTo(right.sortOrder);
  });
  return occurrences;
}

AnniversaryOccurrence? nextAnniversaryOccurrence({
  required Anniversary anniversary,
  required DateTime fromDate,
}) {
  final from = dateOnly(fromDate);
  final range = DateRange(
    start: from,
    end: from.add(const Duration(days: 366 * 3)),
  );
  final upcoming = calculateAnniversaryOccurrences(
    anniversary: anniversary,
    visibleRange: range,
  ).where((occurrence) => !occurrence.date.isBefore(from)).toList();
  if (upcoming.isEmpty) {
    return null;
  }
  return upcoming.first;
}

const _dayMilestones = [100, 200, 300, 500, 700, 1000];

bool _containsDate(DateRange range, DateTime value) {
  final date = dateOnly(value);
  return !date.isBefore(dateOnly(range.start)) &&
      date.isBefore(dateOnly(range.end));
}

DateTime _safeAnniversaryDate(DateTime baseDate, int yearsAfter) {
  final targetYear = baseDate.year + yearsAfter;
  final lastDayOfMonth = DateTime(targetYear, baseDate.month + 1, 0).day;
  final day = baseDate.day > lastDayOfMonth ? lastDayOfMonth : baseDate.day;
  return DateTime(targetYear, baseDate.month, day);
}
