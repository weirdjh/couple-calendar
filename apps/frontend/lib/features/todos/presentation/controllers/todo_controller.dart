import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../auth/presentation/controllers/session_controller.dart';
import '../../data/repositories/api_todo_repository.dart';
import '../../data/repositories/firestore_todo_repository.dart';
import '../../data/repositories/mock_todo_repository.dart';
import '../../data/repositories/todo_repository.dart';
import '../../domain/models/todo_item.dart';

final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  if (useApi) {
    return ApiTodoRepository(baseUrl: apiBaseUrl);
  }
  if (useFirebase) {
    return FirestoreTodoRepository();
  }
  return MockTodoRepository();
});

final todoControllerProvider = NotifierProvider<TodoController, TodoState>(
  TodoController.new,
);

class TodoState {
  const TodoState({
    this.categories = const [],
    this.items = const [],
    this.completions = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<TodoCategory> categories;
  final List<TodoItem> items;
  final List<TodoCompletion> completions;
  final bool isLoading;
  final bool isSaving;
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

  TodoCategory? categoryById(String categoryId) {
    return categories
        .where((category) => category.id == categoryId)
        .firstOrNull;
  }

  TodoItem? itemById(String itemId) {
    return items.where((item) => item.id == itemId).firstOrNull;
  }

  int completionCountForCategory(String categoryId) {
    final itemIds = itemsForCategory(categoryId).map((item) => item.id).toSet();
    return completions
        .where((completion) => itemIds.contains(completion.itemId))
        .length;
  }

  TodoCategory? categoryForItem(String itemId) {
    final item = items.where((item) => item.id == itemId).firstOrNull;
    if (item == null) {
      return null;
    }
    return categories
        .where((category) => category.id == item.categoryId)
        .firstOrNull;
  }

  TodoState copyWith({
    List<TodoCategory>? categories,
    List<TodoItem>? items,
    List<TodoCompletion>? completions,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TodoState(
      categories: categories ?? this.categories,
      items: items ?? this.items,
      completions: completions ?? this.completions,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class TodoController extends Notifier<TodoState> {
  late final TodoRepository _repository;

  @override
  TodoState build() {
    _repository = ref.watch(todoRepositoryProvider);
    final session = ref.watch(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      return const TodoState();
    }
    Future.microtask(_loadTodos);
    return const TodoState(isLoading: true);
  }

  Future<TodoCategory?> addCategory({
    required String title,
    required String emoji,
  }) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '카테고리 이름을 입력해 주세요.');
      return null;
    }
    final trimmedEmoji = emoji.trim().isEmpty ? '🧭' : emoji.trim();

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final category = await _repository.createCategory(
        coupleId: couple.id,
        userId: user.id,
        draft: TodoCategoryDraft(title: trimmedTitle, emoji: trimmedEmoji),
      );
      state = state.copyWith(
        categories: [...state.categories, category],
        isSaving: false,
      );
      return category;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '카테고리를 저장하지 못했어요.');
      return null;
    }
  }

  Future<TodoItem?> addItem({
    required String categoryId,
    required String title,
    String note = '',
  }) async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return null;
    }

    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '세부 항목을 입력해 주세요.');
      return null;
    }

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final item = await _repository.createItem(
        coupleId: couple.id,
        userId: user.id,
        draft: TodoItemDraft(
          categoryId: categoryId,
          title: trimmedTitle,
          note: note.trim(),
        ),
      );
      state = state.copyWith(items: [...state.items, item], isSaving: false);
      return item;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '세부 항목을 저장하지 못했어요.',
      );
      return null;
    }
  }

  Future<TodoCategory?> updateCategory({
    required String categoryId,
    required String title,
    required String emoji,
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '카테고리 이름을 입력해 주세요.');
      return null;
    }
    final category = state.categoryById(categoryId);
    if (category == null) {
      state = state.copyWith(errorMessage: '카테고리를 찾을 수 없어요.');
      return null;
    }
    final updatedCategory = category.copyWith(
      title: trimmedTitle,
      emoji: emoji.trim().isEmpty ? '🧭' : emoji.trim(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _repository.updateCategory(
        coupleId: category.coupleId,
        category: updatedCategory,
      );
      state = state.copyWith(
        categories: state.categories
            .map((item) => item.id == categoryId ? saved : item)
            .toList(),
        isSaving: false,
      );
      return saved;
    } catch (_) {
      state = state.copyWith(isSaving: false, errorMessage: '카테고리를 수정하지 못했어요.');
      return null;
    }
  }

  Future<TodoItem?> updateItem({
    required String itemId,
    required String title,
    String note = '',
  }) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      state = state.copyWith(errorMessage: '세부 항목을 입력해 주세요.');
      return null;
    }
    final item = state.itemById(itemId);
    if (item == null) {
      state = state.copyWith(errorMessage: '세부 항목을 찾을 수 없어요.');
      return null;
    }
    final updatedItem = item.copyWith(
      title: trimmedTitle,
      note: note.trim(),
      updatedAt: DateTime.now(),
    );
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final saved = await _repository.updateItem(
        coupleId: item.coupleId,
        item: updatedItem,
      );
      state = state.copyWith(
        items: state.items
            .map((candidate) => candidate.id == itemId ? saved : candidate)
            .toList(),
        isSaving: false,
      );
      return saved;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '세부 항목을 수정하지 못했어요.',
      );
      return null;
    }
  }

  Future<TodoCompletion?> addCompletion({
    required String itemId,
    required DateTime completedAt,
    required String calendarEventId,
    String memo = '',
  }) async {
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

    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final completion = await _repository.createCompletion(
        coupleId: couple.id,
        userId: user.id,
        draft: TodoCompletionDraft(
          itemId: itemId,
          completedAt: completedAt,
          calendarEventId: calendarEventId,
          memo: memo.trim(),
        ),
      );
      state = state.copyWith(
        completions: [...state.completions, completion],
        isSaving: false,
      );
      return completion;
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '달성 기록을 저장하지 못했어요.',
      );
      return null;
    }
  }

  Future<void> removeCompletion(String completionId) async {
    final session = ref.read(sessionControllerProvider);
    final couple = session.currentCouple;
    final user = session.currentUser;
    if (couple == null || user == null) {
      state = state.copyWith(errorMessage: '커플 공간을 먼저 연결해 주세요.');
      return;
    }
    final exists = state.completions.any(
      (completion) => completion.id == completionId,
    );
    if (!exists) {
      return;
    }
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.deleteCompletion(
        coupleId: couple.id,
        userId: user.id,
        completionId: completionId,
      );
      state = state.copyWith(
        completions: state.completions
            .where((completion) => completion.id != completionId)
            .toList(),
        isSaving: false,
      );
    } catch (_) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: '달성 기록을 삭제하지 못했어요.',
      );
    }
  }

  Future<void> refreshTodos() {
    return _loadTodos();
  }

  Future<void> _loadTodos() async {
    final session = ref.read(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;
    if (user == null || couple == null) {
      state = const TodoState();
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _repository.fetchTodos(
        coupleId: couple.id,
        userId: user.id,
      );
      state = state.copyWith(
        categories: snapshot.categories,
        items: snapshot.items,
        completions: snapshot.completions,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: '버킷리스트를 불러오지 못했어요.',
      );
    }
  }
}
