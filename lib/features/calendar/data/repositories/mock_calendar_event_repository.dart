import '../../../../core/time/calendar_date_utils.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/models/event_input.dart';
import 'calendar_event_repository.dart';

class MockCalendarEventRepository implements CalendarEventRepository {
  MockCalendarEventRepository() : _events = _seedEvents(DateTime.now());

  final List<CalendarEvent> _events;
  var _nextId = 10;

  @override
  Future<List<CalendarEvent>> fetchEvents({
    required String coupleId,
    required String userId,
    required DateRange visibleRange,
  }) async {
    final events =
        _events
            .where((event) => event.coupleId == coupleId)
            .where((event) => event.deletedAt == null)
            .where((event) => visibleRange.overlaps(event.startAt, event.endAt))
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
    final now = DateTime.now();
    final id = 'event-${_nextId++}';
    final photos = input.photoLabels.indexed.map((entry) {
      final (index, label) = entry;
      return EventPhoto(
        id: 'photo-$id-$index',
        storagePath: 'mock/$coupleId/$id/$index.jpg',
        downloadUrl: label,
        uploadedBy: userId,
        createdAt: now,
      );
    }).toList();
    final reminders = input.reminderOffsetMinutes == null
        ? <Reminder>[]
        : [
            Reminder(
              id: 'reminder-$id',
              eventId: id,
              remindAt: input.startAt.subtract(
                Duration(minutes: input.reminderOffsetMinutes!),
              ),
              offsetMinutes: input.reminderOffsetMinutes!,
              createdAt: now,
              updatedAt: now,
            ),
          ];

    final event = CalendarEvent(
      id: id,
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
    _events.add(event);
    return event;
  }

  @override
  Future<void> deleteEvent({
    required String coupleId,
    required String eventId,
    required String userId,
  }) async {
    final index = _events.indexWhere(
      (event) => event.coupleId == coupleId && event.id == eventId,
    );
    if (index == -1) {
      return;
    }
    _events[index] = _events[index].copyWith(
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<CalendarEvent> updateEvent({
    required String coupleId,
    required String userId,
    required CalendarEvent event,
  }) async {
    final index = _events.indexWhere(
      (existing) => existing.coupleId == coupleId && existing.id == event.id,
    );
    if (index == -1) {
      throw StateError('Event not found');
    }
    final updated = event.copyWith(updatedAt: DateTime.now());
    _events[index] = updated;
    return updated;
  }
}

int compareCalendarEvents(CalendarEvent left, CalendarEvent right) {
  if (left.isAllDay != right.isAllDay) {
    return left.isAllDay ? -1 : 1;
  }
  final timeCompare = left.startAt.compareTo(right.startAt);
  if (timeCompare != 0) {
    return timeCompare;
  }
  return left.title.compareTo(right.title);
}

List<CalendarEvent> _seedEvents(DateTime today) {
  final now = DateTime.now();
  final coupleId = 'demo-couple';
  final userId = 'demo-user-1';
  final dinnerStart = DateTime(today.year, today.month, today.day, 19);
  final weekend = dateOnly(today).add(const Duration(days: 3));
  final tripStart = dateOnly(today).add(const Duration(days: 7));
  final movieDay = dateOnly(today).subtract(const Duration(days: 2));

  return [
    CalendarEvent(
      id: 'event-1',
      coupleId: coupleId,
      title: '저녁 약속',
      startAt: dinnerStart,
      endAt: dinnerStart.add(const Duration(hours: 2)),
      memo: '퇴근 후 성수에서 만나기',
      colorValue: 0xFF4D7C8A,
      ownership: EventOwnership.personal,
      ownerUserId: userId,
      reminders: [
        Reminder(
          id: 'reminder-event-1',
          eventId: 'event-1',
          remindAt: dinnerStart.subtract(const Duration(hours: 1)),
          offsetMinutes: 60,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    ),
    CalendarEvent(
      id: 'event-2',
      coupleId: coupleId,
      title: '하남검단산 데이트',
      startAt: weekend,
      endAt: weekend.add(const Duration(days: 1)),
      isAllDay: true,
      kind: CalendarEventKind.date,
      memo: '버킷리스트 등산을 데이트 기록으로 남기기',
      colorValue: 0xFFC67C4E,
      ownership: EventOwnership.shared,
      ownerUserId: userId,
      linkedItems: [
        LinkedItem(
          type: LinkedItemType.dateRecord,
          targetId: 'date-record-1',
          targetPath: '/records/dates/date-record-1',
          title: '하남검단산 데이트',
          subtitle: '하남검단산',
          date: weekend,
          preview: '등산 버킷리스트 달성',
          emoji: '⛰️',
          createdAt: now,
        ),
      ],
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    ),
    CalendarEvent(
      id: 'event-3',
      coupleId: coupleId,
      title: '부산 여행',
      startAt: tripStart,
      endAt: tripStart.add(const Duration(days: 3)),
      isAllDay: true,
      memo: '2박 3일 여행 일정',
      colorValue: 0xFF7C6A9E,
      ownership: EventOwnership.shared,
      ownerUserId: userId,
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    ),
    CalendarEvent(
      id: 'event-4',
      coupleId: coupleId,
      title: '영화 리뷰',
      startAt: movieDay.add(const Duration(hours: 21)),
      endAt: movieDay.add(const Duration(hours: 23)),
      kind: CalendarEventKind.date,
      memo: '리뷰 모듈이 생기면 별점과 감상 기록을 여기에 연결',
      colorValue: 0xFF7C6A9E,
      ownership: EventOwnership.personal,
      ownerUserId: 'demo-user-2',
      linkedItems: [
        LinkedItem(
          type: LinkedItemType.dateRecord,
          targetId: 'date-record-2',
          targetPath: '/records/dates/date-record-2',
          title: '영화 리뷰',
          subtitle: '집 근처 영화관',
          date: movieDay,
          preview: '영화 리뷰가 포함된 데이트',
          emoji: '🎬',
          createdAt: now,
        ),
      ],
      createdBy: userId,
      createdAt: now,
      updatedAt: now,
    ),
  ];
}
