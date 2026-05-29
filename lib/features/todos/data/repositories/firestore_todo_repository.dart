import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/models/todo_item.dart';
import 'todo_repository.dart';

class FirestoreTodoRepository implements TodoRepository {
  FirestoreTodoRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<TodoSnapshot> fetchTodos({
    required String coupleId,
    required String userId,
  }) async {
    final categoriesSnapshot = await _categoriesCollection(
      coupleId,
    ).where(TodoFields.deletedAt, isNull: true).get();
    final itemsSnapshot = await _itemsCollection(
      coupleId,
    ).where(TodoFields.deletedAt, isNull: true).get();
    final completionsSnapshot = await _completionsCollection(
      coupleId,
    ).where(TodoFields.deletedAt, isNull: true).get();

    final categories =
        categoriesSnapshot.docs.map(_TodoMapper.categoryFromDocument).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final items = itemsSnapshot.docs.map(_TodoMapper.itemFromDocument).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final completions =
        completionsSnapshot.docs
            .map(_TodoMapper.completionFromDocument)
            .toList()
          ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return TodoSnapshot(
      categories: categories,
      items: items,
      completions: completions,
    );
  }

  @override
  Future<TodoCategory> createCategory({
    required String coupleId,
    required String userId,
    required TodoCategoryDraft draft,
  }) async {
    final doc = _categoriesCollection(coupleId).doc();
    final now = DateTime.now().toUtc();
    final category = TodoCategory(
      id: doc.id,
      coupleId: coupleId,
      title: draft.title,
      emoji: draft.emoji,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(_TodoMapper.categoryToMap(category));
    return category;
  }

  @override
  Future<TodoCategory> updateCategory({
    required String coupleId,
    required TodoCategory category,
  }) async {
    final updated = category.copyWith(updatedAt: DateTime.now().toUtc());
    await _categoriesCollection(
      coupleId,
    ).doc(category.id).set(_TodoMapper.categoryToMap(updated));
    return updated;
  }

  @override
  Future<TodoItem> createItem({
    required String coupleId,
    required String userId,
    required TodoItemDraft draft,
  }) async {
    final doc = _itemsCollection(coupleId).doc();
    final now = DateTime.now().toUtc();
    final item = TodoItem(
      id: doc.id,
      coupleId: coupleId,
      categoryId: draft.categoryId,
      title: draft.title,
      note: draft.note,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );
    await doc.set(_TodoMapper.itemToMap(item));
    return item;
  }

  @override
  Future<TodoItem> updateItem({
    required String coupleId,
    required TodoItem item,
  }) async {
    final updated = item.copyWith(updatedAt: DateTime.now().toUtc());
    await _itemsCollection(
      coupleId,
    ).doc(item.id).set(_TodoMapper.itemToMap(updated));
    return updated;
  }

  @override
  Future<TodoCompletion> createCompletion({
    required String coupleId,
    required String userId,
    required TodoCompletionDraft draft,
  }) async {
    final doc = _completionsCollection(coupleId).doc();
    final completion = TodoCompletion(
      id: doc.id,
      coupleId: coupleId,
      itemId: draft.itemId,
      completedAt: draft.completedAt,
      completedBy: userId,
      calendarEventId: draft.calendarEventId,
      memo: draft.memo,
      createdAt: DateTime.now().toUtc(),
    );
    await doc.set(_TodoMapper.completionToMap(completion));
    return completion;
  }

  @override
  Future<void> deleteCompletion({
    required String coupleId,
    required String userId,
    required String completionId,
  }) async {
    await _completionsCollection(coupleId).doc(completionId).update({
      TodoFields.deletedAt: Timestamp.fromDate(DateTime.now().toUtc()),
    });
  }

  CollectionReference<Map<String, dynamic>> _categoriesCollection(
    String coupleId,
  ) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('todoCategories');
  }

