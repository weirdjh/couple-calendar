import 'package:calendar/core/time/calendar_date_utils.dart' as dates;
import 'package:calendar/features/auth/presentation/controllers/session_controller.dart';
import 'package:calendar/features/calendar/domain/models/calendar_event.dart';
import 'package:calendar/features/calendar/domain/models/event_input.dart';
import 'package:calendar/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'createEvent loads the target month and keeps linked items visible',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(sessionControllerProvider.notifier)
          .createDemoCouple(partnerName: '상대방');
      await Future<void>.delayed(Duration.zero);

      final targetDate = DateTime.now().add(const Duration(days: 45));
      final linkedItem = LinkedItem(
        type: LinkedItemType.dateRecord,
        targetId: 'date-record-test',
        targetPath: '/records/dates/date-record-test',
        title: '테스트 데이트 기록',
        createdAt: DateTime.now(),
      );

      final event = await container
          .read(calendarControllerProvider.notifier)
          .createEvent(
            EventInput(
              title: '테스트 데이트 기록',
              startAt: dates.dateOnly(targetDate),
              endAt: dates.dateOnly(targetDate).add(const Duration(days: 1)),
              isAllDay: true,
              ownership: EventOwnership.shared,
              linkedItems: [linkedItem],
            ),
          );

      final state = container.read(calendarControllerProvider);

      expect(event, isNotNull);
      expect(state.focusedMonth, dates.monthStart(targetDate));
      expect(state.selectedDate, dates.dateOnly(targetDate));
      expect(
        state.selectedDateEvents.expand((event) => event.linkedItems),
        contains(linkedItem),
      );
    },
  );
}
