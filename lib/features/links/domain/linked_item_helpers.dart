import 'models/linked_item.dart';

String? todoItemIdForLinkedItem(LinkedItem item) {
  final segments = _targetPathSegments(item);
  final todoIndex = segments.indexOf('todos');
  if (todoIndex >= 0 && todoIndex + 1 < segments.length) {
    return segments[todoIndex + 1];
  }
  return item.targetId.startsWith('todo-item') ? item.targetId : null;
}

String? todoCompletionIdForLinkedItem(LinkedItem item) {
  final segments = _targetPathSegments(item);
  final completionIndex = segments.indexOf('completions');
  if (completionIndex >= 0 && completionIndex + 1 < segments.length) {
    return segments[completionIndex + 1];
  }
  return item.targetId.startsWith('todo-completion') ? item.targetId : null;
}

String? dateRecordIdForLinkedItem(LinkedItem item) {
  final segments = _targetPathSegments(item);
  final dateRecordIndex = segments.indexOf('dates');
  if (dateRecordIndex >= 0 && dateRecordIndex + 1 < segments.length) {
    return segments[dateRecordIndex + 1];
  }
  return item.targetId.startsWith('date-record') ? item.targetId : null;
}

List<String> _targetPathSegments(LinkedItem item) {
  return item.targetPath
          ?.split('/')
          .where((segment) => segment.isNotEmpty)
          .toList() ??
      const [];
}
