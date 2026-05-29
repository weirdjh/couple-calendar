import 'package:korean_lunar_utils/korean_lunar_utils.dart';

import '../../../../core/time/calendar_date_utils.dart';
import '../models/anniversary.dart';

List<AnniversaryOccurrence> calculateAnniversaryOccurrences({
  required Anniversary anniversary,
  required DateRange visibleRange,
}) {
  final baseDate = _solarBaseDate(anniversary);
  final occurrences = <AnniversaryOccurrence>[];

  if (anniversary.repeatRule == AnniversaryRepeatRule.every100Days ||
      anniversary.repeatRule == AnniversaryRepeatRule.every100DaysAndYearly) {
    final startDayCount =
        ((visibleRange.start.difference(baseDate).inDays + 1) / 100).floor() *
        100;
    for (
      var dayCount = startDayCount < 100 ? 100 : startDayCount;
      ;
      dayCount += 100
    ) {
      final date = baseDate.add(Duration(days: dayCount - 1));
      if (!date.isBefore(visibleRange.end)) {
        break;
      }
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
  }

  if (anniversary.repeatRule == AnniversaryRepeatRule.yearly ||
      anniversary.repeatRule == AnniversaryRepeatRule.every100DaysAndYearly) {
    final yearlyOccurrences = switch (anniversary.calendarType) {
      AnniversaryCalendarType.solar => _solarYearlyOccurrences(
        anniversary: anniversary,
        baseDate: baseDate,
        visibleRange: visibleRange,
      ),
      AnniversaryCalendarType.lunar => _lunarYearlyOccurrences(
        anniversary: anniversary,
        visibleRange: visibleRange,
      ),
    };
    occurrences.addAll(yearlyOccurrences);
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

List<AnniversaryOccurrence> _solarYearlyOccurrences({
  required Anniversary anniversary,
  required DateTime baseDate,
  required DateRange visibleRange,
}) {
  final occurrences = <AnniversaryOccurrence>[];
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
  return occurrences;
}

List<AnniversaryOccurrence> _lunarYearlyOccurrences({
  required Anniversary anniversary,
  required DateRange visibleRange,
}) {
  final occurrences = <AnniversaryOccurrence>[];
  final startYear = visibleRange.start.year - 1;
  final endYear = visibleRange.end.year + 1;
  for (var year = startYear; year <= endYear; year += 1) {
    final yearCount = year - anniversary.baseDate.year;
    if (yearCount <= 0) {
      continue;
    }
    final date = _lunarToSolarOrNull(
      year: year,
      month: anniversary.baseDate.month,
      day: anniversary.baseDate.day,
      isLeapMonth: anniversary.isLeapMonth,
    );
    if (date == null || !_containsDate(visibleRange, date)) {
      continue;
    }
    occurrences.add(
      AnniversaryOccurrence(
        anniversaryId: anniversary.id,
        title: anniversary.title,
        date: date,
        label: '$yearCount주년',
        sortOrder: 10000 + yearCount,
        yearCount: yearCount,
      ),
    );
  }
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

DateTime _solarBaseDate(Anniversary anniversary) {
  if (anniversary.calendarType == AnniversaryCalendarType.solar) {
    return dateOnly(anniversary.baseDate);
  }
  return _lunarToSolarOrNull(
        year: anniversary.baseDate.year,
        month: anniversary.baseDate.month,
        day: anniversary.baseDate.day,
        isLeapMonth: anniversary.isLeapMonth,
      ) ??
      dateOnly(anniversary.baseDate);
}

DateTime? _lunarToSolarOrNull({
  required int year,
  required int month,
  required int day,
  required bool isLeapMonth,
}) {
  try {
    return dateOnly(
      LunarSolarConverter.convertLunarDateToSolar(
        LunarDate(year, month, day, isLeapMonth: isLeapMonth),
      ),
    );
  } on RangeError {
    return null;
  }
}
