import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/controllers/session_controller.dart';
import '../../domain/models/todo_item.dart';

final todoControllerProvider = NotifierProvider<TodoController, TodoState>(
  TodoController.new,
);

class TodoState {
  const TodoState({
    this.categories = const [],
    this.items = const [],
    this.completions = const [],
    this.errorMessage,
  });

  final List<TodoCategory> categories;
  final List<TodoItem> items;
  final List<TodoCompletion> completions;
  final String? errorMessage;

  List<TodoItem> itemsForCategory(String categoryId) {
    return items.where((item) => item.categoryId == categoryId).toList();
  }

  List<TodoCompletion> completionsForItem(String itemId) {
    final result =
        completions.where((completion) => completion.itemId == itemId).toList()
          ..sort(
            (left, right) => right.completedAt.compareTo(left.completedAt),
          );
    return result;
  }

  int completionCountForCategory(String categoryId) {
    final itemIds = itemsForCategory(categoryId).map((item) => item.id).toSet();
    return completions
        .where((completion) => itemIds.contains(completion.itemId))
        .length;
  }

  TodoState copyWith({
    List<TodoCategory>? categories,
    List<TodoItem>? items,
    List<TodoCompletion>? completions,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TodoState(
      categories: categories ?? this.categories,
      items: items ?? this.items,
      completions: completions ?? this.completions,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class TodoController extends Notifier<TodoState> {
  var _nextCategoryId = 3;
  var _nextItemId = 5;
  var _nextCompletionId = 1;

  @override
  TodoState build() {
    final session = ref.watch(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      return const TodoState();
    }

    final now = DateTime.now();
    return TodoState(
      categories: [
        TodoCategory(
          id: 'todo-category-1',
          coupleId: couple.id,
          title: '등산 하기',
          createdBy: user.id,
          createdAt: now,
          updatedAt: now,
        ),
        TodoCategory(
          id: 'todo-category-2',
          coupleId: couple.id,
          title: '와인 마시기',
          createdBy: user.id,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      items: [
        TodoItem(
          id: 'todo-item-1',
          coupleId: couple.id,
          categoryId: 'todo-category-1',
          title: '하남검단산 가기',
          note: '날씨 좋을 때 오전 출발',
          createdBy: user.id,
          createdAt: now,
          updatedAt: now,
        ),
        TodoItem(
          id: 'todo-item-2',
          coupleId: couple.id,
          categoryId: 'todo-category-1',
          title: '남산 가기',
          note: '밤 산책도 좋음',
          createdBy: user.id,
          createdAt: now,
          updatedAt: now,
        ),
        TodoItem(
          id: 'todo-item-3',
          coupleId: couple.id,
          categoryId: 'todo-category-2',
          title: '내추럴 와인바 가기',
          note: '조용한 곳으로',
          createdBy: user.id,
          createdAt: now,
          updatedAt: now,
        ),
        TodoItem(
          id: 'todo-item-4',
          coupleId: couple.id,
          categoryId: 'todo-category-2',
          title: '샴페인 마셔보기',
          createdBy: user.id,
          createdAt: now,
          updatedAt: now,
        ),
      ],
    );
  }

  void addCategory(String title) {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return;
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '카테고리 이름을 입력해 주세요.');
      return;
    }

    final now = DateTime.now();
    final category = TodoCategory(
      id: 'todo-category-${_nextCategoryId++}',
      coupleId: couple.id,
      title: trimmedTitle,
      createdBy: user.id,
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(
      categories: [...state.categories, category],
      clearError: true,
    );
  }

  void addItem({
    required String categoryId,
    required String title,
    String note = '',
  }) {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return;
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '세부 항목을 입력해 주세요.');
      return;
    }

    final now = DateTime.now();
    final item = TodoItem(
      id: 'todo-item-${_nextItemId++}',
      coupleId: couple.id,
      categoryId: categoryId,
      title: trimmedTitle,
      note: note.trim(),
      createdBy: user.id,
      createdAt: now,
      updatedAt: now,
    );
    state = state.copyWith(items: [...state.items, item], clearError: true);
  }

  TodoCompletion? addCompletion({
    required String itemId,
    required DateTime completedAt,
    required String calendarEventId,
    String memo = '',
  }) {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }
    if (!state.items.any((item) => item.id == itemId)) {
      state = state.copyWith(errorMessage: '세부 항목을 찾을 수 없어요.');
      return null;
    }

    final now = DateTime.now();
    final completion = TodoCompletion(
      id: 'todo-completion-${_nextCompletionId++}',
      coupleId: couple.id,
      itemId: itemId,
      completedAt: completedAt,
      completedBy: user.id,
      calendarEventId: calendarEventId,
      memo: memo.trim(),
      createdAt: now,
    );
    state = state.copyWith(
      completions: [...state.completions, completion],
      clearError: true,
    );
    return completion;
  }

  void removeCompletion(String completionId) {
    final exists = state.completions.any(
      (completion) => completion.id == completionId,
    );
    if (!exists) {
      return;
    }
    state = state.copyWith(
      completions: state.completions
          .where((completion) => completion.id != completionId)
          .toList(),
      clearError: true,
    );
  }
}
