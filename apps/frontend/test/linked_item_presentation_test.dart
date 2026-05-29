import 'package:calendar/features/calendar/domain/models/calendar_event.dart';
import 'package:calendar/features/calendar/presentation/linked_item_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts todo item and completion ids from linked item route path', () {
    final linkedItem = LinkedItem(
      type: LinkedItemType.todo,
      targetId: 'todo-completion-7',
      targetPath: '/todos/todo-item-2/completions/todo-completion-7',
      title: '남산 가기',
      createdAt: DateTime(2026, 5, 6),
    );

    expect(todoItemIdForLinkedItem(linkedItem), 'todo-item-2');
    expect(todoCompletionIdForLinkedItem(linkedItem), 'todo-completion-7');
  });

  test('extracts date record id from linked item route path', () {
    final linkedItem = LinkedItem(
      type: LinkedItemType.dateRecord,
      targetId: 'date-record-3',
      targetPath: '/records/dates/date-record-3',
      title: '성수 산책',
      createdAt: DateTime(2026, 5, 6),
    );

    expect(dateRecordIdForLinkedItem(linkedItem), 'date-record-3');
  });

  test('uses custom emoji before default linked item emoji', () {
    final linkedItem = LinkedItem(
      type: LinkedItemType.todo,
      targetId: 'todo-item-1',
      title: '하남검단산 가기',
      emoji: '⛰️',
      createdAt: DateTime(2026, 5, 7),
    );

    expect(linkedItemDisplayEmoji(linkedItem), '⛰️');
  });
}