  CollectionReference<Map<String, dynamic>> _itemsCollection(String coupleId) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('todoItems');
  }

  CollectionReference<Map<String, dynamic>> _completionsCollection(
    String coupleId,
  ) {
    return _firestore
        .collection('couples')
        .doc(coupleId)
        .collection('todoCompletions');
  }
}

class TodoFields {
  static const coupleId = 'coupleId';
  static const title = 'title';
  static const emoji = 'emoji';
  static const categoryId = 'categoryId';
  static const note = 'note';
  static const itemId = 'itemId';
  static const completedAt = 'completedAt';
  static const completedBy = 'completedBy';
  static const calendarEventId = 'calendarEventId';
  static const memo = 'memo';
  static const createdBy = 'createdBy';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const deletedAt = 'deletedAt';
}

class _TodoMapper {
  static TodoCategory categoryFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TodoCategory(
      id: doc.id,
      coupleId: data[TodoFields.coupleId] as String? ?? '',
      title: data[TodoFields.title] as String? ?? '',
      emoji: data[TodoFields.emoji] as String? ?? '🧭',
      createdBy: data[TodoFields.createdBy] as String? ?? '',
      createdAt: _readDate(data[TodoFields.createdAt]),
      updatedAt: _readDate(data[TodoFields.updatedAt]),
    );
  }

  static Map<String, dynamic> categoryToMap(TodoCategory category) {
    return {
      TodoFields.coupleId: category.coupleId,
      TodoFields.title: category.title,
      TodoFields.emoji: category.emoji,
      TodoFields.createdBy: category.createdBy,
      TodoFields.createdAt: Timestamp.fromDate(category.createdAt.toUtc()),
      TodoFields.updatedAt: Timestamp.fromDate(category.updatedAt.toUtc()),
      TodoFields.deletedAt: null,
    };
  }

  static TodoItem itemFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TodoItem(
      id: doc.id,
      coupleId: data[TodoFields.coupleId] as String? ?? '',
      categoryId: data[TodoFields.categoryId] as String? ?? '',
      title: data[TodoFields.title] as String? ?? '',
      note: data[TodoFields.note] as String? ?? '',
      createdBy: data[TodoFields.createdBy] as String? ?? '',
      createdAt: _readDate(data[TodoFields.createdAt]),
      updatedAt: _readDate(data[TodoFields.updatedAt]),
    );
  }

  static Map<String, dynamic> itemToMap(TodoItem item) {
    return {
      TodoFields.coupleId: item.coupleId,
      TodoFields.categoryId: item.categoryId,
      TodoFields.title: item.title,
      TodoFields.note: item.note,
      TodoFields.createdBy: item.createdBy,
      TodoFields.createdAt: Timestamp.fromDate(item.createdAt.toUtc()),
      TodoFields.updatedAt: Timestamp.fromDate(item.updatedAt.toUtc()),
      TodoFields.deletedAt: null,
    };
  }

  static TodoCompletion completionFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return TodoCompletion(
      id: doc.id,
      coupleId: data[TodoFields.coupleId] as String? ?? '',
      itemId: data[TodoFields.itemId] as String? ?? '',
      completedAt: _readDate(data[TodoFields.completedAt]),
      completedBy: data[TodoFields.completedBy] as String? ?? '',
      calendarEventId: data[TodoFields.calendarEventId] as String? ?? '',
      memo: data[TodoFields.memo] as String? ?? '',
      createdAt: _readDate(data[TodoFields.createdAt]),
    );
  }

  static Map<String, dynamic> completionToMap(TodoCompletion completion) {
    return {
      TodoFields.coupleId: completion.coupleId,
      TodoFields.itemId: completion.itemId,
      TodoFields.completedAt: Timestamp.fromDate(
        completion.completedAt.toUtc(),
      ),
      TodoFields.completedBy: completion.completedBy,
      TodoFields.calendarEventId: completion.calendarEventId,
      TodoFields.memo: completion.memo,
      TodoFields.createdAt: Timestamp.fromDate(completion.createdAt.toUtc()),
      TodoFields.deletedAt: null,
    };
  }

  static DateTime _readDate(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
