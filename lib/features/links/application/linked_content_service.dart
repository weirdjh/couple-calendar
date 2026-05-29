import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../auth/presentation/controllers/session_controller.dart';
import '../../calendar/presentation/controllers/calendar_controller.dart';
import '../../date_records/presentation/controllers/date_record_controller.dart';
import 'api_link_use_case_client.dart';
import '../domain/linked_item_helpers.dart';
import '../../todos/presentation/controllers/todo_controller.dart';
import '../domain/models/linked_item.dart';

final linkedContentServiceProvider = Provider<LinkedContentService>(
  LinkedContentService.new,
);

class LinkedContentService {
  const LinkedContentService(this._ref);

  final Ref _ref;

  Future<void> unlinkCalendarEventItem({
    required String eventId,
    required LinkedItem linkedItem,
  }) async {
    final session = _ref.read(sessionControllerProvider);
    final couple = session.currentCouple;
    final user = session.currentUser;
    if (couple == null || user == null) {
      return;
    }
    if (useApi) {
      await _ref
          .read(apiLinkUseCaseClientProvider)
          .removeCalendarEventLinkedItem(
            coupleId: couple.id,
            userId: user.id,
            eventId: eventId,
            linkedItem: linkedItem,
          );
      await _refreshLinkedState();
      return;
    }
    final event = _ref
        .read(calendarControllerProvider)
        .events
        .where((item) => item.id == eventId)
        .firstOrNull;
    if (event == null) {
      return;
    }

    await _ref
        .read(calendarEventRepositoryProvider)
        .updateEvent(
          coupleId: couple.id,
          userId: user.id,
          event: event.copyWith(
            linkedItems: event.linkedItems
                .where(
                  (item) =>
                      item.type != linkedItem.type ||
                      item.targetId != linkedItem.targetId,
                )
                .toList(),
          ),
        );

    switch (linkedItem.type) {
      case LinkedItemType.todo:
        await removeTodoCompletionEverywhere(linkedItem.targetId);
      case LinkedItemType.dateRecord:
        await _ref
            .read(dateRecordRepositoryProvider)
            .unlinkCalendarEvent(
              coupleId: couple.id,
              userId: user.id,
              recordId: dateRecordIdForLinkedItem(linkedItem),
              eventId: eventId,
            );
      case LinkedItemType.conflict:
      case LinkedItemType.anniversary:
      case LinkedItemType.review:
      case LinkedItemType.place:
        break;
    }
    await _refreshLinkedState();
  }

  Future<void> removeTodoCompletionEverywhere(String completionId) async {
    final session = _ref.read(sessionControllerProvider);
    final couple = session.currentCouple;
    final user = session.currentUser;
    if (couple == null || user == null) {
      return;
    }
    if (useApi) {
      await _ref
          .read(apiLinkUseCaseClientProvider)
          .removeTodoCompletionEverywhere(
            coupleId: couple.id,
            userId: user.id,
            completionId: completionId,
          );
      await _refreshLinkedState();
      return;
    }
    final dateRecordRepository = _ref.read(dateRecordRepositoryProvider);
    final dateRecords = await dateRecordRepository.fetchDateRecords(
      coupleId: couple.id,
      userId: user.id,
    );
    for (final record in dateRecords) {
      final linkedItems = record.linkedItems.where(
        (item) =>
            item.type == LinkedItemType.todo && item.targetId == completionId,
      );
      for (final linkedItem in linkedItems) {
        await _ref
            .read(dateRecordRepositoryProvider)
            .removeLinkedItem(
              coupleId: couple.id,
              userId: user.id,
              recordId: record.id,
              linkedItem: linkedItem,
            );
      }
    }

    final events = _ref.read(calendarControllerProvider).events;
    for (final event in events) {
      final linkedItems = event.linkedItems.where(
        (item) =>
            item.type == LinkedItemType.todo && item.targetId == completionId,
      );
      for (final linkedItem in linkedItems) {
        await _ref
            .read(calendarEventRepositoryProvider)
            .updateEvent(
              coupleId: couple.id,
              userId: user.id,
              event: event.copyWith(
                linkedItems: event.linkedItems
                    .where(
                      (item) =>
                          item.type != linkedItem.type ||
                          item.targetId != linkedItem.targetId,
                    )
                    .toList(),
              ),
            );
      }
    }

    await _ref
        .read(todoRepositoryProvider)
        .deleteCompletion(
          coupleId: couple.id,
          userId: user.id,
          completionId: completionId,
        );
    await _refreshLinkedState();
  }

  Future<void> _refreshLinkedState() async {
    await _ref.read(todoControllerProvider.notifier).refreshTodos();
    await _ref.read(dateRecordControllerProvider.notifier).refreshDateRecords();
    await _ref.read(calendarControllerProvider.notifier).refreshVisibleMonth();
  }
}
