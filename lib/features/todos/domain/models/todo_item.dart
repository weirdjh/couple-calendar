class TodoCategory {
  const TodoCategory({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String coupleId;
  final String title;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
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
}
