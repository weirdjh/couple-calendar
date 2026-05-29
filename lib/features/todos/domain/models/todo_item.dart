class TodoCategory {
  const TodoCategory({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.emoji = '🧭',
  });

  final String id;
  final String coupleId;
  final String title;
  final String emoji;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TodoCategory copyWith({
    String? id,
    String? coupleId,
    String? title,
    String? emoji,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoCategory(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TodoItem {
  const TodoItem({
    required this.id,
    required this.coupleId,
    required this.categoryId,
    required this.title,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.note = '',
  });

  final String id;
  final String coupleId;
  final String categoryId;
  final String title;
  final String note;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  TodoItem copyWith({
    String? id,
    String? coupleId,
    String? categoryId,
    String? title,
    String? note,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TodoItem(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      note: note ?? this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TodoCompletion {
  const TodoCompletion({
    required this.id,
    required this.coupleId,
    required this.itemId,
    required this.completedAt,
    required this.completedBy,
    required this.calendarEventId,
    required this.createdAt,
    this.memo = '',
  });

  final String id;
  final String coupleId;
  final String itemId;
  final DateTime completedAt;
  final String completedBy;
  final String calendarEventId;
  final String memo;
  final DateTime createdAt;

  TodoCompletion copyWith({
    String? id,
    String? coupleId,
    String? itemId,
    DateTime? completedAt,
    String? completedBy,
    String? calendarEventId,
    String? memo,
    DateTime? createdAt,
  }) {
    return TodoCompletion(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      itemId: itemId ?? this.itemId,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      calendarEventId: calendarEventId ?? this.calendarEventId,
      memo: memo ?? this.memo,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
