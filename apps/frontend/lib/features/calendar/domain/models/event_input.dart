import 'calendar_event.dart';

class EventInput {
  const EventInput({
    required this.title,
    required this.startAt,
    required this.endAt,
    this.isAllDay = false,
    this.memo = '',
    this.kind = CalendarEventKind.schedule,
    this.colorValue = 0xFF4169E1,
    this.ownership = EventOwnership.personal,
    this.photoLabels = const [],
    this.reminderOffsetMinutes,
    this.linkedItems = const [],
  });

  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final bool isAllDay;
  final String memo;
  final CalendarEventKind kind;
  final int colorValue;
  final EventOwnership ownership;
  final List<String> photoLabels;
  final int? reminderOffsetMinutes;
  final List<LinkedItem> linkedItems;

  EventInput copyWith({
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    bool? isAllDay,
    String? memo,
    CalendarEventKind? kind,
    int? colorValue,
    EventOwnership? ownership,
    List<String>? photoLabels,
    int? reminderOffsetMinutes,
    List<LinkedItem>? linkedItems,
    bool clearReminder = false,
  }) {
    return EventInput(
      title: title ?? this.title,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      isAllDay: isAllDay ?? this.isAllDay,
      memo: memo ?? this.memo,
      kind: kind ?? this.kind,
      colorValue: colorValue ?? this.colorValue,
      ownership: ownership ?? this.ownership,
      photoLabels: photoLabels ?? this.photoLabels,
      reminderOffsetMinutes: clearReminder
          ? null
          : reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      linkedItems: linkedItems ?? this.linkedItems,
    );
  }
}
