class LinkedItem {
  const LinkedItem({
    required this.type,
    required this.targetId,
    required this.title,
    required this.createdAt,
    this.targetPath,
    this.subtitle,
    this.date,
    this.thumbnailUrl,
    this.preview,
    this.emoji,
  });

  final LinkedItemType type;
  final String targetId;
  final String? targetPath;
  final String title;
  final String? subtitle;
  final DateTime? date;
  final String? thumbnailUrl;
  final String? preview;
  final String? emoji;
  final DateTime createdAt;

  LinkedItem copyWith({
    LinkedItemType? type,
    String? targetId,
    String? targetPath,
    String? title,
    String? subtitle,
    DateTime? date,
    String? thumbnailUrl,
    String? preview,
    String? emoji,
    DateTime? createdAt,
  }) {
    return LinkedItem(
      type: type ?? this.type,
      targetId: targetId ?? this.targetId,
      targetPath: targetPath ?? this.targetPath,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      date: date ?? this.date,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      preview: preview ?? this.preview,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum LinkedItemType { todo, dateRecord, conflict, anniversary, review, place }
