import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/time/calendar_date_utils.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/event_input.dart';
import 'calendar_event_repository.dart';
import 'mock_calendar_event_repository.dart';

class FirestoreCalendarEventRepository implements CalendarEventRepository {
  FirestoreCalendarEventRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required String coupleId,
    required String userId,
    required DateRange visibleRange,
  }) async {
    final snapshot = await _eventsCollection(coupleId)
        .where(CalendarEventFields.deletedAt, isNull: true)
        .where(
          CalendarEventFields.rangeStartAt,
          isLessThan: Timestamp.fromDate(visibleRange.end.toUtc()),
        )
        .get();

    final events =
        snapshot.docs
            .map((doc) => _CalendarEventMapper.fromDocument(doc))
            .where(
              (event) =>
                  !event.endAt.toUtc().isBefore(visibleRange.start.toUtc()),
            )
            .toList()
          ..sort(compareCalendarEvents);
    return events;
  }

  @override
  Future<CalendarEvent> createEvent({
    required String coupleId,
    required String userId,
    required EventInput input,
  }) async {
    final doc = _eventsCollection(coupleId).doc();
    final now = DateTime.now().toUtc();
    final reminders = _buildReminders(input, doc.id, now);
    final photos = _buildMockPhotos(input, coupleId, doc.id, userId, now);
    final event = CalendarEvent(
      id: doc.id,
      coupleId: coupleId,
      title: input.title.trim(),
      startAt: input.startAt,
      endAt: input.endAt,
      isAllDay: input.isAllDay,
      memo: input.memo.trim(),
      kind: input.kind,
      colorValue: input.colorValue,
      ownership: input.ownership,
      ownerUserId: userId,
      photos: photos,
      reminders: reminders,
      linkedItems: input.linkedItems,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    );

    await doc.set(_CalendarEventMapper.toMap(event));
    return event;
  }

  @override
  Future<void> deleteEvent({
    required String coupleId,
    required String eventId,
    required String userId,
  }) async {
    final now = DateTime.now().toUtc();
    await _eventsCollection(coupleId).doc(eventId).update({
      CalendarEventFields.deletedAt: Timestamp.fromDate(now),
      CalendarEventFields.updatedAt: Timestamp.fromDate(now),
    });
  }

  @override
  Future<CalendarEvent> updateEvent({
    required String coupleId,
    required String userId,
    required CalendarEvent event,
  }) async {
    final updated = event.copyWith(updatedAt: DateTime.now().toUtc());
    await _eventsCollection(
      coupleId,
    ).doc(event.id).set(_CalendarEventMapper.toMap(updated));
    return updated;
  }

  CollectionReference<Map<String, dynamic>> _eventsCollection(String coupleId) {
    return _firestore.collection('couples').doc(coupleId).collection('events');
  }
}

