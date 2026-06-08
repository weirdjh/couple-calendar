import 'package:http/http.dart' as http;

import '../../../../core/api/api_client.dart';
import '../../../../core/time/calendar_date_utils.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/event_input.dart';
import 'calendar_event_repository.dart';
import 'mock_calendar_event_repository.dart';

class ApiCalendarEventRepository implements CalendarEventRepository {
  ApiCalendarEventRepository({required String baseUrl, http.Client? client})
    : _api = ApiClient(baseUrl: baseUrl, client: client);

  final ApiClient _api;

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required String coupleId,
    required String userId,
    required DateRange visibleRange,
  }) async {
    final decoded = await _api.getJson(
      '/v1/couples/$coupleId/events',
      credential: ApiCredential.devUser(userId),
      queryParameters: {
        'startAt': visibleRange.start.toUtc().toIso8601String(),
        'endAt': visibleRange.end.toUtc().toIso8601String(),
      },
    );
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(_CalendarEventApiMapper.fromJson)
        .toList()
      ..sort(compareCalendarEvents);
  }

  @override
  Future<CalendarEvent> createEvent({
    required String coupleId,
    required String userId,
    required EventInput input,
  }) async {
    final decoded = await _api.postJson(
      '/v1/couples/$coupleId/events',
      credential: ApiCredential.devUser(userId),
      body: _CalendarEventApiMapper.inputToJson(input),
    );
    return _CalendarEventApiMapper.fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<CalendarEvent> updateEvent({
    required String coupleId,
    required String userId,
    required CalendarEvent event,
  }) async {
    final decoded = await _api.putJson(
      '/v1/couples/$coupleId/events/${event.id}',
      credential: ApiCredential.devUser(userId),
      body: _CalendarEventApiMapper.eventToMutationJson(event),
    );
    return _CalendarEventApiMapper.fromJson(decoded as Map<String, dynamic>);
  }

  @override
  Future<void> deleteEvent({
    required String coupleId,
    required String eventId,
    required String userId,
  }) async {
    await _api.deleteJson(
      '/v1/couples/$coupleId/events/$eventId',
      credential: ApiCredential.devUser(userId),
    );
  }
}

class _CalendarEventApiMapper {
  static CalendarEvent fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] as String? ?? '',
      coupleId: json['coupleId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startAt: _readDate(json['startAt']),
      endAt: _readDate(json['endAt']),
      isAllDay: json['isAllDay'] as bool? ?? false,
      memo: json['memo'] as String? ?? '',
      kind: _readKind(json['kind']),
      colorValue: json['colorValue'] as int? ?? 0xFF4169E1,
      ownership: _readOwnership(json['ownership']),
      ownerUserId: json['ownerUserId'] as String? ?? '',
      watcherUserIds: _readStringList(json['watcherUserIds']),
      reminders: _readReminders(json['reminders']),
      linkedItems: _readLinkedItems(json['linkedItems']),
      createdBy: json['createdBy'] as String? ?? '',
      createdAt: _readDate(json['createdAt']),
      updatedAt: _readDate(json['updatedAt']),
      deletedAt: _readNullableDate(json['deletedAt']),
    );
  }

  static Map<String, dynamic> inputToJson(EventInput input) {
    return {
      'title': input.title,
      'startAt': input.startAt.toUtc().toIso8601String(),
      'endAt': input.endAt.toUtc().toIso8601String(),
      'isAllDay': input.isAllDay,
      'memo': input.memo,
      'kind': input.kind.name,
      'colorValue': input.colorValue,
      'ownership': input.ownership.name,
      'linkedItems': input.linkedItems.map(_linkedItemToJson).toList(),
      'reminderOffsetMinutes': input.reminderOffsetMinutes,
    };
  }

  static Map<String, dynamic> eventToMutationJson(CalendarEvent event) {
    return {
      'title': event.title,
      'startAt': event.startAt.toUtc().toIso8601String(),
      'endAt': event.endAt.toUtc().toIso8601String(),
      'isAllDay': event.isAllDay,
      'memo': event.memo,
      'kind': event.kind.name,
      'colorValue': event.colorValue,
      'ownership': event.ownership.name,
      'watcherUserIds': event.watcherUserIds,
      'linkedItems': event.linkedItems.map(_linkedItemToJson).toList(),
      'reminderOffsetMinutes': event.reminders.isEmpty
          ? null
          : event.reminders.first.offsetMinutes,
    };
  }

  static DateTime _readDate(Object? value) {
    return _readNullableDate(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }

  static DateTime? _readNullableDate(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
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

  static List<Reminder> _readReminders(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map<String, dynamic>>().map((json) {
      return Reminder(
        id: json['id'] as String? ?? '',
        eventId: json['eventId'] as String? ?? '',
        remindAt: _readDate(json['remindAt']),
        offsetMinutes: json['offsetMinutes'] as int? ?? 0,
        enabled: json['enabled'] as bool? ?? true,
        createdAt: _readDate(json['createdAt']),
        updatedAt: _readDate(json['updatedAt']),
      );
    }).toList();
  }

  static List<LinkedItem> _readLinkedItems(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<Map<String, dynamic>>().map((json) {
      return LinkedItem(
        type: _readLinkedItemType(json['type']),
        targetId: json['targetId'] as String? ?? '',
        targetPath: json['targetPath'] as String?,
        title: json['title'] as String? ?? '',
        subtitle: json['subtitle'] as String?,
        date: _readNullableDate(json['date']),
        thumbnailUrl: json['thumbnailUrl'] as String?,
        preview: json['preview'] as String?,
        emoji: json['emoji'] as String?,
        createdAt: _readDate(json['createdAt']),
      );
    }).toList();
  }

  static LinkedItemType _readLinkedItemType(Object? value) {
    return LinkedItemType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => LinkedItemType.todo,
    );
  }

  static Map<String, dynamic> _linkedItemToJson(LinkedItem item) {
    return {
      'type': item.type.name,
      'targetId': item.targetId,
      'targetPath': item.targetPath,
      'title': item.title,
      'subtitle': item.subtitle,
      'date': item.date?.toUtc().toIso8601String(),
      'thumbnailUrl': item.thumbnailUrl,
      'preview': item.preview,
      'emoji': item.emoji,
      'createdAt': item.createdAt.toUtc().toIso8601String(),
    };
  }
}
