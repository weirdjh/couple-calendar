class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.coupleId,
    required this.title,
    required this.startAt,
    required this.endAt,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.isAllDay = false,
    this.memo = '',
    this.colorValue = 0xFF4D7C8A,
    this.photos = const [],
    this.reminders = const [],
    this.linkedItems = const [],
    this.deletedAt,
  });

  final String id;
  final String coupleId;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final bool isAllDay;
  final String memo;
  final int colorValue;
  final List<EventPhoto> photos;
  final List<Reminder> reminders;
  final List<LinkedItem> linkedItems;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  CalendarEvent copyWith({
    String? id,
    String? coupleId,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    bool? isAllDay,
    String? memo,
    int? colorValue,
    List<EventPhoto>? photos,
    List<Reminder>? reminders,
    List<LinkedItem>? linkedItems,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      coupleId: coupleId ?? this.coupleId,
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isAllDay: isAllDay ?? this.isAllDay,
      memo: memo ?? this.memo,
      colorValue: colorValue ?? this.colorValue,
      photos: photos ?? this.photos,
      reminders: reminders ?? this.reminders,
      linkedItems: linkedItems ?? this.linkedItems,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}

class EventPhoto {
  const EventPhoto({
    required this.id,
    required this.storagePath,
    required this.downloadUrl,
    required this.uploadedBy,
    required this.createdAt,
  });

  final String id;
  final String storagePath;
  final String downloadUrl;
  final String uploadedBy;
  final DateTime createdAt;
}

class Reminder {
  const Reminder({
    required this.id,
    required this.eventId,
    required this.remindAt,
    required this.offsetMinutes,
    required this.createdAt,
    required this.updatedAt,
    this.enabled = true,
  });

  final String id;
  final String eventId;
  final DateTime remindAt;
  final int offsetMinutes;
  final bool enabled;
  final DateTime createdAt;
  final DateTime updatedAt;
}

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
  });

  final LinkedItemType type;
  final String targetId;
  final String? targetPath;
  final String title;
  final String? subtitle;
  final DateTime? date;
  final String? thumbnailUrl;
  final String? preview;
  final DateTime createdAt;
}

enum LinkedItemType { todo, dateRecord, conflict, anniversary, review, place }
