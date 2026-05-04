import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../../domain/models/anniversary.dart';
import '../../domain/services/anniversary_calculator.dart';

final anniversariesProvider = Provider<List<Anniversary>>((ref) {
  final session = ref.watch(sessionControllerProvider);
  final user = session.currentUser;
  final couple = session.currentCouple;
  if (user == null || couple == null) {
    return const [];
  }

  final now = DateTime.now();
  final baseDate =
      couple.relationshipStartDate ??
      DateTime(now.year - 1, now.month, now.day - 12);
  return [
    Anniversary(
      id: 'anniversary-first-met',
      coupleId: couple.id,
      title: '처음 만난 날',
      baseDate: baseDate,
      kind: AnniversaryKind.firstMet,
      createdBy: user.id,
      createdAt: now,
      updatedAt: now,
    ),
  ];
});

final visibleAnniversaryOccurrencesProvider =
    Provider<List<AnniversaryOccurrence>>((ref) {
      final calendarState = ref.watch(calendarControllerProvider);
      final anniversaries = ref.watch(anniversariesProvider);
      final range = visibleMonthRange(calendarState.focusedMonth);

      return anniversaries
          .expand(
            (anniversary) => calculateAnniversaryOccurrences(
              anniversary: anniversary,
              visibleRange: range,
            ),
          )
          .toList();
    });

final selectedDateAnniversaryOccurrencesProvider =
    Provider<List<AnniversaryOccurrence>>((ref) {
      final calendarState = ref.watch(calendarControllerProvider);
      final occurrences = ref.watch(visibleAnniversaryOccurrencesProvider);
      return occurrences
          .where(
            (occurrence) =>
                isSameDate(occurrence.date, calendarState.selectedDate),
          )
          .toList();
    });

final nextAnniversaryOccurrenceProvider = Provider<AnniversaryOccurrence?>((
  ref,
) {
  final anniversaries = ref.watch(anniversariesProvider);
  final upcoming =
      anniversaries
          .map(
            (anniversary) => nextAnniversaryOccurrence(
              anniversary: anniversary,
              fromDate: DateTime.now(),
            ),
          )
          .nonNulls
          .toList()
        ..sort((left, right) => left.date.compareTo(right.date));
  if (upcoming.isEmpty) {
    return null;
  }
  return upcoming.first;
});

final upcomingAnniversaryOccurrencesProvider =
    Provider<List<AnniversaryOccurrence>>((ref) {
      final anniversaries = ref.watch(anniversariesProvider);
      final now = DateTime.now();
      final range = DateRange(
        start: dateOnly(now),
        end: dateOnly(now).add(const Duration(days: 366 * 3)),
      );

      final occurrences =
          anniversaries
              .expand(
                (anniversary) => calculateAnniversaryOccurrences(
                  anniversary: anniversary,
                  visibleRange: range,
                ),
              )
              .where((occurrence) => !occurrence.date.isBefore(dateOnly(now)))
              .toList()
            ..sort((left, right) => left.date.compareTo(right.date));
      return occurrences.take(12).toList();
    });
