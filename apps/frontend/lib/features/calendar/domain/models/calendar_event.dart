import '../../../links/domain/models/linked_item.dart';

export '../../../links/domain/models/linked_item.dart';

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
    this.kind = CalendarEventKind.schedule,
    this.colorValue = 0xFF4D7C8A,
    this.ownership = EventOwnership.personal,
    this.ownerUserId = '',
    this.watcherUserIds = const [],
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
  final CalendarEventKind kind;
  final int colorValue;
  final EventOwnership ownership;
  final String ownerUserId;
  final List<String> watcherUserIds;
  final List<EventPhoto> photos;
  final List<Reminder> reminders;
  final List<LinkedItem> linkedItems;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  String get effectiveOwnerUserId =>
      ownerUserId.isEmpty ? createdBy : ownerUserId;

  bool get isShared => ownership == EventOwnership.shared;

  bool isOwnedBy(String userId) =>
      ownership == EventOwnership.personal && effectiveOwnerUserId == userId;

  bool isPartnerOwnedFor(String userId) =>
      ownership == EventOwnership.personal && effectiveOwnerUserId != userId;

  bool isWatchedBy(String userId) => watcherUserIds.contains(userId);

  bool canEditFor(String userId) => isShared || isOwnedBy(userId);

  String ownershipLabelFor(String userId) {
    if (isShared) {
      return '우리 일정';
    }
    return isOwnedBy(userId) ? '내 일정' : '상대 일정';
  }

  CalendarEvent copyWith({
    String? id,
    String? coupleId,
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    bool? isAllDay,
    String? memo,
    CalendarEventKind? kind,
    int? colorValue,
    EventOwnership? ownership,
    String? ownerUserId,
    List<String>? watcherUserIds,
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
      kind: kind ?? this.kind,
      colorValue: colorValue ?? this.colorValue,
      ownership: ownership ?? this.ownership,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      watcherUserIds: watcherUserIds ?? this.watcherUserIds,
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

enum EventOwnership { personal, shared }

enum CalendarEventKind { schedule, date }

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
