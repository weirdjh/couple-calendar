import 'package:http/http.dart' as http;

import '../../../../core/api/api_client.dart';
import '../../domain/models/todo_item.dart';
import 'todo_repository.dart';

class ApiTodoRepository implements TodoRepository {
  ApiTodoRepository({required String baseUrl, http.Client? client})
    : _api = ApiClient(baseUrl: baseUrl, client: client);

  final ApiClient _api;

  @override
  Future<TodoSnapshot> fetchTodos({
    required String coupleId,
    required String userId,
  }) async {
    final json =
        await _api.getJson(
              '/v1/couples/$coupleId/todos',
              credential: ApiCredential.devUser(userId),
            )
            as Map<String, dynamic>;
    return TodoSnapshot(
      categories: _readList(json['categories'], _categoryFromJson),
      items: _readList(json['items'], _itemFromJson),
      completions: _readList(json['completions'], _completionFromJson),
    );
  }

  @override
  Future<TodoCategory> createCategory({
    required String coupleId,
    required String userId,
    required TodoCategoryDraft draft,
  }) async {
    final json =
        await _api.postJson(
              '/v1/couples/$coupleId/todos/categories',
              credential: ApiCredential.devUser(userId),
              body: {
                'draft': {'title': draft.title, 'emoji': draft.emoji},
              },
            )
            as Map<String, dynamic>;
    return _categoryFromJson(json);
  }

  @override
  Future<TodoCategory> updateCategory({
    required String coupleId,
    required TodoCategory category,
  }) async {
    final json =
        await _api.putJson(
              '/v1/couples/$coupleId/todos/categories/${category.id}',
              credential: ApiCredential.devUser(category.createdBy),
              body: {'category': _categoryToJson(category)},
            )
            as Map<String, dynamic>;
    return _categoryFromJson(json);
  }

  @override
  Future<TodoItem> createItem({
    required String coupleId,
    required String userId,
    required TodoItemDraft draft,
  }) async {
    final json =
        await _api.postJson(
              '/v1/couples/$coupleId/todos/items',
              credential: ApiCredential.devUser(userId),
              body: {
                'draft': {
                  'categoryId': draft.categoryId,
                  'title': draft.title,
                  'note': draft.note,
                },
              },
            )
            as Map<String, dynamic>;
    return _itemFromJson(json);
  }

  @override
  Future<TodoItem> updateItem({
    required String coupleId,
    required TodoItem item,
  }) async {
    final json =
        await _api.putJson(
              '/v1/couples/$coupleId/todos/items/${item.id}',
              credential: ApiCredential.devUser(item.createdBy),
              body: {'item': _itemToJson(item)},
            )
            as Map<String, dynamic>;
    return _itemFromJson(json);
  }

  @override
  Future<TodoCompletion> createCompletion({
    required String coupleId,
    required String userId,
    required TodoCompletionDraft draft,
  }) async {
    final json =
        await _api.postJson(
              '/v1/couples/$coupleId/todos/completions',
              credential: ApiCredential.devUser(userId),
              body: {
                'draft': {
                  'itemId': draft.itemId,
                  'completedAt': draft.completedAt.toUtc().toIso8601String(),
                  'calendarEventId': draft.calendarEventId,
                  'memo': draft.memo,
                },
              },
            )
            as Map<String, dynamic>;
    return _completionFromJson(json);
  }

  @override
  Future<void> deleteCompletion({
    required String coupleId,
    required String userId,
    required String completionId,
  }) async {
    await _api.deleteJson(
      '/v1/couples/$coupleId/todos/completions/$completionId',
      credential: ApiCredential.devUser(userId),
    );
  }
}

List<T> _readList<T>(Object? value, T Function(Map<String, dynamic>) mapper) {
  if (value is! List) return const [];
  return value.whereType<Map<String, dynamic>>().map(mapper).toList();
}

DateTime _readDate(Object? value) {
  if (value is! String) return DateTime.fromMillisecondsSinceEpoch(0);
  return DateTime.tryParse(value)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

TodoCategory _categoryFromJson(Map<String, dynamic> json) => TodoCategory(
  id: json['id'] as String? ?? '',
  coupleId: json['coupleId'] as String? ?? '',
  title: json['title'] as String? ?? '',
  emoji: json['emoji'] as String? ?? '🧭',
  createdBy: json['createdBy'] as String? ?? '',
  createdAt: _readDate(json['createdAt']),
  updatedAt: _readDate(json['updatedAt']),
);

Map<String, dynamic> _categoryToJson(TodoCategory category) => {
  'id': category.id,
  'coupleId': category.coupleId,
  'title': category.title,
  'emoji': category.emoji,
  'createdBy': category.createdBy,
  'createdAt': category.createdAt.toUtc().toIso8601String(),
  'updatedAt': category.updatedAt.toUtc().toIso8601String(),
};

TodoItem _itemFromJson(Map<String, dynamic> json) => TodoItem(
  id: json['id'] as String? ?? '',
  coupleId: json['coupleId'] as String? ?? '',
  categoryId: json['categoryId'] as String? ?? '',
  title: json['title'] as String? ?? '',
  note: json['note'] as String? ?? '',
  createdBy: json['createdBy'] as String? ?? '',
  createdAt: _readDate(json['createdAt']),
  updatedAt: _readDate(json['updatedAt']),
);

Map<String, dynamic> _itemToJson(TodoItem item) => {
  'id': item.id,
  'coupleId': item.coupleId,
  'categoryId': item.categoryId,
  'title': item.title,
  'note': item.note,
  'createdBy': item.createdBy,
  'createdAt': item.createdAt.toUtc().toIso8601String(),
  'updatedAt': item.updatedAt.toUtc().toIso8601String(),
};

TodoCompletion _completionFromJson(Map<String, dynamic> json) => TodoCompletion(
  id: json['id'] as String? ?? '',
  coupleId: json['coupleId'] as String? ?? '',
  itemId: json['itemId'] as String? ?? '',
  completedAt: _readDate(json['completedAt']),
  completedBy: json['completedBy'] as String? ?? '',
  calendarEventId: json['calendarEventId'] as String? ?? '',
  memo: json['memo'] as String? ?? '',
  createdAt: _readDate(json['createdAt']),
);