List<Reminder> _buildReminders(EventInput input, String eventId, DateTime now) {
  final offset = input.reminderOffsetMinutes;
  if (offset == null) {
    return const [];
  }
  return [
    Reminder(
      id: 'reminder-$eventId',
      eventId: eventId,
      remindAt: input.startAt.subtract(Duration(minutes: offset)),
      offsetMinutes: offset,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}

List<EventPhoto> _buildMockPhotos(
  EventInput input,
  String coupleId,
  String eventId,
  String userId,
  DateTime now,
) {
  return input.photoLabels.indexed.map((entry) {
    final (index, label) = entry;
    return EventPhoto(
      id: 'photo-$eventId-$index',
      storagePath: 'pending/$coupleId/events/$eventId/$index',
      downloadUrl: label,
      uploadedBy: userId,
      createdAt: now,
    );
  }).toList();
}

class CalendarEventFields {
  static const id = 'id';
  static const coupleId = 'coupleId';
  static const title = 'title';
  static const startAt = 'startAt';
  static const endAt = 'endAt';
  static const rangeStartAt = 'rangeStartAt';
  static const rangeEndAt = 'rangeEndAt';
  static const isAllDay = 'isAllDay';
  static const memo = 'memo';
  static const kind = 'kind';
  static const colorValue = 'colorValue';
  static const ownership = 'ownership';
  static const ownerUserId = 'ownerUserId';
  static const watcherUserIds = 'watcherUserIds';
  static const photos = 'photos';
  static const reminders = 'reminders';
  static const linkedItems = 'linkedItems';
  static const createdBy = 'createdBy';
  static const createdAt = 'createdAt';
  static const updatedAt = 'updatedAt';
  static const deletedAt = 'deletedAt';
}

class _CalendarEventMapper {
  static CalendarEvent fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CalendarEvent(
      id: doc.id,
      coupleId: data[CalendarEventFields.coupleId] as String,
      title: data[CalendarEventFields.title] as String? ?? '',
      startAt: _readDate(data[CalendarEventFields.startAt]),
      endAt: _readDate(data[CalendarEventFields.endAt]),
      isAllDay: data[CalendarEventFields.isAllDay] as bool? ?? false,
      memo: data[CalendarEventFields.memo] as String? ?? '',
      kind: _readKind(data[CalendarEventFields.kind]),
      colorValue: data[CalendarEventFields.colorValue] as int? ?? 0xFF4D7C8A,
      ownership: _readOwnership(data[CalendarEventFields.ownership]),
      ownerUserId: data[CalendarEventFields.ownerUserId] as String? ?? '',
      watcherUserIds: _readStringList(data[CalendarEventFields.watcherUserIds]),
      photos: _readPhotos(data[CalendarEventFields.photos]),
      reminders: _readReminders(data[CalendarEventFields.reminders]),
      linkedItems: _readLinkedItems(data[CalendarEventFields.linkedItems]),
      createdBy: data[CalendarEventFields.createdBy] as String? ?? '',
      createdAt: _readDate(data[CalendarEventFields.createdAt]),
      updatedAt: _readDate(data[CalendarEventFields.updatedAt]),
      deletedAt: _readNullableDate(data[CalendarEventFields.deletedAt]),
    );
  }

  static Map<String, dynamic> toMap(CalendarEvent event) {
    return {
      CalendarEventFields.coupleId: event.coupleId,
      CalendarEventFields.title: event.title,
      CalendarEventFields.startAt: Timestamp.fromDate(event.startAt.toUtc()),
      CalendarEventFields.endAt: Timestamp.fromDate(event.endAt.toUtc()),
      CalendarEventFields.rangeStartAt: Timestamp.fromDate(
        event.startAt.toUtc(),
      ),
      CalendarEventFields.rangeEndAt: Timestamp.fromDate(event.endAt.toUtc()),
      CalendarEventFields.isAllDay: event.isAllDay,
      CalendarEventFields.memo: event.memo,
      CalendarEventFields.kind: event.kind.name,
      CalendarEventFields.colorValue: event.colorValue,
      CalendarEventFields.ownership: event.ownership.name,
      CalendarEventFields.ownerUserId: event.effectiveOwnerUserId,
      CalendarEventFields.watcherUserIds: event.watcherUserIds,
      CalendarEventFields.photos: event.photos.map(_photoToMap).toList(),
      CalendarEventFields.reminders: event.reminders
          .map(_reminderToMap)
          .toList(),
      CalendarEventFields.linkedItems: event.linkedItems
          .map(_linkedItemToMap)
          .toList(),
      CalendarEventFields.createdBy: event.createdBy,
      CalendarEventFields.createdAt: Timestamp.fromDate(
        event.createdAt.toUtc(),
      ),
      CalendarEventFields.updatedAt: Timestamp.fromDate(
        event.updatedAt.toUtc(),
      ),
      CalendarEventFields.deletedAt: event.deletedAt == null
          ? null
          : Timestamp.fromDate(event.deletedAt!.toUtc()),
    };
  }

  static DateTime _readDate(Object? value) {
    return _readNullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _readNullableDate(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }

  static EventOwnership _readOwnership(Object? value) {
    return EventOwnership.values.firstWhere(
      (ownership) => ownership.name == value,
      orElse: () => EventOwnership.personal,
    );
  }

  static CalendarEventKind _readKind(Object? value) {
    return CalendarEventKind.values.firstWhere(
      (kind) => kind.name == value,
      orElse: () => CalendarEventKind.schedule,
    );
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList();
  }

  static Map<String, dynamic> _photoToMap(EventPhoto photo) {
    return {
      'id': photo.id,
      'storagePath': photo.storagePath,
      'downloadUrl': photo.downloadUrl,
      'uploadedBy': photo.uploadedBy,
      'createdAt': Timestamp.fromDate(photo.createdAt.toUtc()),
    };
  }

  static List<EventPhoto> _readPhotos(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map<String, dynamic>>().map((data) {
      return EventPhoto(
        id: data['id'] as String? ?? '',
        storagePath: data['storagePath'] as String? ?? '',
        downloadUrl: data['downloadUrl'] as String? ?? '',
        uploadedBy: data['uploadedBy'] as String? ?? '',
        createdAt: _readDate(data['createdAt']),
      );
    }).toList();
  }

  static Map<String, dynamic> _reminderToMap(Reminder reminder) {
    return {
      'id': reminder.id,
      'eventId': reminder.eventId,
      'remindAt': Timestamp.fromDate(reminder.remindAt.toUtc()),
      'offsetMinutes': reminder.offsetMinutes,
      'enabled': reminder.enabled,
      'createdAt': Timestamp.fromDate(reminder.createdAt.toUtc()),
      'updatedAt': Timestamp.fromDate(reminder.updatedAt.toUtc()),
    };
  }

  static List<Reminder> _readReminders(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map<String, dynamic>>().map((data) {
      return Reminder(
        id: data['id'] as String? ?? '',
        eventId: data['eventId'] as String? ?? '',
        remindAt: _readDate(data['remindAt']),
        offsetMinutes: data['offsetMinutes'] as int? ?? 0,
        enabled: data['enabled'] as bool? ?? true,
        createdAt: _readDate(data['createdAt']),
        updatedAt: _readDate(data['updatedAt']),
      );
    }).toList();
  }

  static Map<String, dynamic> _linkedItemToMap(LinkedItem item) {
    return {
      'type': item.type.name,
      'targetId': item.targetId,
      'targetPath': item.targetPath,
      'title': item.title,
      'subtitle': item.subtitle,
      'date': item.date == null ? null : Timestamp.fromDate(item.date!.toUtc()),
      'thumbnailUrl': item.thumbnailUrl,
      'preview': item.preview,
      'emoji': item.emoji,
      'createdAt': Timestamp.fromDate(item.createdAt.toUtc()),
    };
  }

  static List<LinkedItem> _readLinkedItems(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map<String, dynamic>>().map((data) {
      return LinkedItem(
        type: _readLinkedItemType(data['type']),
        targetId: data['targetId'] as String? ?? '',
        targetPath: data['targetPath'] as String?,
        title: data['title'] as String? ?? '',
        subtitle: data['subtitle'] as String?,
        date: _readNullableDate(data['date']),
        thumbnailUrl: data['thumbnailUrl'] as String?,
        preview: data['preview'] as String?,
        emoji: data['emoji'] as String?,
        createdAt: _readDate(data['createdAt']),
      );
    }).toList();
  }

  static LinkedItemType _readLinkedItemType(Object? value) {
    return LinkedItemType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => LinkedItemType.todo,
    );
  }
}
