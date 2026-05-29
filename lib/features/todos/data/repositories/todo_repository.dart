import '../../domain/models/todo_item.dart';

abstract class TodoRepository {
  Future<TodoSnapshot> fetchTodos({
    required String coupleId,
    required String userId,
  });

  Future<TodoCategory> createCategory({
    required String coupleId,
    required String userId,
    required TodoCategoryDraft draft,
  });

  Future<TodoCategory> updateCategory({
    required String coupleId,
    required TodoCategory category,
  });

  Future<TodoItem> createItem({
    required String coupleId,
    required String userId,
    required TodoItemDraft draft,
  });

  Future<TodoItem> updateItem({
    required String coupleId,
    required TodoItem item,
  });

  Future<TodoCompletion> createCompletion({
    required String coupleId,
    required String userId,
    required TodoCompletionDraft draft,
  });

  Future<void> deleteCompletion({
    required String coupleId,
    required String userId,
    required String completionId,
  });
}

class TodoSnapshot {
  const TodoSnapshot({
    this.categories = const [],
    this.items = const [],
    this.completions = const [],
  });

  final List<TodoCategory> categories;
  final List<TodoItem> items;
  final List<TodoCompletion> completions;
}

class TodoCategoryDraft {
  const TodoCategoryDraft({required this.title, required this.emoji});

  final String title;
  final String emoji;
}

class TodoItemDraft {
  const TodoItemDraft({
    required this.categoryId,
    required this.title,
    this.note = '',
  });

  final String categoryId;
  final String title;
  final String note;
}

class TodoCompletionDraft {
  const TodoCompletionDraft({
    required this.itemId,
    required this.completedAt,
    required this.calendarEventId,
    this.memo = '',
  });

  final String itemId;
  final DateTime completedAt;
  final String calendarEventId;
  final String memo;
}
