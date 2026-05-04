import 'package:flutter/material.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../anniversaries/domain/models/anniversary.dart';
import '../../domain/models/calendar_event.dart';

class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    required this.focusedMonth,
    required this.selectedDate,
    required this.events,
    required this.anniversaries,
    required this.onDateSelected,
    this.showEventTitles = false,
    super.key,
  });

  final DateTime focusedMonth;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final List<AnniversaryOccurrence> anniversaries;
  final ValueChanged<DateTime> onDateSelected;
  final bool showEventTitles;

  @override
  Widget build(BuildContext context) {
    final days = dates.calendarGridDays(focusedMonth);
    final eventsByDate = _groupEventsByDate(events, days);
    final anniversariesByDate = _groupAnniversariesByDate(anniversaries, days);
    final weekLabels = ['일', '월', '화', '수', '목', '금', '토'];

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
          child: Column(
            children: [
              Row(
                children: weekLabels
                    .map(
                      (label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 1.18,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  return _DayCell(
                    day: day,
                    isFocusedMonth: day.month == focusedMonth.month,
                    isSelected: dates.isSameDate(day, selectedDate),
                    isToday: dates.isSameDate(day, DateTime.now()),
                    events: eventsByDate[dates.dateOnly(day)] ?? const [],
                    anniversaries:
                        anniversariesByDate[dates.dateOnly(day)] ?? const [],
                    showEventTitles: showEventTitles,
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

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.isFocusedMonth,
    required this.isSelected,
    required this.isToday,
    required this.events,
    required this.anniversaries,
    required this.showEventTitles,
    required this.onTap,
  });

  final DateTime day;
  final bool isFocusedMonth;
  final bool isSelected;
  final bool isToday;
  final List<CalendarEvent> events;
  final List<AnniversaryOccurrence> anniversaries;
  final bool showEventTitles;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = isSelected
        ? scheme.primary
        : isToday
        ? scheme.primaryContainer
        : scheme.surface;
    final foreground = isSelected
        ? scheme.onPrimary
        : isFocusedMonth
        ? scheme.onSurface
        : scheme.outline;

    return Material(
      color: background,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const Spacer(),
              if (showEventTitles && events.isNotEmpty)
                ...events.take(2).map((event) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: isSelected ? scheme.onPrimary : foreground,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                })
              else
                Row(
                  children: [
                    if (anniversaries.isNotEmpty)
                      Icon(
                        Icons.celebration,
                        size: 12,
                        color: isSelected ? scheme.onPrimary : scheme.tertiary,
                      ),
                    if (anniversaries.isNotEmpty && events.isNotEmpty)
                      const SizedBox(width: 3),
                    Flexible(
                      child: Wrap(
                        spacing: 3,
                        runSpacing: 3,
                        children: events.take(3).map((event) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? scheme.onPrimary
                                  : Color(event.colorValue),
                              shape: BoxShape.circle,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
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
  return result;
}
