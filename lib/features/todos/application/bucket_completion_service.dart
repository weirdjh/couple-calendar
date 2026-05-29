import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_bootstrap.dart';
import '../../../core/time/calendar_date_utils.dart' as dates;
import '../../auth/presentation/controllers/session_controller.dart';
import '../../calendar/domain/models/calendar_event.dart';
import '../../date_records/application/date_record_service.dart';
import '../../date_records/presentation/controllers/date_record_controller.dart';
import '../../links/application/api_link_use_case_client.dart';
import '../data/repositories/todo_repository.dart';
import '../domain/models/todo_item.dart';
import '../presentation/controllers/todo_controller.dart';

final bucketCompletionServiceProvider = Provider<BucketCompletionService>(
  BucketCompletionService.new,
);

class BucketCompletionService {
  const BucketCompletionService(this._ref);

  final Ref _ref;

  Future<BucketCompletionResult?> completeItemForEvent({
    required TodoItem item,
    required CalendarEvent event,
    TodoCategory? category,
  }) async {
    final session = _ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      return null;
    }

    if (useApi) {
      final result = await _ref
          .read(apiLinkUseCaseClientProvider)
          .completeTodoItemForEvent(
            coupleId: couple.id,
            userId: user.id,
            itemId: item.id,
            eventId: event.id,
          );
      await _ref.read(todoControllerProvider.notifier).refreshTodos();
      await _ref
          .read(dateRecordControllerProvider.notifier)
          .refreshDateRecords();
      return BucketCompletionResult(
        completion: result.completion,
        linkedItem: result.linkedItem,
        dateRecordId: result.dateRecordId,
      );
    }

    final completedAt = dates.dateOnly(event.startAt);
    final completion = await _ref
        .read(todoRepositoryProvider)
        .createCompletion(
          coupleId: couple.id,
          userId: user.id,
          draft: TodoCompletionDraft(
            itemId: item.id,
            completedAt: completedAt,
            calendarEventId: event.id,
          ),
        );

    final linkedItem = linkedItemForTodoCompletion(
      item: item,
      completion: completion,
      category: category,
    );
    final dateRecordId = await _ref
        .read(dateRecordServiceProvider)
        .ensureDateRecordForEvent(event);
    if (dateRecordId == null) {
      return null;
    }

    await _ref
        .read(dateRecordRepositoryProvider)
        .addLinkedItem(
          coupleId: couple.id,
          userId: user.id,
          recordId: dateRecordId,
          linkedItem: linkedItem,
        );
    await _ref.read(todoControllerProvider.notifier).refreshTodos();
    await _ref.read(dateRecordControllerProvider.notifier).refreshDateRecords();

    return BucketCompletionResult(
      completion: completion,
      linkedItem: linkedItem,
      dateRecordId: dateRecordId,
    );
  }
}

class BucketCompletionResult {
  const BucketCompletionResult({
    required this.completion,
    required this.linkedItem,
    required this.dateRecordId,
  });

  final TodoCompletion completion;
  final LinkedItem linkedItem;
  final String dateRecordId;
}

LinkedItem linkedItemForTodoCompletion({
  required TodoItem item,
  required TodoCompletion completion,
  TodoCategory? category,
}) {
  return LinkedItem(
    type: LinkedItemType.todo,
    targetId: completion.id,
    targetPath: '/todos/${item.id}/completions/${completion.id}',
    title: item.title,
    subtitle: category?.title ?? (item.note.isEmpty ? null : item.note),
    date: completion.completedAt,
    preview: '버킷리스트 달성',
    emoji: category?.emoji,
    createdAt: completion.createdAt,
  );
}

LinkedItem previewLinkedItemForTodoItem({
  required TodoItem item,
  required DateTime date,
  TodoCategory? category,
}) {
  return LinkedItem(
    type: LinkedItemType.todo,
    targetId: item.id,
    targetPath: '/todos/${item.id}',
    title: item.title,
    subtitle: category?.title ?? (item.note.isEmpty ? null : item.note),
    date: date,
    preview: '버킷리스트 연결 예정',
    emoji: category?.emoji,
    createdAt: DateTime.now(),
  );
}
