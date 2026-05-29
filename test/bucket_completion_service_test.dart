import 'package:calendar/core/time/calendar_date_utils.dart' as dates;
import 'package:calendar/features/auth/presentation/controllers/session_controller.dart';
import 'package:calendar/features/calendar/domain/models/calendar_event.dart';
import 'package:calendar/features/calendar/domain/models/event_input.dart';
import 'package:calendar/features/calendar/presentation/controllers/calendar_controller.dart';
import 'package:calendar/features/date_records/presentation/controllers/date_record_controller.dart';
import 'package:calendar/features/todos/application/bucket_completion_service.dart';
import 'package:calendar/features/todos/presentation/controllers/todo_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'completeItemForEvent creates a completion and links it to a date record',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

    container
        .read(sessionControllerProvider.notifier)
        .createDemoCouple(partnerName: '상대방');
    await Future<void>.delayed(Duration.zero);
    container.read(todoControllerProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final todoState = container.read(todoControllerProvider);
      final item = todoState.itemById('todo-item-2')!;
      final category = todoState.categoryForItem(item.id);
      final targetDate = dates.dateOnly(
        DateTime.now().add(const Duration(days: 8)),
      );

      final event = await container
          .read(calendarControllerProvider.notifier)
          .createEvent(
            EventInput(
              title: '남산 산책',
              startAt: targetDate,
              endAt: targetDate.add(const Duration(days: 1)),
              isAllDay: true,
              ownership: EventOwnership.shared,
            ),
          );

      expect(event, isNotNull);

      final result = await container
          .read(bucketCompletionServiceProvider)
          .completeItemForEvent(item: item, event: event!, category: category);

      expect(result, isNotNull);
      expect(
        container
            .read(todoControllerProvider)
            .completionsForItem(item.id)
            .map((completion) => completion.id),
        contains(result!.completion.id),
      );

      final linkedRecord = container
          .read(dateRecordControllerProvider)
          .recordById(result.dateRecordId);
      expect(linkedRecord, isNotNull);
      expect(
        linkedRecord!.linkedItems.where(
          (linkedItem) =>
              linkedItem.type == LinkedItemType.todo &&
              linkedItem.targetId == result.completion.id,
        ),
        isNotEmpty,
      );
    },
  );
}
