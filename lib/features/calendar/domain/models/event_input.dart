import 'calendar_event.dart';

class EventInput {
  const EventInput({
    required this.title,
    required this.startAt,
    required this.endAt,
    this.isAllDay = false,
    this.memo = '',
    this.colorValue = 0xFF4D7C8A,
    this.photoLabels = const [],
    this.reminderOffsetMinutes,
    this.linkedItems = const [],
  });

  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final bool isAllDay;
  final String memo;
  final int colorValue;
  final List<String> photoLabels;
  final int? reminderOffsetMinutes;
  final List<LinkedItem> linkedItems;

  EventInput copyWith({
    String? title,
    DateTime? startAt,
    DateTime? endAt,
    bool? isAllDay,
    String? memo,
    int? colorValue,
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
      colorValue: colorValue ?? this.colorValue,
      photoLabels: photoLabels ?? this.photoLabels,
      reminderOffsetMinutes: clearReminder
          ? null
          : reminderOffsetMinutes ?? this.reminderOffsetMinutes,
      linkedItems: linkedItems ?? this.linkedItems,
    );
  }
}
