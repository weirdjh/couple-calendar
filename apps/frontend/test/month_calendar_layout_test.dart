import 'package:calendar/features/anniversaries/domain/models/anniversary.dart';
import 'package:calendar/features/calendar/domain/models/calendar_event.dart';
import 'package:calendar/features/calendar/presentation/widgets/month_calendar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('does not overflow on holiday cells with multi-day events', (
    tester,
  ) async {
    final now = DateTime(2026, 2, 28);
    final event = CalendarEvent(
      id: 'event-1',
      coupleId: 'couple-1',
      title: '긴 여행 일정',
      startAt: DateTime(2026, 2, 28, 9),
      endAt: DateTime(2026, 3, 2, 18),
      createdBy: 'user-a',
      ownerUserId: 'user-a',
      createdAt: now,
      updatedAt: now,
    );

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            child: MonthCalendar(
              focusedMonth: DateTime(2026, 3),
              selectedDate: DateTime(2026, 3, 1),
              events: [event],
              anniversaries: const <AnniversaryOccurrence>[],
              showEventTitles: true,
              currentUserId: 'user-a',
              onDateSelected: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('삼일절'), findsOneWidget);
    expect(find.text('긴 여행 일정'), findsWidgets);
  });
}
