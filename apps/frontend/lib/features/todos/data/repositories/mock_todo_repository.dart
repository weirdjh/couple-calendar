import '../../domain/models/todo_item.dart';
import 'todo_repository.dart';

class MockTodoRepository implements TodoRepository {
  final Map<String, TodoSnapshot> _snapshotsByCouple = {};
  var _nextCategoryId = 3;
  var _nextItemId = 5;
  var _nextCompletionId = 2;

  @override
  Future<TodoSnapshot> fetchTodos({
    required String coupleId,
    required String userId,
  }) async {
    return _ensureSeeded(coupleId: coupleId, userId: userId);
  }

  @override
  Future<TodoCategory> createCategory({
    required String coupleId,
    required String userId,
    required TodoCategoryDraft draft,
  }) async {
    final snapshot = _ensureSeeded(coupleId: coupleId, userId: userId);
    final now = DateTime.now();
    final category = TodoCategory(
      id: 'todo-category-${_nextCategoryId++}',
      coupleId: coupleId,
      title: draft.title,
      emoji: draft.emoji,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );
    _snapshotsByCouple[coupleId] = TodoSnapshot(
      categories: [...snapshot.categories, category],
      items: snapshot.items,
      completions: snapshot.completions,
    );
    return category;
  }

  @override
  Future<TodoCategory> updateCategory({
    required String coupleId,
    required TodoCategory category,
  }) async {
    final snapshot = _snapshot(coupleId);
    _snapshotsByCouple[coupleId] = TodoSnapshot(
      categories: snapshot.categories
          .map((item) => item.id == category.id ? category : item)
          .toList(),
      items: snapshot.items,
      completions: snapshot.completions,
    );
    return category;
  }

  @override
  Future<TodoItem> createItem({
    required String coupleId,
    required String userId,
    required TodoItemDraft draft,
  }) async {
    final snapshot = _ensureSeeded(coupleId: coupleId, userId: userId);
    final now = DateTime.now();
    final item = TodoItem(
      id: 'todo-item-${_nextItemId++}',
      coupleId: coupleId,
      categoryId: draft.categoryId,
      title: draft.title,
      note: draft.note,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );
    _snapshotsByCouple[coupleId] = TodoSnapshot(
      categories: snapshot.categories,
      items: [...snapshot.items, item],
      completions: snapshot.completions,
    );
    return item;
  }

  @override
  Future<TodoItem> updateItem({
    required String coupleId,
    required TodoItem item,
  }) async {
    final snapshot = _snapshot(coupleId);
    _snapshotsByCouple[coupleId] = TodoSnapshot(
      categories: snapshot.categories,
      items: snapshot.items
          .map((candidate) => candidate.id == item.id ? item : candidate)
          .toList(),
      completions: snapshot.completions,
    );
    return item;
  }

  @override
  Future<TodoCompletion> createCompletion({
    required String coupleId,
    required String userId,
    required TodoCompletionDraft draft,
  }) async {
    final snapshot = _ensureSeeded(coupleId: coupleId, userId: userId);
    final completion = TodoCompletion(
      id: 'todo-completion-${_nextCompletionId++}',
      coupleId: coupleId,
      itemId: draft.itemId,
      completedAt: draft.completedAt,
      completedBy: userId,
      calendarEventId: draft.calendarEventId,
      memo: draft.memo,
      createdAt: DateTime.now(),
    );
    _snapshotsByCouple[coupleId] = TodoSnapshot(
      categories: snapshot.categories,
      items: snapshot.items,
      completions: [...snapshot.completions, completion],
    );
    return completion;
  }

  @override
  Future<void> deleteCompletion({
    required String coupleId,
    required String userId,
    required String completionId,
  }) async {
    final snapshot = _snapshot(coupleId);
    _snapshotsByCouple[coupleId] = TodoSnapshot(
      categories: snapshot.categories,
      items: snapshot.items,
      completions: snapshot.completions
          .where((completion) => completion.id != completionId)
          .toList(),
    );
  }

  TodoSnapshot _ensureSeeded({
    required String coupleId,
    required String userId,
  }) {
    return _snapshotsByCouple.putIfAbsent(
      coupleId,
      () => _seed(coupleId: coupleId, userId: userId),
    );
  }

  TodoSnapshot _snapshot(String coupleId) {
    return _snapshotsByCouple[coupleId] ?? const TodoSnapshot();
  }

  TodoSnapshot _seed({required String coupleId, required String userId}) {
    final now = DateTime.now();
    final mountainDate = DateTime(now.year, now.month, now.day + 3);
    return TodoSnapshot(
      categories: [
        TodoCategory(
          id: 'todo-category-1',
          coupleId: coupleId,
          title: '등산 하기',
          emoji: '⛰️',
          createdBy: userId,
          createdAt: now,
          updatedAt: now,
        ),
        TodoCategory(
          id: 'todo-category-2',
          coupleId: coupleId,
          title: '와인 마시기',
          emoji: '🍷',
          createdBy: userId,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      items: [
        TodoItem(
          id: 'todo-item-1',
          coupleId: coupleId,
          categoryId: 'todo-category-1',
          title: '하남검단산 가기',
          note: '날씨 좋을 때 오전 출발',
          createdBy: userId,
          createdAt: now,
          updatedAt: now,
        ),
        TodoItem(
          id: 'todo-item-2',
          coupleId: coupleId,
          categoryId: 'todo-category-1',
          title: '남산 가기',
          note: '밤 산책도 좋음',
          createdBy: userId,
          createdAt: now,
          updatedAt: now,
        ),
        TodoItem(
          id: 'todo-item-3',
          coupleId: coupleId,
          categoryId: 'todo-category-2',
          title: '내추럴 와인바 가기',
          note: '조용한 곳으로',
          createdBy: userId,
          createdAt: now,
          updatedAt: now,
        ),
        TodoItem(
          id: 'todo-item-4',
          coupleId: coupleId,
          categoryId: 'todo-category-2',
          title: '샴페인 마셔보기',
          createdBy: userId,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      completions: [
        TodoCompletion(
          id: 'todo-completion-1',
          coupleId: coupleId,
          itemId: 'todo-item-1',
          completedAt: mountainDate,
          completedBy: userId,
          calendarEventId: 'event-2',
          memo: '하남검단산 데이트 기록과 연결',
          createdAt: now,
        ),
      ],
    );
  }
}
