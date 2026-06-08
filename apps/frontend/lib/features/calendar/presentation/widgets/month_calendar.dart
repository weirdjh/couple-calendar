import 'package:flutter/material.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../anniversaries/domain/models/anniversary.dart';
import '../../domain/models/calendar_event.dart';
import '../../domain/services/korean_holiday_calendar.dart';
import '../event_ownership_presentation.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    required this.focusedMonth,
    required this.selectedDate,
    required this.events,
    required this.anniversaries,
    required this.onDateSelected,
    this.showEventTitles = false,
    this.currentUserId = '',
    this.holidayCalendar = const KoreanHolidayCalendar(),
    super.key,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final List<AnniversaryOccurrence> anniversaries;
  final ValueChanged<DateTime> onDateSelected;
  final bool showEventTitles;
  final String currentUserId;
  final KoreanHolidayCalendar holidayCalendar;

  @override
  Widget build(BuildContext context) {
    final days = dates.calendarGridDays(focusedMonth);
    final eventsByDate = _groupEventsByDate(events, days);
    final anniversariesByDate = _groupAnniversariesByDate(anniversaries, days);
    final weekLabels = [
      _WeekLabel('일', isRedDay: true),
      _WeekLabel('월'),
      _WeekLabel('화'),
      _WeekLabel('수'),
      _WeekLabel('목'),
      _WeekLabel('금'),
      _WeekLabel('토', isSaturday: true),
    ];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
          child: Column(
            children: [
              Row(
                children: weekLabels.map((label) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        label.text,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: _dayAccentColor(
                                context,
                                isRedDay: label.isRedDay,
                                isSaturday: label.isSaturday,
                              ),
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  childAspectRatio: 0.92,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  return _DayCell(
                    day: day,
                    dayStyle: holidayCalendar.styleFor(day),
                    isFocusedMonth: day.month == focusedMonth.month,
                    isSelected: dates.isSameDate(day, selectedDate),
                    isToday: dates.isSameDate(day, DateTime.now()),
                    events: eventsByDate[dates.dateOnly(day)] ?? const [],
                    anniversaries:
                        anniversariesByDate[dates.dateOnly(day)] ?? const [],
                    showEventTitles: showEventTitles,
                    currentUserId: currentUserId,
                    onTap: () => onDateSelected(day),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekLabel {
  const _WeekLabel(this.text, {this.isRedDay = false, this.isSaturday = false});

  final String text;
  final bool isRedDay;
  final bool isSaturday;
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.dayStyle,
    required this.isFocusedMonth,
    required this.isSelected,
    required this.isToday,
    required this.events,
    required this.anniversaries,
    required this.showEventTitles,
    required this.currentUserId,
    required this.onTap,
  });

  final DateTime day;
  final CalendarDayStyle dayStyle;
  final bool isFocusedMonth;
  final bool isSelected;
  final bool isToday;
  final List<CalendarEvent> events;
  final List<AnniversaryOccurrence> anniversaries;
  final bool showEventTitles;
  final String currentUserId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final multiDayEvents = events
        .where(_isMultiDayEvent)
        .take(showEventTitles ? 1 : 2)
        .toList();
    final singleDayEvents = events.where((event) => !_isMultiDayEvent(event));
    final hasDateEvent = events.any(_isDateEvent);
    final background = isSelected
        ? scheme.primaryContainer
        : isToday
        ? scheme.primaryContainer
        : scheme.surface;
    final foreground = _dayAccentColor(
      context,
      isRedDay: dayStyle.isRedDay,
      isSaturday: dayStyle.isSaturday,
      isMuted: !isFocusedMonth,
    );

    return Material(
      color: background,
      clipBehavior: Clip.hardEdge,
      shape: Border(
        top: isSelected
            ? BorderSide(color: scheme.primary, width: 2)
            : hasDateEvent
            ? const BorderSide(color: Color(0xFFC79AA3), width: 2)
            : BorderSide.none,
        right: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45)),
        bottom: BorderSide(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${day.day}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: isToday || isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                  if (dayStyle.label != null) ...[
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        dayStyle.label!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: foreground,
                          fontSize: 8,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ] else
                    const Spacer(),
                ],
              ),
              if (multiDayEvents.isNotEmpty) ...[
                const SizedBox(height: 2),
                ...multiDayEvents.map((event) {
                  final starts = dates.isSameDate(
                    dates.dateOnly(event.startAt),
                    day,
                  );
                  final ends = dates.isSameDate(_inclusiveEndDate(event), day);
                  final color = currentUserId.isEmpty
                      ? Color(event.colorValue)
                      : eventOwnershipColor(event, currentUserId);
                  return Container(
                    height: 5,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.horizontal(
                        left: starts ? const Radius.circular(6) : Radius.zero,
                        right: ends ? const Radius.circular(6) : Radius.zero,
                      ),
                    ),
                  );
                }),
              ],
              Expanded(
                child: ClipRect(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: showEventTitles && events.isNotEmpty
                        ? Text(
                            _eventCellTitle(events.first),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: foreground,
                                  fontSize: 8,
                                  height: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                          )
                        : Row(
                            children: [
                              if (anniversaries.isNotEmpty)
                                Icon(
                                  Icons.celebration,
                                  size: 12,
                                  color: scheme.tertiary,
                                ),
                              if (anniversaries.isNotEmpty &&
                                  singleDayEvents.isNotEmpty)
                                const SizedBox(width: 3),
                              Flexible(
                                child: Wrap(
                                  spacing: 3,
                                  runSpacing: 3,
                                  children: singleDayEvents.take(3).map((
                                    event,
                                  ) {
                                    return Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? scheme.primary
                                            : currentUserId.isEmpty
                                            ? Color(event.colorValue)
                                            : eventOwnershipColor(
                                                event,
                                                currentUserId,
                                              ),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _isDateEvent(CalendarEvent event) {
  return event.kind == CalendarEventKind.date ||
      event.linkedItems.any((item) => item.type == LinkedItemType.dateRecord);
}

String _eventCellTitle(CalendarEvent event) {
  if (_isDateEvent(event)) {
    final emoji = event.linkedItems
        .where((item) => item.type == LinkedItemType.dateRecord)
        .map((item) => item.emoji)
        .nonNulls
        .firstOrNull;
    if (emoji != null && emoji.trim().isNotEmpty) {
      return '${emoji.trim()} ${event.title}';
    }
    return '💕 ${event.title}';
  }
  return event.title;
}

Color _dayAccentColor(
  BuildContext context, {
  required bool isRedDay,
  required bool isSaturday,
  bool isMuted = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  final base = isRedDay
      ? scheme.error
      : isSaturday
      ? scheme.primary
      : scheme.onSurface;
  return isMuted ? base.withValues(alpha: 0.42) : base;
}

bool _isMultiDayEvent(CalendarEvent event) {
  return !dates.isSameDate(
    dates.dateOnly(event.startAt),
    _inclusiveEndDate(event),
  );
}

DateTime _inclusiveEndDate(CalendarEvent event) {
  if (event.isAllDay) {
    return dates.dateOnly(event.endAt).subtract(const Duration(days: 1));
  }
  return dates.dateOnly(event.endAt);
}

Map<DateTime, List<AnniversaryOccurrence>> _groupAnniversariesByDate(
  List<AnniversaryOccurrence> anniversaries,
  List<DateTime> visibleDays,
) {
  final result = {
    for (final day in visibleDays)
      dates.dateOnly(day): <AnniversaryOccurrence>[],
  };
  for (final occurrence in anniversaries) {
    result[dates.dateOnly(occurrence.date)]?.add(occurrence);
  }
  return result;
}

Map<DateTime, List<CalendarEvent>> _groupEventsByDate(
  List<CalendarEvent> events,
  List<DateTime> visibleDays,
) {
  final result = {
    for (final day in visibleDays) dates.dateOnly(day): <CalendarEvent>[],
  };
  for (final event in events) {
    for (final day in visibleDays) {
      final date = dates.dateOnly(day);
      final start = dates.dateOnly(event.startAt);
      final end = event.isAllDay
          ? dates.dateOnly(event.endAt).subtract(const Duration(days: 1))
          : dates.dateOnly(event.endAt);
      if (!date.isBefore(start) && !date.isAfter(end)) {
        result[date]?.add(event);
      }
    }
  }
  for (final dayEvents in result.values) {
    dayEvents.sort(_compareEventsForCalendarCell);
  }
  return result;
}

int _compareEventsForCalendarCell(CalendarEvent left, CalendarEvent right) {
  if (left.isAllDay != right.isAllDay) {
    return left.isAllDay ? -1 : 1;
  }
  final leftIsMultiDay = _isMultiDayEvent(left);
  final rightIsMultiDay = _isMultiDayEvent(right);
  if (leftIsMultiDay != rightIsMultiDay) {
    return leftIsMultiDay ? -1 : 1;
  }
  final timeCompare = left.startAt.compareTo(right.startAt);
  if (timeCompare != 0) {
    return timeCompare;
  }
  return left.title.compareTo(right.title);
}
